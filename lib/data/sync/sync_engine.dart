import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';

/// Mesin sinkron offline-first:
/// - tulis lokal dulu → masuk [sync_queue] → push ke Firestore saat online
/// - pull koleksi publik (products, promos, store_settings) via snapshot listener
/// - konflik stok/status pesanan: server menang
class SyncEngine {
  final FirebaseFirestore _firestore;
  StreamSubscription? _connSub;
  final List<StreamSubscription> _pullSubs = [];

  SyncEngine(this._firestore);

  Future<void> start() async {
    _connSub = Connectivity()
        .onConnectivityChanged
        .listen((results) => _onConnectivity(results));
    _startPullListeners();
    await drainQueue();
  }

  Future<void> dispose() async {
    await _connSub?.cancel();
    for (final s in _pullSubs) {
      await s.cancel();
    }
  }

  void _onConnectivity(List<ConnectivityResult> results) {
    if (!results.contains(ConnectivityResult.none)) {
      unawaited(drainQueue());
    }
  }

  /// Antrekan operasi tulis lokal → push ke Firestore.
  Future<void> enqueue(
      String collection, String docId, String op, Map<String, dynamic> payload) async {
    final db = await AppDatabase.db;
    await db.insert('sync_queue', {
      'collection': collection,
      'docId': docId,
      'op': op, // set | update | delete
      'payload': jsonEncode(payload),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    await drainQueue();
  }

  /// Kirim semua antrean tertunda (hanya saat online).
  /// Item yang gagal dikirim dilewati di sisa putaran ini (tetap di DB,
  /// dicoba lagi saat ada perubahan koneksi / aplikasi dibuka berikutnya)
  /// agar satu item bermasalah tidak memacetkan seluruh antrean
  /// (head-of-line blocking).
  Future<void> drainQueue() async {
    final conn = await Connectivity().checkConnectivity();
    if (conn.contains(ConnectivityResult.none)) return;
    final db = await AppDatabase.db;
    final rows = await db.query('sync_queue', orderBy: 'id ASC');
    final gagal = <int>{};
    for (final row in rows) {
      final id = row['id'] as int;
      if (gagal.contains(id)) continue;
      final collection = row['collection'] as String;
      final docId = row['docId'] as String;
      final op = row['op'] as String;
      try {
        final ref = _firestore.collection(collection).doc(docId);
        final payload = _reviveTimestamps(
            jsonDecode(row['payload'] as String) as Map<String, dynamic>);
        switch (op) {
          case 'set':
            await ref.set(payload, SetOptions(merge: true));
          case 'update':
            await ref.update(payload);
          case 'delete':
            await ref.delete();
          case 'increment':
            // Delta atomik: {'deltas': {field: n}, 'sets': {field: v}}.
            // FieldValue.increment tidak bisa di-JSON-kan, jadi payload
            // antrean memakai struktur ini lalu dibangkitkan di sini.
            final sets =
                Map<String, dynamic>.from(payload['sets'] as Map? ?? {});
            final deltas =
                Map<String, dynamic>.from(payload['deltas'] as Map? ?? {});
            await ref.set(
              {
                ...sets,
                for (final e in deltas.entries)
                  e.key: FieldValue.increment((e.value as num).toInt()),
              },
              SetOptions(merge: true),
            );
        }
        await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
      } catch (_) {
        // Gagal → catat, lewati item ini di putaran ini, lanjut ke
        // item berikutnya. Item tetap di antrean untuk dicoba lagi nanti.
        gagal.add(id);
      }
    }
  }

  /// Kembalikan sentinel menjadi nilai Firestore:
  /// - `{'__sv': '__sv_timestamp'}` → FieldValue.serverTimestamp()
  /// - `{'__ts': ms}` → Timestamp.fromMillisecondsSinceEpoch(ms)
  ///   (kebalikan dari _queueSafe di repository).
  Map<String, dynamic> _reviveTimestamps(Map<String, dynamic> m) {
    Object? revive(Object? v) {
      if (v is Map) {
        if (v['__sv'] == '__sv_timestamp' && v.length == 1) {
          return FieldValue.serverTimestamp();
        }
        if (v['__ts'] != null && v.length == 2 && v['ms'] is num) {
          return Timestamp.fromMillisecondsSinceEpoch(
              (v['ms'] as num).toInt());
        }
        return {
          for (final e in v.entries) e.key.toString(): revive(e.value)
        };
      }
      if (v is List) return v.map(revive).toList();
      return v;
    }

    return Map<String, dynamic>.from(revive(m) as Map);
  }

  /// Pull koleksi publik → tulis ke SQLite lokal (server menang).
  void _startPullListeners() {
    _pullSubs.add(_firestore.collection('products').snapshots().listen(
          (snap) => _pullInto('products', snap),
        ));
    _pullSubs.add(_firestore.collection('promos').snapshots().listen(
          (snap) => _pullInto('promos', snap),
        ));
    _pullSubs.add(_firestore
        .collection('store_settings')
        .snapshots()
        .listen((snap) => _pullSettings(snap)));
  }

  Future<void> _pullInto(
      String table, QuerySnapshot<Map<String, dynamic>> snap) async {
    final db = await AppDatabase.db;
    for (final doc in snap.docChanges) {
      final data = doc.doc.data();
      if (data == null) continue;
      if (table == 'products') {
        await db.insert(
          'products',
          {
            'id': doc.doc.id,
            'name': data['name'] ?? '',
            'category': data['category'] ?? '',
            'price': (data['price'] as num?)?.toInt() ?? 0,
            'cost': (data['costPrice'] as num?)?.toInt() ?? 0,
            'stock': (data['stock'] as num?)?.toInt() ?? 0,
            'lowStockAt': (data['lowStockAt'] as num?)?.toInt() ?? 5,
            'barcode': data['barcode'],
            'photoPath': data['photoUrl'],
            'active': (data['isActive'] == false) ? 0 : 1,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else if (table == 'promos') {
        await db.insert(
          'promos',
          {
            'id': doc.doc.id,
            'title': data['title'] ?? '',
            'subtitle': data['subtitle'],
            'productId': data['productId'],
            'discountType': data['discountType'],
            'discountValue': (data['discountValue'] as num?)?.toInt() ?? 0,
            'isActive': (data['isActive'] == false) ? 0 : 1,
            'startsAt': _tsMillis(data['startsAt']),
            'endsAt': _tsMillis(data['endsAt']),
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  /// Ambil millis dari Timestamp/num untuk kolom lokal (null bila tak ada).
  int? _tsMillis(Object? v) {
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    if (v is num) return v.toInt();
    return null;
  }

  Future<void> _pullSettings(QuerySnapshot<Map<String, dynamic>> snap) async {    final db = await AppDatabase.db;
    for (final doc in snap.docChanges) {
      final data = doc.doc.data();
      if (data == null) continue;
      await db.insert(
        'store_settings',
        {
          'key': doc.doc.id,
          'value': jsonEncode(data),
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}

final syncEngineProvider = Provider<SyncEngine>((ref) {
  throw UnimplementedError('SyncEngine dioverride di main.dart');
});
