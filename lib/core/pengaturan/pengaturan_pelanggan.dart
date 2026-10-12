import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pilihan tampilan produk Mode Pelanggan — Ringkas / Lega / Daftar.
enum DensityPilihan {
  ringkas,
  lega,
  daftar;

  static DensityPilihan fromString(String? s) => switch (s) {
        'lega' => DensityPilihan.lega,
        'daftar' => DensityPilihan.daftar,
        _ => DensityPilihan.ringkas,
      };
}

/// Pilihan dering notifikasi — Bawaan HP / Khas Mimi / Hening.
enum DeringPilihan {
  bawaan,
  khas,
  hening;

  static DeringPilihan fromString(String? s) => switch (s) {
        'khas' => DeringPilihan.khas,
        'hening' => DeringPilihan.hening,
        _ => DeringPilihan.bawaan,
      };
}

/// Penyimpanan string sederhana yang persisten (SharedPreferences).
/// Dipakai untuk density & dering (pola sama seperti ThemeSettings).
class PengaturanString extends StateNotifier<String> {
  final String _key;

  PengaturanString(this._key, String def) : super(def) {
    _muat();
  }

  Future<void> _muat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_key);
      if (s != null) state = s;
    } catch (_) {}
  }

  Future<void> pilih(String nilai) async {
    state = nilai;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, nilai);
    } catch (_) {}
  }
}

/// Tampilan produk Mode Pelanggan (default: ringkas).
final densityPelangganProvider =
    StateNotifierProvider<PengaturanString, String>((ref) {
  return PengaturanString('densityPelanggan', 'ringkas');
});

/// Dering notifikasi Mode Pelanggan (default: bawaan).
final deringPelangganProvider =
    StateNotifierProvider<PengaturanString, String>((ref) {
  return PengaturanString('deringPelanggan', 'bawaan');
});
