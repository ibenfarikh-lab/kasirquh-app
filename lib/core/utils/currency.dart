import 'package:intl/intl.dart';

final _rp = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

String formatRp(num value) => _rp.format(value);

final _angka = NumberFormat.decimalPattern('id_ID');

String formatAngka(num value) => _angka.format(value);

String formatStok(double v) {
  if (v == v.truncateToDouble()) return v.toInt().toString();
  final s = v.toString().replaceAll(RegExp(r'0+$'), '');
  return s.replaceAll('.', ',');
}

double parseDesimal(String text) {
  final t =
      text.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(t) ?? 0;
}
