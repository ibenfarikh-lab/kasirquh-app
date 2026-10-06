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
  Future<void> drainQueue() async {
    final conn = await Connectivity().checkConnectivity();
    if (conn.contains(ConnectivityResult.none)) return;
    final db = await AppDatabase.db;
    final rows = await db.query('sync_queue', orderBy: 'id ASC');
    for (final row in rows) {
      final id = row['id'] as int;
      final collection = row['collection'] as String;
      final docId = row['docId'] as String;
      final op = row['op'] as String;
      final payload =
          jsonDecode(row['payload'] as String) as Map<String, dynamic>;
      try {
        final ref = _firestore.collection(collection).doc(docId);
        switch (op) {
          case 'set':
            await ref.set(payload, SetOptions(merge: true));
          case 'update':
            await ref.update(payload);
          case 'delete':
            await ref.delete();
        }
        await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
      } catch (_) {
        // Gagal → tetap di antrean, coba lagi saat online berikutnya.
        break;
      }
    }
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
            'cost': (data['cost'] as num?)?.toInt() ?? 0,
            'stock': (data['stock'] as num?)?.toInt() ?? 0,
            'barcode': data['barcode'],
            'photoPath': data['photoPath'],
            'active': (data['active'] == false) ? 0 : 1,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  Future<void> _pullSettings(
      QuerySnapshot<Map<String, dynamic>> snap) async {
    final db = await AppDatabase.db;
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
