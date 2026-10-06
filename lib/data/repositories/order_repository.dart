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
/// Checkout: validasi stok dari server → buat dokumen `orders`.
/// Aturan: hanya member approved (dijamin rules Firestore juga).
class OrderRepository {
  final FirebaseFirestore? _db;

  OrderRepository(this._db);

  /// Buat pesanan. Mengembalikan kode pesanan.
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

    // Validasi stok dari server (wajib — tolak bila melebihi).
    final lacking = <String>[];
    for (final item in items) {
      final doc = await db.collection('products').doc(item.productId).get();
      final stock = (doc.data()?['stock'] as num?)?.toInt();
      if (stock == null || stock < item.qty) {
        lacking.add(item.name);
      }
    }
    if (lacking.isNotEmpty) throw StockShortage(lacking);

    final ref = db.collection('orders').doc();
    final code =
        'WM-${ref.id.substring(0, 6).toUpperCase()}';
    final total = items.fold<int>(0, (s, e) => s + e.price * e.qty);
    await ref.set({
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
    });
    return code;
  }

  /// Riwayat pesanan milik pelanggan (terbaru dulu).
  Stream<List<Order>> watchMyOrders(String customerId) async* {
    final db = _db;
    if (db == null) {
      yield const [];
      return;
    }
    try {
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
    } catch (_) {
      yield const [];
    }
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
