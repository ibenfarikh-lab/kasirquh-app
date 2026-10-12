import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mode aktif aplikasi: 'gateway' | 'pelanggan' | 'admin'.
///
/// Dipakai app.dart untuk memilih ThemeData di level MaterialApp.
/// Tanpa ini, halaman yang dibuka via Navigator.push keluar dari
/// Theme yang membungkus shell — kembali ke tema default terang
/// (bug laporan user 2026-10-12: Misi Koin & Tebak Harga tetap
/// terang padahal tema gelap aktif).
final modeAktifProvider = StateProvider<String>((ref) => 'gateway');
