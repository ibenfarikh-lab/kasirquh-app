import 'package:flutter_test/flutter_test.dart';
import 'package:kasirquh_app/core/utils/csv_products.dart';

void main() {
  group('parseCsvNumber (format Web)', () {
    test('ribuan titik Indonesia', () {
      expect(parseCsvNumber('1.500'), 1500);
      expect(parseCsvNumber('15.000,50'), 15000.5);
    });
    test('desimal koma', () {
      expect(parseCsvNumber('2,5'), 2.5);
      expect(parseCsvNumber('0,75'), 0.75);
    });
    test('kosong / bukan angka -> 0', () {
      expect(parseCsvNumber(''), 0);
      expect(parseCsvNumber('abc'), 0);
      expect(parseCsvNumber(null), 0);
    });
    test('angka polos', () {
      expect(parseCsvNumber('2500'), 2500);
      expect(parseCsvNumber('3.75'), 3.75);
    });
  });

  group('parseCsvText', () {
    test('kutip melindungi koma & kutip ganda', () {
      final rows = parseCsvText('Nama,Harga\n"Gula, Manis","1""x"\n');
      expect(rows.length, 2);
      expect(rows[1][0], 'Gula, Manis');
      expect(rows[1][1], '1"x');
    });
    test('BOM dibuang & baris kosong dilewati', () {
      final rows = parseCsvText('\uFEFFNama\n\nBeras\n');
      expect(rows.length, 2);
      expect(rows[0][0], 'Nama');
    });
  });

  group('mapCsvRows', () {
    test('alias header Indonesia + dedup barcode (terakhir menang)', () {
      final rows = parseCsvText(
        'Kode Barang,Nama Produk,Kategori,Stok,Harga Beli,Harga Jual\n'
        '8999,Beras Ramos,Sembako,10,9000,11000\n'
        '8999,Beras Ramos Premium,Sembako,5,9500,12000\n'
        ',Tanpa Kode,Lainnya,1,100,200\n',
      );
      final r = mapCsvRows(rows);
      expect(r.items.length, 2);
      final beras = r.items.firstWhere((e) => e.barcode == '8999');
      expect(beras.name, 'Beras Ramos Premium');
      expect(beras.stock, 5);
      expect(beras.cost, 9500);
      expect(beras.price, 12000);
      expect(beras.cat, 'Sembako');
      expect(beras.unit, 'pcs'); // bawaan Web
    });

    test('tanpa kolom Nama -> dilewati dengan alasan', () {
      final r = mapCsvRows(parseCsvText('Harga,Stok\n100,2\n'));
      expect(r.items, isEmpty);
      expect(r.skipped.length, 1);
      expect(r.skipped.first.row, 1);
    });

    test('baris tanpa nama dilewati, kategori bawaan Lainnya', () {
      final r = mapCsvRows(parseCsvText('Nama,Harga\n,500\nGula,7000\n'));
      expect(r.items.length, 1);
      expect(r.items.first.cat, 'Lainnya');
      expect(r.skipped.length, 1);
      expect(r.skipped.first.row, 2);
    });
  });
}
