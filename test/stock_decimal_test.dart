import 'package:flutter_test/flutter_test.dart';

import 'package:kasirquh_app/core/utils/currency.dart';
import 'package:kasirquh_app/data/models/product.dart';
import 'package:kasirquh_app/data/models/stock_note.dart';

/// Revisi stok desimal — root cause selisih Rp21.000:
/// PWA membulatkan (3,75→4), native memotong (3,75→3).
/// Yang benar: 3,75 × Rp4.000 = Rp15.000 (desimal dipertahankan).
void main() {
  test('formatStok: bulat tanpa desimal, pecahan pakai koma', () {
    expect(formatStok(10), '10');
    expect(formatStok(10.0), '10');
    expect(formatStok(3.75), '3,75');
    expect(formatStok(2.5), '2,5');
    expect(formatStok(0.5), '0,5');
  });

  test('parseDesimal: koma/titik Indonesia', () {
    expect(parseDesimal('3,75'), 3.75);
    expect(parseDesimal('3.75'), 3.75);
    expect(parseDesimal('10'), 10.0);
    // Untuk field qty/stok: titik = desimal (selaras PWA —
    // format ribuan dilewati untuk desimal).
    expect(parseDesimal('1.000'), 1.0);
    expect(parseDesimal(''), 0.0);
  });

  test('Product.fromMap: stok desimal tidak dipotong', () {
    final p = Product.fromMap({
      'id': 'x',
      'name': 'Bawang Putih Hunan',
      'price': 6000,
      'cost': 4000,
      'stock': 3.75,
    });
    expect(p.stock, 3.75);
  });

  test('Product.fromMap: stok bulat tetap jalan', () {
    final p = Product.fromMap({
      'id': 'y',
      'name': 'Indomie',
      'price': 3500,
      'cost': 2800,
      'stock': 10,
    });
    expect(p.stock, 10.0);
  });

  test('Product toFirestore: stok desimal terkirim apa adanya', () {
    const p = Product(
      id: 'x',
      name: 'Bawang',
      category: 'Sembako',
      price: 6000,
      cost: 4000,
      stock: 3.75,
    );
    expect(p.toFirestore()['stock'], 3.75);
    expect(p.toMap()['stock'], 3.75);
  });

  test('StockNoteItem.fromMap: qty desimal & string PWA', () {
    final a = StockNoteItem.fromMap(
        {'name': 'Bawang', 'qty': 2.5, 'price': 4000});
    expect(a.qty, 2.5);
    expect(a.subtotal, 10000.0);
    final b =
        StockNoteItem.fromMap({'name': 'Gula', 'qty': '3', 'price': 0});
    expect(b.qty, 3.0);
  });

  test('contoh terkunci: 3,75 kg x Rp4.000 = Rp15.000', () {
    const p = Product(
      id: 'x',
      name: 'Bawang Putih Hunan',
      category: 'Sembako',
      price: 6000,
      cost: 4000,
      stock: 3.75,
    );
    expect(p.stock * p.cost, 15000.0);
    expect(formatRp((p.stock * p.cost).round()), 'Rp15.000');
  });
}
