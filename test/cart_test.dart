import 'package:flutter_test/flutter_test.dart';
import 'package:kasirquh_app/data/models/order.dart';
import 'package:kasirquh_app/data/repositories/order_repository.dart'
    show orderStatusLabel;
import 'package:kasirquh_app/data/models/product.dart';
import 'package:kasirquh_app/data/repositories/product_repository.dart';
import 'package:kasirquh_app/features/customer/cart/cart_provider.dart';

const _indomie = Product(
  id: 'p1',
  name: 'Indomie Goreng',
  category: 'Sembako',
  price: 3500,
  cost: 2800,
  stock: 10,
  barcode: '899123456',
);

const _aqua = Product(
  id: 'p2',
  name: 'Aqua 600ml',
  category: 'Minuman',
  price: 4000,
  cost: 3200,
  stock: 2,
);

const _habis = Product(
  id: 'p3',
  name: 'Gula 1kg',
  category: 'Sembako',
  price: 17500,
  cost: 15000,
  stock: 0,
);

void main() {
  group('CartNotifier', () {
    test('tambah produk baru → 1 baris qty 1', () {
      final cart = CartNotifier();
      expect(cart.add(_indomie), isTrue);
      expect(cart.state.length, 1);
      expect(cart.state.first.qty, 1);
    });

    test('tambah produk stok habis → ditolak', () {
      final cart = CartNotifier();
      expect(cart.add(_habis), isFalse);
      expect(cart.state, isEmpty);
    });

    test('qty tidak bisa melebihi stok', () {
      final cart = CartNotifier();
      expect(cart.add(_aqua), isTrue);
      expect(cart.add(_aqua), isTrue);
      expect(cart.add(_aqua), isFalse); // stok cuma 2
      expect(cart.state.first.qty, 2);
    });

    test('setQty 0 menghapus baris; total & totalQty benar', () {
      final cart = CartNotifier();
      cart.add(_indomie);
      cart.add(_indomie);
      cart.add(_aqua);
      expect(cart.totalQty, 3);
      expect(cart.total, 3500 * 2 + 4000);
      cart.setQty('p1', 0);
      expect(cart.state.length, 1);
      expect(cart.totalQty, 1);
      cart.clear();
      expect(cart.state, isEmpty);
      expect(cart.total, 0);
    });
  });

  group('filterProducts', () {
    final all = [_indomie, _aqua, _habis];

    test('tanpa filter → semua', () {
      expect(filterProducts(all).length, 3);
    });

    test('filter kategori', () {
      final r = filterProducts(all, category: 'Minuman');
      expect(r.length, 1);
      expect(r.first.id, 'p2');
    });

    test('pencarian nama (case-insensitive)', () {
      final r = filterProducts(all, query: 'INDOmie');
      expect(r.length, 1);
      expect(r.first.id, 'p1');
    });

    test('pencarian barcode', () {
      final r = filterProducts(all, query: '899123456');
      expect(r.length, 1);
      expect(r.first.id, 'p1');
    });

    test('kombinasi kategori + query', () {
      expect(
          filterProducts(all, category: 'Sembako', query: 'gula').length, 1);
      expect(filterProducts(all, category: 'Minuman', query: 'gula'),
          isEmpty);
    });
  });

  group('orderStatusLabel', () {
    test('semua status punya label Indonesia', () {
      expect(orderStatusLabel(OrderStatus.menunggu), 'Menunggu');
      expect(orderStatusLabel(OrderStatus.dikemas), 'Dikemas');
      expect(orderStatusLabel(OrderStatus.dikirim), 'Dikirim');
      expect(orderStatusLabel(OrderStatus.selesai), 'Selesai');
      expect(orderStatusLabel(OrderStatus.dibatalkan), 'Dibatalkan');
    });

    test('orderStatusFrom selaras skema Firestore', () {
      expect(orderStatusFrom('dikemas'), OrderStatus.dikemas);
      expect(orderStatusFrom('dikirim'), OrderStatus.dikirim);
      expect(orderStatusFrom('ngawur'), OrderStatus.menunggu);
    });
  });
}
