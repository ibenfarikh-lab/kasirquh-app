import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/mode_provider.dart';
import 'core/theme/theme_settings.dart';
import 'features/gateway/gateway_screen.dart';
import 'l10n/strings_id.dart';

/// Akar aplikasi: tema dipilih di level MaterialApp berdasar mode aktif.
///
/// Alasan (bug 2026-10-12): Theme yang hanya membungkus shell tidak
/// menjangkau halaman yang dibuka via Navigator.push — route baru
/// dibangun di atas shell sehingga kembali ke tema default.
/// Dengan tema di MaterialApp, seluruh route ikut tema yang benar.
class KasirQuhApp extends ConsumerWidget {
  const KasirQuhApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(modeAktifProvider);
    final sistem =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    late final ThemeData tema;
    if (mode == 'admin') {
      final t = ref.watch(temaAdminProvider);
      tema = temaAdminAktif(t, sistem);
    } else if (mode == 'pelanggan') {
      final t = ref.watch(temaPelangganProvider);
      tema = temaPelangganAktif(t, sistem);
    } else {
      // Gateway: selalu gelap.
      tema = AppTheme.adminTheme();
    }

    return MaterialApp(
      title: Strings.appName,
      debugShowCheckedModeBanner: false,
      // Tema dihitung manual berdasar mode — selalu pakai yang ini.
      theme: tema,
      themeMode: ThemeMode.light,
      home: const GatewayScreen(),
    );
  }
}
