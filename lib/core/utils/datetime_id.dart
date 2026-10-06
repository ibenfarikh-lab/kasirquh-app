import 'package:intl/intl.dart';

/// Format tanggal Bahasa Indonesia. Contoh: 6 Okt 2026 · 12:26
String formatTanggalJam(DateTime dt) =>
    DateFormat('d MMM yyyy · HH:mm', 'id_ID').format(dt);

/// Format tanggal saja. Contoh: 6 Okt 2026
String formatTanggal(DateTime dt) =>
    DateFormat('d MMM yyyy', 'id_ID').format(dt);
