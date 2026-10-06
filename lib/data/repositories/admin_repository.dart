import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/app_database.dart';
import '../../data/models/chat.dart';
import '../../data/models/customer.dart';
import '../../data/models/journal_entry.dart';
import '../../data/models/order.dart';
import '../../data/models/product.dart';
import '../../data/models/stock_note.dart';
import '../../data/models/store_note.dart';
import '../../data/remote/firestore_service.dart';
import 'store_repository.dart';
import '../sync/sync_engine.dart';

const _uuid = Uuid();

/// Sentinel untuk FieldValue.serverTimestamp() di payload antrean
/// (JSON tidak bisa mengenkode FieldValue; dibangkitkan lagi di drainQueue).
const _tsSentinel = '__sv_timestamp';

Object? _queueSafe(Object? v) {
  if (v is FieldValue) return {'__sv': _tsSentinel};
  if (v is Map) {
    return {
      for (final e in v.entries) e.key.toString(): _queueSafe(e.value)
    };
  }
  if (v is List) return v.map(_queueSafe).toList();
  if (v is DateTime) return v.millisecondsSinceEpoch;
  return v;
}

/// Ringkasan pembukuan — dihitung dari data nyata, bukan contoh.
class JournalSummary {
  final int masuk;
  final int keluar;
  final int transaksi;

  const JournalSummary({
    this.masuk = 0,
    this.keluar = 0,
    this.transaksi = 0,
  });

  int get saldo => masuk - keluar;
}

/// Repository Mode Admin: baca Firestore (admin butuh data live),
/// tulis lokal-dulu + antrean sinkron (offline-first).
class AdminRepository {
  final FirebaseFirestore? _db;
  final SyncEngine? _sync;

  AdminRepository(this._db, this._sync);

  bool get online => _db != null;

  // ============ TULIS LOKAL + ANTREAN ============

