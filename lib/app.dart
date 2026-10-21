import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/mode_provider.dart';
import 'core/theme/theme_settings.dart';
import 'features/gateway/gateway_screen.dart';
import 'l10n/strings_id.dart';

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
      tema = AppTheme.adminTheme();
    }

    return MaterialApp(
      title: Strings.appName,
      debugShowCheckedModeBanner: false,
      theme: tema,
      themeMode: ThemeMode.light,
      home: const GatewayScreen(),
    );
  }
}
