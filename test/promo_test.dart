import 'package:flutter_test/flutter_test.dart';
import 'package:kasirquh_app/data/repositories/store_repository.dart';

void main() {
  group('Promo.hargaPromo', () {
    test('tanpa diskon -> harga normal', () {
      const p = Promo(id: '1', title: 'x');
      expect(p.hargaPromo(10000), 10000);
    });

    test('percent 10 dari 10000 -> 9000', () {
      const p = Promo(
          id: '1', title: 'x', discountType: 'percent', discountValue: 10);
      expect(p.hargaPromo(10000), 9000);
    });

    test('percent 100 -> 0, percent >100 dijaga', () {
      const p = Promo(
          id: '1', title: 'x', discountType: 'percent', discountValue: 150);
      expect(p.hargaPromo(10000), 0);
    });

    test('amount 2000 dari 10000 -> 8000', () {
      const p = Promo(
          id: '1', title: 'x', discountType: 'amount', discountValue: 2000);
      expect(p.hargaPromo(10000), 8000);
    });

    test('flash = potongan nominal', () {
      const p = Promo(
          id: '1', title: 'x', discountType: 'flash', discountValue: 500);
      expect(p.hargaPromo(10000), 9500);
    });

    test('amount melebihi harga -> 0 (tidak negatif)', () {
      const p = Promo(
          id: '1', title: 'x', discountType: 'amount', discountValue: 99999);
      expect(p.hargaPromo(10000), 0);
    });
  });

  group('Promo.fromDoc', () {
    test('memetakan discountType/discountValue', () {
      final p = Promo.fromDoc('1', {
        'title': 'Promo',
        'discountType': 'percent',
        'discountValue': 20,
        'isActive': true,
      });
      expect(p.discountType, 'percent');
      expect(p.discountValue, 20);
      expect(p.hargaPromo(5000), 4000);
    });

    test('tanpa field diskon -> harga normal', () {
      final p = Promo.fromDoc('1', {'title': 'Banner', 'isActive': true});
      expect(p.discountType, isNull);
      expect(p.hargaPromo(5000), 5000);
    });
  });
}