  Future<void> _writeLocalThenQueue({
    required String table,
    required Map<String, dynamic> row,
    required String collection,
    required String docId,
    required String op,
    required Map<String, dynamic> payload,
  }) async {
    final db = await AppDatabase.db;
    await db.insert(
      table,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    final safe = _queueSafe(payload) as Map<String, dynamic>;
    if (_sync != null) {
      await _sync.enqueue(collection, docId, op, safe);
    } else {
      // Mode lokal: simpan di antrean; terkirim saat online berikutnya.
      await db.insert('sync_queue', {
        'collection': collection,
        'docId': docId,
        'op': op,
        'payload': jsonEncode(safe),
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<void> _deleteLocalThenQueue({
    required String table,
    required String pkColumn,
    required String pkValue,
    required String collection,
    required String docId,
  }) async {
    final db = await AppDatabase.db;
    await db.delete(table, where: '$pkColumn = ?', whereArgs: [pkValue]);
    final payload = <String, dynamic>{};
    if (_sync != null) {
      await _sync.enqueue(collection, docId, 'delete', payload);
    } else {
      await db.insert('sync_queue', {
        'collection': collection,
        'docId': docId,
        'op': 'delete',
        'payload': jsonEncode(payload),
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  String _newId(String collection) {
    final db = _db;
    if (db != null) return db.collection(collection).doc().id;
    return _uuid.v4();
  }

  // ============ PRODUK ============

  /// Semua produk termasuk nonaktif (admin boleh lihat arsip).
  Stream<List<Product>> watchAllProducts() async* {
    final db = _db;
    if (db == null) {
      yield await _productsFromSqlite(all: true);
      return;
    }
    try {
      yield* db.collection('products').snapshots().map((snap) {
        final list = snap.docs.map((d) {
          final m = d.data();
          return Product(
            id: d.id,
            name: (m['name'] as String?) ?? '',
            category: (m['category'] as String?) ?? '',
            price: (m['price'] as num?)?.toInt() ?? 0,
            cost: (m['costPrice'] as num?)?.toInt() ?? 0,
            stock: (m['stock'] as num?)?.toInt() ?? 0,
            barcode: m['barcode'] as String?,
            photoPath: m['photoUrl'] as String?,
            active: m['isActive'] != false,
          );
        }).toList();
        list.sort((a, b) => a.name.compareTo(b.name));
        return list;
      });
    } catch (_) {
      yield await _productsFromSqlite(all: true);
    }
  }

  Future<List<Product>> _productsFromSqlite({bool all = false}) async {
    try {
      final db = await AppDatabase.db;
      final rows = await db.query(
        'products',
        where: all ? null : 'active = 1',
        orderBy: 'name ASC',
      );
      return rows.map((r) => Product.fromMap(r)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<Product?> findByBarcode(String barcode) async {
    final q = barcode.trim();
    if (q.isEmpty) return null;
    final db = _db;
    if (db != null) {
      try {
        final snap = await db
            .collection('products')
            .where('barcode', isEqualTo: q)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          final d = snap.docs.first;
          final m = d.data();
          if (m['isActive'] == false) return null;
          return Product(
            id: d.id,
            name: (m['name'] as String?) ?? '',
            category: (m['category'] as String?) ?? '',
            price: (m['price'] as num?)?.toInt() ?? 0,
            cost: (m['costPrice'] as num?)?.toInt() ?? 0,
            stock: (m['stock'] as num?)?.toInt() ?? 0,
            barcode: m['barcode'] as String?,
            active: true,
          );
        }
      } catch (_) {}
    }
    try {
      final sq = await AppDatabase.db;
      final rows = await sq.query('products',
          where: 'barcode = ? AND active = 1', whereArgs: [q], limit: 1);
      if (rows.isNotEmpty) return Product.fromMap(rows.first);
    } catch (_) {}
    return null;
  }

  /// Simpan produk (baru / ubah). Mengembalikan id.
  Future<String> saveProduct({
    String? id,
    required String name,
    required String category,
    required int price,
    required int cost,
    required int stock,
    String? barcode,
    bool active = true,
  }) async {
    final docId = id ?? _newId('products');
    final now = DateTime.now().millisecondsSinceEpoch;
    final product = Product(
      id: docId,
      name: name.trim(),
      category: category,
      price: price,
      cost: cost,
      stock: stock,
      barcode: (barcode ?? '').trim().isEmpty ? null : barcode!.trim(),
      active: active,
    );
    await _writeLocalThenQueue(
      table: 'products',
      row: {...product.toMap(), 'updatedAt': now},
      collection: 'products',
      docId: docId,
      op: 'set',
      payload: {
        'name': product.name,
        'category': product.category,
        'price': product.price,
        'costPrice': product.cost,
        'stock': product.stock,
        'barcode': product.barcode,
        'isActive': product.active,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    return docId;
  }

  Future<void> setProductActive(String id, bool active) async {
    final db = await AppDatabase.db;
    await db.update('products', {'active': active ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
    final payload = {
      'isActive': active,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final safe = _queueSafe(payload) as Map<String, dynamic>;
    if (_sync != null) {
      await _sync.enqueue('products', id, 'update', safe);
    } else {
      await db.insert('sync_queue', {
        'collection': 'products',
        'docId': id,
        'op': 'update',
        'payload': jsonEncode(safe),
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<void> deleteProduct(String id) => _deleteLocalThenQueue(
        table: 'products',
        pkColumn: 'id',
        pkValue: id,
        collection: 'products',
        docId: id,
      );

  /// Sesuaikan stok (mis. belanja stok / koreksi). [costPrice] opsional.
  Future<void> adjustStock(String productId, int delta,
      {int? costPrice}) async {
    final sq = await AppDatabase.db;
    final rows =
        await sq.query('products', where: 'id = ?', whereArgs: [productId]);
    if (rows.isEmpty) return;
    final p = Product.fromMap(rows.first);
    final newStock = (p.stock + delta).clamp(0, 1 << 31);
    final newCost = costPrice ?? p.cost;
    await sq.update(
      'products',
      {'stock': newStock, 'cost': newCost},
      where: 'id = ?',
      whereArgs: [productId],
    );
    final payload = {
      'stock': newStock,
      'costPrice': newCost,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final safe = _queueSafe(payload) as Map<String, dynamic>;
    if (_sync != null) {
      await _sync.enqueue('products', productId, 'update', safe);
    } else {
      await sq.insert('sync_queue', {
        'collection': 'products',
        'docId': productId,
        'op': 'update',
        'payload': jsonEncode(safe),
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // ============ PESANAN ============

  Stream<List<Order>> watchAllOrders() async* {
    final db = _db;
    if (db == null) {
      yield const [];
      return;
    }
    try {
      yield* db.collection('orders').snapshots().map(_ordersFromSnap);
    } catch (_) {
      yield const [];
    }
  }

  List<Order> _ordersFromSnap(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = snap.docs.map((d) => _orderFromDoc(d.id, d.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Order _orderFromDoc(String id, Map<String, dynamic> m) {
    final items = (m['items'] as List? ?? [])
        .map((e) => OrderItem(
              productId: (e['productId'] as String?) ?? '',
              name: (e['name'] as String?) ?? '',
              qty: (e['qty'] as num?)?.toInt() ?? 0,
              price: (e['price'] as num?)?.toInt() ?? 0,
            ))
        .toList();
    final ts = m['createdAt'];
    return Order(
      id: id,
      customerId: (m['customerId'] as String?) ?? '',
      customerName: (m['customerName'] as String?) ?? '',
      items: items,
      total: (m['total'] as num?)?.toInt() ?? 0,
      status: orderStatusFrom((m['status'] as String?) ?? 'menunggu'),
      payment: (m['paymentMethod'] as String?) ?? 'cod',
      createdAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Future<void> setOrderStatus(String orderId, OrderStatus status) async {
    final sq = await AppDatabase.db;
    await sq.update('orders', {'status': status.name},
        where: 'id = ?', whereArgs: [orderId]);
    final payload = {
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final safe = _queueSafe(payload) as Map<String, dynamic>;
    if (_sync != null) {
      await _sync.enqueue('orders', orderId, 'update', safe);
    } else {
      await sq.insert('sync_queue', {
        'collection': 'orders',
        'docId': orderId,
        'op': 'update',
        'payload': jsonEncode(safe),
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // ============ PERSETUJUAN & PELANGGAN ============

  Stream<List<Customer>> watchPendingApprovals() async* {
    final db = _db;
    if (db == null) {
      yield const [];
      return;
    }
    try {
      yield* db
          .collection('customers')
          .where('approvalStatus', isEqualTo: 'pending')
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => _customerFrom(d.id, d.data()))
              .toList());
    } catch (_) {
      yield const [];
    }
  }

  Stream<List<Customer>> watchCustomers() async* {
    final db = _db;
    if (db == null) {
      yield const [];
      return;
    }
    try {
      yield* db.collection('customers').snapshots().map((snap) {
        final list =
            snap.docs.map((d) => _customerFrom(d.id, d.data())).toList();
        list.sort((a, b) => a.name.compareTo(b.name));
        return list;
      });
    } catch (_) {
      yield const [];
    }
  }

  Customer _customerFrom(String uid, Map<String, dynamic> m) {
    final ts = m['createdAt'];
    return Customer(
      uid: uid,
      name: (m['name'] as String?) ?? '',
      email: (m['email'] as String?) ?? '',
      approvalStatus: (m['approvalStatus'] as String?) ?? 'pending',
      coins: (m['coins'] as num?)?.toInt() ?? 0,
      createdAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.fromMillisecondsSinceEpoch(
              (m['createdAt'] as num?)?.toInt() ?? 0),
    );
  }

  Future<void> setApproval(String uid, bool approved) async {
    final status = approved ? 'approved' : 'rejected';
    final sq = await AppDatabase.db;
    await sq.update('customers', {'approvalStatus': status},
        where: 'uid = ?', whereArgs: [uid]);
    final payload = {'approvalStatus': status};
    final safe = _queueSafe(payload) as Map<String, dynamic>;
    if (_sync != null) {
      await _sync.enqueue('customers', uid, 'update', safe);
    } else {
      await sq.insert('sync_queue', {
        'collection': 'customers',
        'docId': uid,
        'op': 'update',
        'payload': jsonEncode(safe),
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  /// Sesuaikan koin pelanggan + catat di coin_ledger (append-only).
  Future<void> adjustCoins(String uid, int delta, String reason) async {
    final db = _db;
    if (db == null) throw StateError('Butuh internet untuk ubah koin.');
    final ledgerRef = db.collection('coin_ledger').doc();
    final batch = db.batch();
    batch.set(ledgerRef, {
      'customerId': uid,
      'amount': delta,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(db.collection('customers').doc(uid), {
      'coins': FieldValue.increment(delta),
    });
    await batch.commit();
  }

  // ============ JURNAL / PEMBUKUAN ============

  /// kind lokal: penjualan | kulakan | beban | modal
  /// → Firestore: type pemasukan/pengeluaran + category.
  Map<String, dynamic> _journalToFirestore(JournalEntry e) {
    final category = switch (e.kind) {
      'penjualan' => 'penjualan',
      'kulakan' => 'kulakan',
      'beban' => 'beban_promosi',
      _ => 'lainnya',
    };
    return {
      'type': e.amount >= 0 ? 'pemasukan' : 'pengeluaran',
      'category': category,
      'amount': e.amount.abs(),
      'note': e.label,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  JournalEntry _journalFromDoc(String id, Map<String, dynamic> m) {
    final kind = switch (m['category'] as String?) {
      'penjualan' => 'penjualan',
      'kulakan' => 'kulakan',
      'beban_promosi' => 'beban',
      _ => 'modal',
    };
    final amount = (m['amount'] as num?)?.toInt() ?? 0;
    final signed =
        (m['type'] as String?) == 'pengeluaran' ? -amount : amount;
    final ts = m['createdAt'];
    return JournalEntry(
      id: id,
      kind: kind,
      label: (m['note'] as String?) ?? '',
      amount: signed,
      createdAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.fromMillisecondsSinceEpoch(
              (m['createdAt'] as num?)?.toInt() ?? 0),
    );
  }

  Stream<List<JournalEntry>> watchJournal({int limit = 300}) async* {
    final db = _db;
    if (db == null) {
      yield await _journalFromSqlite();
      return;
    }
    try {
      yield* db
          .collection('journal')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => _journalFromDoc(d.id, d.data())).toList());
    } catch (_) {
      yield await _journalFromSqlite();
    }
  }

  Future<List<JournalEntry>> _journalFromSqlite() async {
    try {
      final sq = await AppDatabase.db;
      final rows = await sq.query('journal', orderBy: 'createdAt DESC');
      return rows
          .map((r) => JournalEntry(
                id: r['id'] as String,
                kind: r['kind'] as String,
                label: r['label'] as String,
                amount: (r['amount'] as num).toInt(),
                createdAt: DateTime.fromMillisecondsSinceEpoch(
                    (r['createdAt'] as num).toInt()),
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<JournalSummary> journalSummary({DateTime? from, DateTime? to}) async {
    final entries = await _journalFromSqlite();
    var masuk = 0, keluar = 0, n = 0;
    for (final e in entries) {
      if (from != null && e.createdAt.isBefore(from)) continue;
      if (to != null && !e.createdAt.isBefore(to)) continue;
      n++;
      if (e.amount >= 0) {
        masuk += e.amount;
      } else {
        keluar += -e.amount;
      }
    }
    // Jika online, hitung dari server (lebih lengkap).
    final db = _db;
    if (db != null) {
      try {
        var q = db.collection('journal').orderBy('createdAt', descending: true);
        final snap = await q.limit(1000).get();
        masuk = 0;
        keluar = 0;
        n = 0;
        for (final d in snap.docs) {
          final e = _journalFromDoc(d.id, d.data());
          if (from != null && e.createdAt.isBefore(from)) continue;
          if (to != null && !e.createdAt.isBefore(to)) continue;
          n++;
          if (e.amount >= 0) {
            masuk += e.amount;
          } else {
            keluar += -e.amount;
          }
        }
      } catch (_) {
        // pakai hasil lokal
      }
    }
    return JournalSummary(masuk: masuk, keluar: keluar, transaksi: n);
  }

  /// Tambah entri jurnal jujur (label sesuai fitur nyata).
  Future<String> addJournal({
    required String kind, // penjualan | kulakan | beban | modal
    required String label,
    required int amount, // positif = masuk, negatif = keluar
  }) async {
    final id = _newId('journal');
    final now = DateTime.now();
    final entry = JournalEntry(
      id: id,
      kind: kind,
      label: label,
      amount: amount,
      createdAt: now,
    );
    await _writeLocalThenQueue(
      table: 'journal',
      row: {
        ...entry.toMap(),
        'synced': 0,
      },
      collection: 'journal',
      docId: id,
      op: 'set',
      payload: _journalToFirestore(entry),
    );
    return id;
  }

  // ============ CATATAN BELANJA HARIAN ============

  Stream<List<StockNote>> watchStockNotes() async* {
    final db = _db;
    if (db == null) {
      yield await _notesFromSqlite();
      return;
    }
    try {
      yield* db
          .collection('stock_notes')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((d) {
                final m = d.data();
                final ts = m['createdAt'];
                return StockNote(
                  id: d.id,
                  date: (m['date'] as String?) ?? '',
                  supplier: (m['supplier'] as String?) ?? '',
                  items: StockNote.itemsFrom(m['items']),
                  total: (m['total'] as num?)?.toInt() ?? 0,
                  source: (m['source'] as String?) ?? 'manual',
                  createdAt: ts is Timestamp
                      ? ts.toDate()
                      : DateTime.fromMillisecondsSinceEpoch(
                          (m['createdAt'] as num?)?.toInt() ?? 0),
                );
              }).toList());
    } catch (_) {
      yield await _notesFromSqlite();
    }
  }

  Future<List<StockNote>> _notesFromSqlite() async {
    try {
      final sq = await AppDatabase.db;
      final rows = await sq.query('stock_notes', orderBy: 'createdAt DESC');
      return rows.map((r) => StockNote.fromMap(r)).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Simpan catatan belanja harian (baru / ubah arsip).
  Future<String> saveStockNote(StockNote note) async {
    final id = note.id.isEmpty ? _newId('stock_notes') : note.id;
    final n = StockNote(
      id: id,
      date: note.date,
      supplier: note.supplier,
      items: note.items,
      total: note.total,
      source: note.source,
      createdAt: note.createdAt,
    );
    await _writeLocalThenQueue(
      table: 'stock_notes',
      row: {...n.toMap(), 'synced': 0},
      collection: 'stock_notes',
      docId: id,
      op: 'set',
      payload: n.toFirestore(),
    );
    return id;
  }

  /// Hapus arsip catatan (tidak menghitung ulang pembukuan/stok).
  Future<void> deleteStockNote(String id) => _deleteLocalThenQueue(
        table: 'stock_notes',
        pkColumn: 'id',
        pkValue: id,
        collection: 'stock_notes',
        docId: id,
      );

  // ============ CHAT ============

  Stream<List<ChatThread>> watchThreads() async* {
    final db = _db;
    if (db == null) {
      yield const [];
      return;
    }
    try {
      yield* db
          .collection('chat_threads')
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => ChatThread.fromDoc(d.id, d.data())).toList());
    } catch (_) {
      yield const [];
    }
  }

  Stream<List<ChatMessage>> watchMessages(String threadId) async* {
    final db = _db;
    if (db == null) {
      yield const [];
      return;
    }
    try {
      yield* db
          .collection('chat_threads')
          .doc(threadId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => ChatMessage.fromDoc(d.id, d.data()))
              .toList());
    } catch (_) {
      yield const [];
    }
  }

  Future<void> sendMessage({
    required String threadId,
    required String customerId,
    required String text,
    required String adminId,
  }) async {
    final db = _db;
    if (db == null) throw StateError('Butuh internet untuk chat.');
    final msgRef = db
        .collection('chat_threads')
        .doc(threadId)
        .collection('messages')
        .doc();
    final batch = db.batch();
    batch.set(
        msgRef,
        ChatMessage(
          id: msgRef.id,
          senderId: adminId,
          senderRole: 'admin',
          text: text.trim(),
          createdAt: DateTime.now(),
        ).toFirestore());
    batch.update(db.collection('chat_threads').doc(threadId), {
      'lastMessage': text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCustomer': FieldValue.increment(1),
      'unreadAdmin': 0,
    });
    await batch.commit();
    // cermin lokal (riwayat offline)
    try {
      final sq = await AppDatabase.db;
      await sq.insert(
        'messages',
        {
          'id': msgRef.id,
          'threadId': threadId,
          'senderId': adminId,
          'text': text.trim(),
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'synced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<void> markThreadRead(String threadId) async {
    final db = _db;
    if (db == null) return;
    try {
      await db
          .collection('chat_threads')
          .doc(threadId)
          .update({'unreadAdmin': 0});
    } catch (_) {}
  }

  // ============ TOKO & PROMO ============

  // ---- Catatan Toko (lokal saja; tidak ada koleksi Firestore/rules) ----

  Stream<List<StoreNote>> watchStoreNotes() async* {
    final sq = await AppDatabase.db;
    final rows = await sq.query('store_notes', orderBy: 'createdAt DESC');
    yield rows.map(StoreNote.fromMap).toList();
    // UI memanggil ref.invalidate(storeNotesProvider) setelah tulis/hapus.
  }

  Future<String> saveStoreNote({String? id, required String title, required String body}) async {
    final sq = await AppDatabase.db;
    final docId = id ?? _newId('store_notes');
    await sq.insert(
      'store_notes',
      StoreNote(
        id: docId,
        title: title.trim(),
        body: body.trim(),
        createdAt: DateTime.now(),
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return docId;
  }

  Future<void> deleteStoreNote(String id) async {
    final sq = await AppDatabase.db;
    await sq.delete('store_notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveStoreSettings(Map<String, dynamic> patch) async {
    final db = _db;
    if (db == null) throw StateError('Butuh internet untuk menyimpan.');
    await db.collection('store_settings').doc('main').set(
      {...patch, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<int?> getModal() async {
    final db = _db;
    if (db == null) return null;
    try {
      final doc = await db.collection('store_settings').doc('main').get();
      return (doc.data()?['modal'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  Future<void> setModal(int value) =>
      saveStoreSettings({'modal': value});

  Stream<List<Map<String, dynamic>>> watchAllPromos() async* {
    final db = _db;
    if (db == null) {
      yield const [];
      return;
    }
    try {
      yield* db.collection('promos').snapshots().map((snap) => snap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList());
    } catch (_) {
      yield const [];
    }
  }

  Future<String> savePromo(Map<String, dynamic> data, {String? id}) async {
    final db = _db;
    if (db == null) throw StateError('Butuh internet untuk menyimpan promo.');
    final docId = id ?? db.collection('promos').doc().id;
    await db.collection('promos').doc(docId).set(
      {...data, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    return docId;
  }

  Future<void> deletePromo(String id) async {
    final db = _db;
    if (db == null) throw StateError('Butuh internet untuk menghapus promo.');
    await db.collection('promos').doc(id).delete();
  }

  // ============ KASIR (POS) ============

  /// Catat penjualan tunai: jurnal + kurangi stok.
  /// Kode struk: KSR-yyyymmdd-HHmmss (referensi nyata).
  Future<String> recordCashSale({
    required List<OrderItem> items,
    required int total,
    required int received,
  }) async {
    final now = DateTime.now();
    final code =
        'KSR-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    await addJournal(
      kind: 'penjualan',
      label: 'Penjualan Tunai · Kasir ($code)',
      amount: total,
    );
    for (final item in items) {
      await adjustStock(item.productId, -item.qty);
    }
    return code;
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  SyncEngine? sync;
  try {
    sync = ref.watch(syncEngineProvider);
  } catch (_) {
    sync = null;
  }
  return AdminRepository(ref.watch(firestoreOrNullProvider), sync);
});

// ============ PROVIDER TURUNAN (dipakai tab & badge) ============

final adminProductsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(adminRepositoryProvider).watchAllProducts();
});

final adminOrdersProvider = StreamProvider<List<Order>>((ref) {
  return ref.watch(adminRepositoryProvider).watchAllOrders();
});

final pendingApprovalsProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(adminRepositoryProvider).watchPendingApprovals();
});

final adminCustomersProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(adminRepositoryProvider).watchCustomers();
});

final adminJournalProvider = StreamProvider<List<JournalEntry>>((ref) {
  return ref.watch(adminRepositoryProvider).watchJournal();
});

final stockNotesProvider = StreamProvider<List<StockNote>>((ref) {
  return ref.watch(adminRepositoryProvider).watchStockNotes();
});

final storeNotesProvider = StreamProvider<List<StoreNote>>((ref) {
  return ref.watch(adminRepositoryProvider).watchStoreNotes();
});

/// Semua promo (termasuk yang nonaktif) — untuk kelola admin.
/// promosProvider (store) hanya menampilkan yang aktif untuk pelanggan.
final adminPromosProvider = StreamProvider<List<Promo>>((ref) {
  return ref.watch(adminRepositoryProvider).watchAllPromos().map(
        (list) => list
            .map((m) => Promo.fromDoc(m['id'] as String, m))
            .where((p) => p.title.isNotEmpty)
            .toList(),
      );
});

final chatThreadsProvider = StreamProvider<List<ChatThread>>((ref) {
  return ref.watch(adminRepositoryProvider).watchThreads();
});

/// Produk stok menipis: stok <= batas global (store_settings.lowStockDefault).
final lowStockProductsProvider = Provider<List<Product>>((ref) {
  final products =
      ref.watch(adminProductsProvider).valueOrNull ?? const <Product>[];
  final limit =
      ref.watch(storeInfoProvider).valueOrNull?.lowStockDefault ?? 5;
  return products.where((p) => p.active && p.stock <= limit).toList();
});

/// Badge Inbox: persetujuan + pesanan menunggu + chat belum dibaca + stok menipis.
final inboxBadgeProvider = Provider<int>((ref) {
  final approvals =
      ref.watch(pendingApprovalsProvider).valueOrNull?.length ?? 0;
  final waiting = ref
          .watch(adminOrdersProvider)
          .valueOrNull
          ?.where((o) => o.status == OrderStatus.menunggu)
          .length ??
      0;
  final unread = ref
          .watch(chatThreadsProvider)
          .valueOrNull
          ?.fold<int>(0, (s, t) => s + t.unreadAdmin) ??
      0;
  final low = ref.watch(lowStockProductsProvider).length;
  return approvals + waiting + unread + low;
});
