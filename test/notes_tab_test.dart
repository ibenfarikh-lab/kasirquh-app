import 'package:flutter_test/flutter_test.dart';

import 'package:kasirquh_app/data/models/product.dart';
import 'package:kasirquh_app/data/models/stock_note.dart';
import 'package:kasirquh_app/features/admin/notes/notes_tab.dart';
import 'package:kasirquh_app/l10n/strings_id.dart';

/// Penyelarasan Catatan Belanja Harian — helper murni.
void main() {
  test('labelSumberCatatan: impor→Impor, manual→Manual, '
      'belanja_stok→Dari Belanja Stok', () {
    expect(labelSumberCatatan('impor'), Strings.labelImpor);
    expect(labelSumberCatatan('manual'), Strings.manualTeks);
    expect(
        labelSumberCatatan('belanja_stok'), Strings.dariBelanjaStok);
    // tak dikenal → Manual (bug lama: impor tampil Manual, kini eksplisit)
    expect(labelSumberCatatan('lain'), Strings.manualTeks);
  });

  test('labelItemBarang: qty>1 tampil, qty<=1 hanya nama', () {
    expect(
      labelItemBarang(
          const StockNoteItem(name: 'Gula', qty: 2, price: 0)),
      'Gula · 2',
    );
    expect(
      labelItemBarang(
          const StockNoteItem(name: 'Minyak 2 dus', qty: 1, price: 0)),
      'Minyak 2 dus',
    );
  });

  test('kunciTanggal: YYYY-MM-DD dengan nol di depan', () {
    expect(kunciTanggal(DateTime(2026, 10, 7)), '2026-10-07');
    expect(kunciTanggal(DateTime(2026, 1, 5)), '2026-01-05');
  });

  test('nilaiStokModal: Σ stok × modal/pcs', () {
    final produk = [
      const Product(
          id: 'a',
          name: 'A',
          category: 'Sembako',
          stock: 10,
          cost: 5000,
          price: 7000),
      const Product(
          id: 'b',
          name: 'B',
          category: 'Sembako',
          stock: 3,
          cost: 2000,
          price: 3000),
    ];
    expect(nilaiStokModal(produk), 10 * 5000 + 3 * 2000);
    expect(nilaiStokModal(const []), 0);
  });

  test('nilaiStokModal: produk nonaktif ikut dihitung (ikut PWA)', () {
    // Root cause selisih Rp21.000: jalur lama membuang isActive == false.
    // Kontrak: fungsi murni ini menjumlah SEMUA produk yang diberikan.
    const produk = [
      Product(
          id: 'a',
          name: 'A',
          category: 'Sembako',
          stock: 10,
          cost: 5000,
          price: 7000,
          active: true),
      Product(
          id: 'b',
          name: 'B',
          category: 'Sembako',
          stock: 7,
          cost: 3000,
          price: 4000,
          active: false),
    ];
    expect(nilaiStokModal(produk), 10 * 5000 + 7 * 3000);
  });

  test('StockNoteItem.fromMap tahan qty string ala PWA', () {
    final it = StockNoteItem.fromMap({'name': 'Beras', 'qty': '1'});
    expect(it.name, 'Beras');
    expect(it.qty, 1);
    expect(it.price, 0);
  });
}
