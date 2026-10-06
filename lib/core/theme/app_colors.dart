import 'package:flutter/material.dart';

/// Token warna dari DESIGN_SYSTEM.md (diekstrak dari prototipe V3,
/// terverifikasi OK di HP 2026-10-06).
class AppColors {
  // Mode Pelanggan — terang (light)
  static const paper = Color(0xFFF7F4F1);
  static const card = Color(0xFFFFFDFB);
  static const ink = Color(0xFF242329);
  static const muted = Color(0xFF777277);
  static const line = Color(0xFFDED8D2);

  // Gateway + Mode Admin — dark warm
  static const adminBg = Color(0xFF120D0B);
  static const panel = Color(0xFF211F20);
  static const panel2 = Color(0xFF302E2F);
  static const adminLine = Color(0xFF5B3B27);
  static const warmText = Color(0xFFF7F1EC);
  static const warmMuted = Color(0xFFBDB2AD);
  static const warmHighlight = Color(0xFFFFB45F);

  // Aksen oranye (kedua mode)
  static const orange = Color(0xFFF49A24);
  static const orange2 = Color(0xFFFFBD61);
  static const orangeDeep = Color(0xFFA95F12);
  static const ctaGradient = LinearGradient(
    colors: [Color(0xFFFF8D25), Color(0xFFFFC267)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Semantik
  static const danger = Color(0xFFDF624F);
  static const ok = Color(0xFF4D8A62);

  // Status pesanan
  static const statusWaiting = orange; // MENUNGGU
  static const statusDone = ok; // selesai/disetujui
  static const statusRejected = danger; // ditolak/batal
}
