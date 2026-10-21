import 'package:flutter_test/flutter_test.dart';
import 'package:kasirquh_app/features/customer/account/misi_koin_page.dart';

void main() {
  test('weekKeyOf sama dengan Web (JS)', () {
    final cases = <String, String>{
      '2026-10-21': '2026-W42',
      '2026-01-01': '2026-W00',
      '2026-01-04': '2026-W00',
      '2026-01-05': '2026-W01',
      '2025-12-29': '2026-W00',
      '2026-12-31': '2026-W52',
      '2027-01-01': '2026-W52',
      '2026-03-15': '2026-W10',
    };
    for (final e in cases.entries) {
      final d = DateTime.parse(e.key);
      expect(weekKeyOf(d), e.value, reason: e.key);
    }
    expect(claimKeyMisi('belanja_3x_minggu', DateTime(2026, 10, 21)),
        'misi_belanja3_2026-W42');
    expect(claimKeyMisi('coba_produk_baru', DateTime(2026, 10, 21)),
        'misi_coba_produk_baru');
  });
}
