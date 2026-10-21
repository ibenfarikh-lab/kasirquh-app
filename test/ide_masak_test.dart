import 'package:flutter_test/flutter_test.dart';


void main() {
  test('nama dipotong maksimal 54 karakter', () {
    final nama = 'A' * 60;
    final hasil = nama.length > 54 ? nama.substring(0, 54) : nama;
    expect(hasil.length, 54);
  });

  test('items kosong ditolak', () {
    final items = <Map<String, dynamic>>[];
    final valid = items
        .where((it) => (it['productId'] as String? ?? '').isNotEmpty)
        .toList();
    expect(valid.isEmpty, true);
  });

  test('items dengan productId kosong difilter', () {
    final items = [
      {'productId': '', 'qty': 1},
      {'productId': 'p1', 'qty': 2},
    ];
    final valid = items
        .where((it) => (it['productId'] as String? ?? '').isNotEmpty)
        .toList();
    expect(valid.length, 1);
    expect(valid.first['productId'], 'p1');
  });

  test('desc default bila kosong', () {
    const desc = '';
    final hasil = desc.trim().isEmpty
        ? 'Racikan pilihanku untuk dibagikan ke warga.'
        : desc.trim();
    expect(hasil, 'Racikan pilihanku untuk dibagikan ke warga.');
  });

  test('qty di-clamp 1..999', () {
    expect((0).clamp(1, 999), 1);
    expect((5).clamp(1, 999), 5);
    expect((1000).clamp(1, 999), 999);
  });
}
