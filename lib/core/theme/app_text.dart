import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Skala tipografi Nunito Sans — dari DESIGN_SYSTEM.md.
class AppText {
  static TextTheme textTheme(ColorScheme scheme) {
    final base = GoogleFonts.nunitoSansTextTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 15),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 15),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
