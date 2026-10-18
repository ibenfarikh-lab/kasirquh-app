import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_settings.dart';

/// Buka halaman admin dengan tema yang benar (Aturan 1: konsistensi mode).
///
/// Halaman yang di-push via Navigator TIDAK mewarisi Theme widget milik
/// AdminShell — konteks `builder` adalah konteks Navigator di level
/// MaterialApp (yang themeMode-nya light). Tanpa pembungkus eksplisit,
/// halaman admin tampil light meski mode dark aktif.
///
/// Helper ini memastikan setiap halaman admin selalu membawa temanya sendiri.
void openAdminPage(BuildContext context, Widget page) {
  final pilihan =
      ProviderScope.containerOf(context).read(temaAdminProvider);
  final sistem = MediaQuery.platformBrightnessOf(context);
  final tema = temaAdminAktif(pilihan, sistem);
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => Theme(data: tema, child: page)),
  );
}
