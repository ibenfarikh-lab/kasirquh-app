import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

extension KonteksTema on BuildContext {
  bool get temaGelap => Theme.of(this).brightness == Brightness.dark;

  Color get teksUtama =>
      temaGelap ? AppColors.warmText : AppColors.ink;

  Color get teksRedup =>
      temaGelap ? AppColors.warmMuted : AppColors.muted;

  Color get garis => temaGelap ? AppColors.adminLine : AppColors.line;

  Color get permukaanKartu =>
      Theme.of(this).cardTheme.color ??
      (temaGelap ? AppColors.panel : AppColors.card);
}

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
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
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
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.panel2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.panel2,
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

  static ThemeData customerDarkTheme() {
    const bg = Color(0xFF000000);
    const kartu = Color(0xFF0A0908);
    const garis = Color(0xFF2A2A2A);
    const orangeKontras = Color(0xFFFF9B3E);
    const teks = Color(0xFFFFFFFF);
    const teksRedup = Color(0xFF9A9A9A);
    final scheme = const ColorScheme.dark(
      primary: orangeKontras,
      onPrimary: bg,
      surface: kartu,
      onSurface: teks,
      surfaceContainerHighest: kartu,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: AppText.textTheme(scheme),
      cardTheme: CardThemeData(
        color: kartu,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: garis, width: 1),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: kartu,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: kartu,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bg,
        selectedItemColor: orangeKontras,
        unselectedItemColor: teksRedup,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: garis,
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: teksRedup),
        hintStyle: TextStyle(color: teksRedup),
        floatingLabelStyle: TextStyle(color: orangeKontras),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: teks,
        elevation: 0,
      ),
    );
  }

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
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
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
