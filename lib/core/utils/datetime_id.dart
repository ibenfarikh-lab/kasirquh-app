import 'package:intl/intl.dart';

String formatTanggalJam(DateTime dt) =>
    DateFormat('d MMM yyyy · HH:mm', 'id_ID').format(dt);

String formatTanggal(DateTime dt) =>
    DateFormat('d MMM yyyy', 'id_ID').format(dt);
