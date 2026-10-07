import 'package:intl/intl.dart';

/// Format rupiah: integer, tanpa desimal. Contoh: Rp25.500
final _rp = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

String formatRp(num value) => _rp.format(value);

/// Format stok: bulat tampil tanpa desimal ("10"), desimal dipertahankan
/// ("3,75"). Tanpa field unit di skema — aturan murni tampilan:
/// ada pecahan → koma Indonesia; bulat → bilangan bulat.
String formatStok(double v) {
  if (v == v.truncateToDouble()) return v.toInt().toString();
  final s = v.toString().replaceAll(RegExp(r'0+$'), '');
  return s.replaceAll('.', ',');
}

/// Parse angka desimal ala Indonesia ("3,75" / "3.75" → 3.75).
/// Dipakai untuk input stok/qty yang boleh desimal.
double parseDesimal(String text) {
  final t =
      text.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(t) ?? 0;
}
