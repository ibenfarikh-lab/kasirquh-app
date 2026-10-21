import 'package:flutter_test/flutter_test.dart';
import 'package:kasirquh_app/data/models/journal_entry.dart';
import 'package:kasirquh_app/features/admin/menu/report_page.dart';

JournalEntry entri({
  required String kind,
  required int amount,
  int profit = 0,
  String method = '',
  num itemCount = 0,
  DateTime? at,
}) =>
    JournalEntry(
      id: 'x$amount$profit',
      kind: kind,
      label: 'uji',
      amount: amount,
      createdAt: at ?? DateTime(2026, 10, 21, 10),
      profit: profit,
      method: method,
      itemCount: itemCount,
    );

void main() {
  group('ringkasanLaporan (P1-4, gaya Web)', () {
    test('hanya penjualan dihitung; laba dari field profit', () {
      final r = ringkasanLaporan([
        entri(kind: 'penjualan', amount: 10000, profit: 2500, itemCount: 2),
        entri(kind: 'penjualan', amount: 5000, profit: 1000, itemCount: 1),
        entri(kind: 'kulakan', amount: -7000, profit: 0),
        entri(kind: 'beban', amount: -1000, profit: 0),
      ]);
      expect(r.omset, 15000);
      expect(r.laba, 3500);
      expect(r.transaksi, 2);
      expect(r.item, 3);
    });

    test('tanpa penjualan -> semua nol', () {
      final r = ringkasanLaporan([
        entri(kind: 'modal', amount: 100000),
      ]);
      expect(r.omset, 0);
      expect(r.laba, 0);
      expect(r.transaksi, 0);
      expect(r.item, 0);
    });
  });

  group('penjualanTerbaru', () {
    test('hanya penjualan, terbaru dulu', () {
      final a = entri(
          kind: 'penjualan', amount: 1, at: DateTime(2026, 10, 20, 9));
      final b = entri(
          kind: 'penjualan', amount: 2, at: DateTime(2026, 10, 21, 9));
      final c = entri(
          kind: 'kulakan', amount: -3, at: DateTime(2026, 10, 21, 10));
      final out = penjualanTerbaru([a, b, c]);
      expect(out.length, 2);
      expect(out.first.amount, 2);
    });
  });
}
