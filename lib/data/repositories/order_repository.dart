import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/currency.dart';
import '../../data/models/order.dart';
import '../../data/remote/firestore_service.dart';

class StockShortage implements Exception {
  final List<String> productNames;
  const StockShortage(this.productNames);
}

class OfflineCheckout implements Exception {
  const OfflineCheckout();
}

class OrderRepository {
  final FirebaseFirestore? _db;

  OrderRepository(this._db);

  Future<String> checkout({
    required String customerId,
    required String customerName,
    required List<OrderItem> items,
    required String paymentMethod,
    required String fulfillment,
    String transferReference = '',
    String? note,
    int ongkir = 0,
    int coinUsed = 0,
    int coinRate = 1,
    int redeemLimit = 50,
    int spendRule = 0,
    int spendReward = 0,
    Map<String, int> promoUnitPrice = const {},
    String? flashProductId,
    String flashRule = '', 
  }) async {
    final db = _db;
    if (db == null) throw const OfflineCheckout();
    final rate = coinRate < 1 ? 1 : coinRate;

    return db.runTransaction((tx) async {
      final counterRef = db.collection('counters').doc('orders');
      final counterSnap = await tx.get(counterRef);
      final seq =
          ((counterSnap.data()?['seq'] as num?)?.toInt() ?? 0) + 1;
      tx.set(counterRef, {'seq': seq}, SetOptions(merge: true));
      final code = 'WM-${seq.toString().padLeft(6, '0')}';

      final custRef = db.collection('customers').doc(customerId);
      final custSnap = await tx.get(custRef);
      if (!custSnap.exists ||
          custSnap.data()?['approvalStatus'] != 'approved') {
        throw StateError('Akun belum disetujui warung');
      }
      final saldo =
          ((custSnap.data()?['coins'] as num?)?.toInt() ?? 0);

      final serverItems = <OrderItem>[];
      var total = 0;
      final lacking = <String>[];
      for (final item in items) {
        final pRef = db.collection('products').doc(item.productId);
        final pSnap = await tx.get(pRef);
        if (!pSnap.exists) {
          throw StateError('Ada produk yang sudah tidak tersedia');
        }
        final pd = pSnap.data()!;
        final namaServer = (pd['name'] as String?) ?? item.name;
        final stock = (pd['stock'] as num?)?.toDouble() ?? 0;
        if (stock < item.qty) {
          lacking.add(namaServer);
          continue;
        }
        if (flashProductId != null && item.productId == flashProductId) {
          final m = RegExp(r'\d+').firstMatch(flashRule);
          final cap = m != null
              ? (int.tryParse(m.group(0)!) ?? 5)
              : 5;
          if (item.qty > (cap < 1 ? 1 : cap)) {
            throw StateError(
                'Promo kilat maksimal ${cap < 1 ? 1 : cap} per pesanan');
          }
        }
        final hargaProduk = ((pd['price'] as num?)?.toInt() ?? 0);
        var unit = promoUnitPrice[item.productId] ?? hargaProduk;
        final wq = ((pd['wholesaleQty'] as num?)?.toInt() ?? 0);
        final wp = ((pd['wholesalePrice'] as num?)?.toInt() ?? 0);
        if (wq > 0 && item.qty >= wq) {
          final grosir = wp > 0 ? wp : unit;
          if (grosir < unit) unit = grosir;
        }
        serverItems.add(OrderItem(
          productId: item.productId,
          name: namaServer,
          qty: item.qty,
          price: unit,
        ));
        total += (unit * item.qty).round();
        tx.update(pRef, {
          'stock': stock - item.qty,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (lacking.isNotEmpty) throw StockShortage(lacking);

      final fullTotal = total + ongkir;
      final maxValue = total * redeemLimit ~/ 100;
      var redeem = coinUsed;
      final maxRedeem = maxValue ~/ rate;
      if (redeem > maxRedeem) redeem = maxRedeem;
      if (redeem > saldo) redeem = saldo;
      if (redeem < 0) redeem = 0;
      final coinValue = redeem * rate;
      final paidTotal = fullTotal - coinValue < 0 ? 0 : fullTotal - coinValue;
      final earned = spendRule > 0 ? (total ~/ spendRule) * spendReward : 0;

      final coinDelta = earned - redeem;
      if (coinDelta != 0) {
        tx.update(custRef, {'coins': FieldValue.increment(coinDelta)});
      }

      final ref = db.collection('orders').doc();
      tx.set(ref, {
        'code': code,
        'customerId': customerId,
        'customerName': customerName,
        'items': serverItems
            .map((e) => {
                  'productId': e.productId,
                  'name': e.name,
                  'price': e.price,
                  'qty': e.qty,
                  'subtotal': (e.price * e.qty).round(),
                })
            .toList(),
        'total': paidTotal,
        'fullTotal': fullTotal,
        'paymentMethod': paymentMethod,
        'transferReference':
            paymentMethod == 'transfer' ? transferReference : '',
        'fulfillment': fulfillment,
        'status': 'menunggu',
        'note': note,
        'coinUsed': redeem,
        'coinValue': coinValue,
        'earnedCoins': earned,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (redeem > 0) {
        final ledgerRef = db.collection('coin_ledger').doc();
        tx.set(ledgerRef, {
          'customerId': customerId,
          'amount': -redeem,
          'reason': 'tukar',
          'label': 'Ditukar pada #$code',
          'detail': 'Potongan ${formatRp(coinValue)}',
          'orderId': ref.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (earned > 0) {
        final ledgerRef = db.collection('coin_ledger').doc();
        tx.set(ledgerRef, {
          'customerId': customerId,
          'amount': earned,
          'reason': 'belanja',
          'label': 'Bonus belanja #$code',
          'detail': '${formatRp(total)} belanja',
          'orderId': ref.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return code;
    });
  }

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
                    qty: (e['qty'] as num?)?.toDouble() ?? 0,
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

String orderStatusLabel(OrderStatus s) => switch (s) {
      OrderStatus.menunggu => 'Menunggu',
      OrderStatus.dikemas => 'Dikemas',
      OrderStatus.dikirim => 'Dikirim',
      OrderStatus.selesai => 'Selesai',
      OrderStatus.dibatalkan => 'Dibatalkan',
    };
