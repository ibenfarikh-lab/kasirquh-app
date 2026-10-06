import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

/// ThemeData ganda: terang untuk Mode Pelanggan, dark warm untuk
/// Gateway + Mode Admin — dari DESIGN_SYSTEM.md.
class AppTheme {
  static ThemeData customerTheme() {
    final scheme = const ColorScheme.light(
      primary: AppColors.orange,
      onPrimary: Colors.white,
      surface: AppColors.card,
      onSurface: AppColors.ink,
      surfaceContainerHighest: AppColors.paper,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
      textTheme: AppText.textTheme(scheme),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 2,
        shadowColor: const Color(0x2E2E241D).withValues(alpha: 0.13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: AppColors.line,
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      // Label/hint field teks: JANGAN andalkan default framework —
      // diuji di HP: default-nya terlalu redup. Eksplisit per mode.
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: AppColors.muted),
        hintStyle: TextStyle(color: AppColors.muted),
        floatingLabelStyle: TextStyle(color: AppColors.orange),
      ),
    );
  }

  static ThemeData adminTheme() {
    final scheme = const ColorScheme.dark(
      primary: AppColors.orange,
      onPrimary: AppColors.adminBg,
      surface: AppColors.panel,
      onSurface: AppColors.warmText,
      surfaceContainerHighest: AppColors.panel2,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.adminBg,
      textTheme: AppText.textTheme(scheme),
      cardTheme: CardThemeData(
        color: AppColors.panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.adminLine, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.panel,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.warmMuted,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: AppColors.adminLine,
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      // Label/hint field teks: eksplisit — warmMuted terbukti kebaca
      // di atas panel gelap (temuan uji HP: default framework terlalu redup).
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: AppColors.warmMuted),
        hintStyle: TextStyle(color: AppColors.warmMuted),
        floatingLabelStyle: TextStyle(color: AppColors.orange),
      ),
    );
  }

  /// Varian gelap Mode Pelanggan — palet warm yang sama dengan admin,
  /// struktur terang pelanggan.
  static ThemeData customerDarkTheme() {
    final scheme = const ColorScheme.dark(
      primary: AppColors.orange,
      onPrimary: AppColors.adminBg,
      surface: AppColors.panel,
      onSurface: AppColors.warmText,
      surfaceContainerHighest: AppColors.panel2,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.adminBg,
      textTheme: AppText.textTheme(scheme),
      cardTheme: CardThemeData(
        color: AppColors.panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.adminLine, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.panel,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.warmMuted,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: AppColors.adminLine,
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: AppColors.warmMuted),
        hintStyle: TextStyle(color: AppColors.warmMuted),
        floatingLabelStyle: TextStyle(color: AppColors.orange),
      ),
    );
  }

  /// Varian terang Mode Admin — palet terang pelanggan.
  static ThemeData adminLightTheme() {
    final scheme = const ColorScheme.light(
      primary: AppColors.orange,
      onPrimary: Colors.white,
      surface: AppColors.card,
      onSurface: AppColors.ink,
      surfaceContainerHighest: AppColors.paper,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
      textTheme: AppText.textTheme(scheme),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 2,
        shadowColor: const Color(0x2E2E241D).withValues(alpha: 0.13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: AppColors.line,
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: AppColors.muted),
        hintStyle: TextStyle(color: AppColors.muted),
        floatingLabelStyle: TextStyle(color: AppColors.orange),
      ),
    );
  }
}
