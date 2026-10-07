import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/order.dart';
import '../../data/remote/firestore_service.dart';

/// Gagal checkout karena stok tidak mencukupi.
class StockShortage implements Exception {
  final List<String> productNames;
  const StockShortage(this.productNames);
}

/// Gagal checkout karena offline.
class OfflineCheckout implements Exception {
  const OfflineCheckout();
}

/// Repository pesanan pelanggan.
/// Checkout: transaksi atomik — nomor urut via counters/orders,
/// validasi + pengurangan stok server, lalu buat dokumen `orders`.
/// Aturan: hanya member approved (dijamin rules Firestore juga).
class OrderRepository {
  final FirebaseFirestore? _db;

  OrderRepository(this._db);

  /// Buat pesanan. Mengembalikan kode pesanan (WM-000123…).
  /// Melempar [OfflineCheckout] bila offline, [StockShortage] bila stok kurang.
  Future<String> checkout({
    required String customerId,
    required String customerName,
    required List<OrderItem> items,
    required String paymentMethod, // cod | transfer
    String? note,
  }) async {
    final db = _db;
    if (db == null) throw const OfflineCheckout();
    final total = items.fold<int>(0, (s, e) => s + e.price * e.qty);

    return db.runTransaction((tx) async {
      // 1. Nomor urut pesanan dari counters/orders (atomik).
      final counterRef = db.collection('counters').doc('orders');
      final counterSnap = await tx.get(counterRef);
      final seq =
          ((counterSnap.data()?['seq'] as num?)?.toInt() ?? 0) + 1;
      tx.set(counterRef, {'seq': seq}, SetOptions(merge: true));
      final code = 'WM-${seq.toString().padLeft(6, '0')}';

      // 2. Validasi stok dari server + kurangi dalam transaksi yang sama.
      //    Gagal validasi → transaksi batal total, tidak ada stok berkurang
      //    dan tidak ada pesanan dibuat (anti oversell).
      final lacking = <String>[];
      for (final item in items) {
        final pRef = db.collection('products').doc(item.productId);
        final pSnap = await tx.get(pRef);
        // JANGAN .toInt(): stok desimal (3,75) wajib utuh —
        // versi lama memotong lalu menulis balik hasil potongan
        // ke Firestore (korupsi data).
        final stock = (pSnap.data()?['stock'] as num?)?.toDouble();
        if (stock == null || stock < item.qty) {
          lacking.add(item.name);
        } else {
          tx.update(pRef, {
            'stock': stock - item.qty,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      if (lacking.isNotEmpty) throw StockShortage(lacking);

      // 3. Buat dokumen pesanan.
      final ref = db.collection('orders').doc();
      tx.set(ref, {
        'code': code,
        'customerId': customerId,
        'customerName': customerName,
        'items': items
            .map((e) => {
                  'productId': e.productId,
                  'name': e.name,
                  'price': e.price,
                  'qty': e.qty,
                  'subtotal': e.price * e.qty,
                })
            .toList(),
        'total': total,
        'paymentMethod': paymentMethod,
        'status': 'menunggu',
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return code;
    });
  }

  /// Riwayat pesanan milik pelanggan (terbaru dulu).
  ///
  /// Error (offline/rules) DITERUSKAN ke UI — jangan ditelan jadi daftar
  /// kosong, agar user tidak disesatkan "belum ada pesanan" padahal
  /// pesanan mungkin ada tapi gagal dimuat.
  Stream<List<Order>> watchMyOrders(String customerId) async* {
    final db = _db;
    if (db == null) {
      throw const OfflineCheckout();
    }
    yield* db
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snap) {
        final list = snap.docs.map((d) {
          final m = d.data();
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
            id: d.id,
            customerId: customerId,
            customerName: (m['customerName'] as String?) ?? '',
            code: (m['code'] as String?) ?? d.id,
            items: items,
            total: (m['total'] as num?)?.toInt() ?? 0,
            status: orderStatusFrom((m['status'] as String?) ?? 'menunggu'),
            payment: (m['paymentMethod'] as String?) ?? 'cod',
            createdAt: ts is Timestamp
                ? ts.toDate()
                : DateTime.fromMillisecondsSinceEpoch(0),
          );
        }).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
  }

  /// Titip belanja terstruktur (Domain B) — tulis ke `titip_requests`.
  /// Skema SAMA PERSIS dengan PWA. Wajib login & online (ikut PWA).
  Future<void> submitTitipRequest({
    required String customerId,
    required String customerName,
    required String item,
    String note = '',
    String method = 'Ambil di warung',
  }) async {
    final db = _db;
    if (db == null) throw const OfflineCheckout();
    final barang = item.trim();
    if (barang.isEmpty) throw ArgumentError('item kosong');
    await db.collection('titip_requests').add({
      'customerId': customerId,
      'customerName':
          customerName.trim().isEmpty ? 'Pelanggan' : customerName.trim(),
      'item': barang.length > 100 ? barang.substring(0, 100) : barang,
      'note': note.trim().length > 300
          ? note.trim().substring(0, 300)
          : note.trim(),
      'method': method,
      'status': 'baru',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(firestoreOrNullProvider));
});

/// Label status pesanan (Bahasa Indonesia).
String orderStatusLabel(OrderStatus s) => switch (s) {
      OrderStatus.menunggu => 'Menunggu',
      OrderStatus.dikemas => 'Dikemas',
      OrderStatus.dikirim => 'Dikirim',
      OrderStatus.selesai => 'Selesai',
      OrderStatus.dibatalkan => 'Dibatalkan',
    };
