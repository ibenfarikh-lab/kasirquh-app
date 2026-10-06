import 'package:flutter_test/flutter_test.dart';
import 'package:kasirquh_app/data/models/journal_entry.dart';
import 'package:kasirquh_app/data/models/product.dart';
import 'package:kasirquh_app/features/admin/menu/report_page.dart'
    show buildCsv, omzetPerHari;
import 'package:kasirquh_app/features/admin/menu/stock_shopping_sheet.dart'
    show saranHargaJual;
import 'package:kasirquh_app/features/admin/pos/pay_sheet.dart'
    show buildReceipt, kembalian;
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

const _gulaNonaktif = Product(
  id: 'p3',
  name: 'Gula 1kg',
  category: 'Sembako',
  price: 17500,
  cost: 15000,
  stock: 1,
  active: false,
);

JournalEntry _jurnal(
        String kind, String label, int amount, DateTime at) =>
    JournalEntry(
        id: 'j-${label.hashCode}-$amount',
        kind: kind,
        label: label,
        amount: amount,
        createdAt: at);

void main() {
  group('kembalian', () {
    test('uang pas → 0', () {
      expect(kembalian(20000, 20000), 0);
    });
    test('uang lebih → selisih positif', () {
      expect(kembalian(50000, 32500), 17500);
    });
    test('uang kurang → negatif', () {
      expect(kembalian(10000, 15000), -5000);
    });
  });

  group('saranHargaJual', () {
    test('modal 8000 → 10000', () {
      expect(saranHargaJual(8000), 10000);
    });
    test('modal 8300 → 10500 (bulat ke atas kelipatan 500)', () {
      expect(saranHargaJual(8300), 10500);
    });
    test('modal 1000 → 1500', () {
      expect(saranHargaJual(1000), 1500);
    });
    test('modal 0 → 0', () {
      expect(saranHargaJual(0), 0);
    });
  });

  group('buildReceipt', () {
    test('struk 32 kolom, memuat total & kode', () {
      final lines = [
        const CartLine(product: _indomie, qty: 2),
        const CartLine(product: _aqua, qty: 1),
      ];
      final total = 2 * 3500 + 4000;
      final teks = buildReceipt(
        storeName: 'Warunge Mimi',
        code: 'KSR-20261006-120000',
        date: DateTime(2026, 10, 6, 12, 0),
        lines: lines,
        total: total,
        received: 20000,
      );
      expect(teks.contains('KSR-20261006-120000'), true);
      expect(teks.contains('Rp11.000'), true);
      expect(teks.contains('Rp20.000'), true);
      expect(teks.contains('Rp9.000'), true); // kembali
      for (final baris in teks.split('\n')) {
        expect(baris.length <= 32, true, reason: 'baris: $baris');
      }
    });
  });

  group('omzetPerHari', () {
    test('7 nilai, index 6 = hari ini, hanya pemasukan', () {
      final today = DateTime(2026, 10, 6, 15, 30);
      final entries = [
        _jurnal('penjualan', 'Kasir', 50000, DateTime(2026, 10, 6, 10)),
        _jurnal('penjualan', 'Kasir', 25000, DateTime(2026, 10, 5, 10)),
        _jurnal('kulakan', 'Kulakan · Supplier', -30000,
            DateTime(2026, 10, 6, 9)),
        _jurnal('penjualan', 'Kasir', 10000, DateTime(2026, 9, 20, 10)),
      ];
      final hasil = omzetPerHari(entries, today);
      expect(hasil.length, 7);
      expect(hasil[6], 50000); // hari ini
      expect(hasil[5], 25000); // kemarin
      expect(hasil.sublist(0, 5).every((e) => e == 0), true);
      expect(hasil.reduce((a, b) => a + b), 75000);
    });
  });

  group('buildCsv', () {
    test('header + baris, label berkoma dikutip', () {
      final entries = [
        _jurnal('penjualan', 'Kasir', 50000, DateTime(2026, 10, 6, 10)),
        _jurnal('kulakan', 'Kulakan, Belanja Stok', -30000,
            DateTime(2026, 10, 6, 9)),
      ];
      final csv = buildCsv(entries);
      final baris = csv.split('\n');
      expect(baris.first, 'tanggal,jenis,keterangan,nominal');
      expect(baris.length, 3);
      expect(baris[1].contains('2026-10-06'), true);
      expect(baris[1].contains('penjualan'), true);
      expect(baris[2].contains('"Kulakan, Belanja Stok"'), true);
      expect(baris[2].endsWith('-30000'), true);
    });
  });

  group('filter stok menipis', () {
    test('stok <= batas & aktif saja', () {
      const batas = 5;
      final semua = [_indomie, _aqua, _gulaNonaktif];
      final menipis =
          semua.where((p) => p.active && p.stock <= batas).toList();
      expect(menipis.length, 1);
      expect(menipis.first.id, 'p2');
    });
  });
}
