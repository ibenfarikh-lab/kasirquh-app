import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

final densityPelangganProvider =
    StateNotifierProvider<PengaturanString, String>((ref) {
  return PengaturanString('densityPelanggan', 'ringkas');
});

final deringPelangganProvider =
    StateNotifierProvider<PengaturanString, String>((ref) {
  return PengaturanString('deringPelanggan', 'bawaan');
});
