import 'package:flutter_test/flutter_test.dart';

import 'package:kasirquh_app/data/models/journal_entry.dart';
import 'package:kasirquh_app/features/admin/menu/ledger_page.dart';
import 'package:kasirquh_app/l10n/strings_id.dart';

JournalEntry _e(String label, int amount, DateTime at) => JournalEntry(
      id: label,
      kind: 'penjualan',
      label: label,
      amount: amount,
      createdAt: at,
    );

/// Penyelarasan Pembukuan — helper murni.
void main() {
  test('batasPeriode hari: 00:00 hari ini s/d 00:00 besok', () {
    final (from, to) = batasPeriode(0, DateTime(2026, 10, 7, 15, 30));
    expect(from, DateTime(2026, 10, 7));
    expect(to, DateTime(2026, 10, 8));
  });

  test('batasPeriode minggu: Senin 00:00 s/d Senin berikutnya', () {
    // 7 Okt 2026 = Rabu → minggu 5–12 Okt 2026.
    final (from, to) = batasPeriode(1, DateTime(2026, 10, 7, 15, 30));
    expect(from, DateTime(2026, 10, 5));
    expect(to, DateTime(2026, 10, 12));
  });

  test('batasPeriode bulan: tgl 1 00:00 s/d tgl 1 bulan berikut', () {
    final (from, to) = batasPeriode(2, DateTime(2026, 10, 7, 15, 30));
    expect(from, DateTime(2026, 10, 1));
    expect(to, DateTime(2026, 11, 1));
  });

  test('filterJurnalPeriode: hanya entri dalam [from, to)', () {
    final semua = [
      _e('a', 1000, DateTime(2026, 10, 7, 10)),
      _e('b', -500, DateTime(2026, 10, 6, 10)),
      _e('c', 2000, DateTime(2026, 10, 8, 0, 0)), // tepat di batas to
    ];
    final hasil = filterJurnalPeriode(
        semua, DateTime(2026, 10, 7), DateTime(2026, 10, 8));
    expect(hasil.map((e) => e.label), ['a']);
  });

  test('saldoAwalSudahAda: true bila ada label Saldo awal kas', () {
    expect(
        saldoAwalSudahAda(
            [_e(Strings.saldoAwalKas, 50000, DateTime(2026, 1, 1))]),
        isTrue);
    expect(
        saldoAwalSudahAda(
            [_e('Jualan', 10000, DateTime(2026, 10, 7))]),
        isFalse);
    expect(saldoAwalSudahAda(const []), isFalse);
  });
}
