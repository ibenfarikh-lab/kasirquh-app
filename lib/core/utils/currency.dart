import 'package:intl/intl.dart';

/// Format rupiah: integer, tanpa desimal. Contoh: Rp25.500
final _rp = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

String formatRp(num value) => _rp.format(value);
