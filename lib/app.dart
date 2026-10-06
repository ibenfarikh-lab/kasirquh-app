import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/gateway/gateway_screen.dart';
import 'l10n/strings_id.dart';

/// Akar aplikasi: tema per mode (terang = pelanggan, dark warm = admin/gateway).
/// Router penuh (Mode Pelanggan 5 Tab, Mode Admin 5 Tab + 13 modul)
/// dibangun bertahap di Fase 2–3.
class KasirQuhApp extends ConsumerWidget {
  const KasirQuhApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: Strings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.customerTheme(),
      darkTheme: AppTheme.adminTheme(),
      // Sementara: selalu terang (Mode Pelanggan). Mode Admin memakai
      // adminTheme() saat navigator admin aktif (Fase 3).
      themeMode: ThemeMode.light,
      home: const GatewayScreen(),
    );
  }
}
