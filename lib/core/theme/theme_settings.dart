import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

enum TemaPilihan {
  terang,
  gelap,
  sistem;

  String get label => switch (this) {
        TemaPilihan.terang => 'Terang',
        TemaPilihan.gelap => 'Gelap',
        TemaPilihan.sistem => 'Otomatis',
      };

  IconData get icon => switch (this) {
        TemaPilihan.terang => Icons.light_mode_outlined,
        TemaPilihan.gelap => Icons.dark_mode_outlined,
        TemaPilihan.sistem => Icons.smartphone_outlined,
      };

  static TemaPilihan fromString(String? s) => switch (s) {
        'gelap' => TemaPilihan.gelap,
        'sistem' => TemaPilihan.sistem,
        'oled' => TemaPilihan.gelap,
        _ => TemaPilihan.terang,
      };
}

class ThemeSettings extends StateNotifier<TemaPilihan> {
  final String _key;

  ThemeSettings(this._key, TemaPilihan def) : super(def) {
    _muat();
  }

  Future<void> _muat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_key);
      if (s != null) state = TemaPilihan.fromString(s);
    } catch (_) {}
  }

  Future<void> pilih(TemaPilihan pilihan) async {
    state = pilihan;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, pilihan.name);
    } catch (_) {}
  }
}

final temaPelangganProvider =
    StateNotifierProvider<ThemeSettings, TemaPilihan>((ref) {
  return ThemeSettings('temaPelanggan', TemaPilihan.terang);
});

final temaAdminProvider =
    StateNotifierProvider<ThemeSettings, TemaPilihan>((ref) {
  return ThemeSettings('temaAdmin', TemaPilihan.gelap);
});

bool resolveGelap(TemaPilihan pilihan, Brightness sistem) =>
    switch (pilihan) {
      TemaPilihan.terang => false,
      TemaPilihan.gelap => true,
      TemaPilihan.sistem => sistem == Brightness.dark,
    };

ThemeData temaPelangganAktif(TemaPilihan pilihan, Brightness sistem) {
  return resolveGelap(pilihan, sistem)
      ? AppTheme.customerDarkTheme()
      : AppTheme.customerTheme();
}

ThemeData temaAdminAktif(TemaPilihan pilihan, Brightness sistem) {
  return resolveGelap(pilihan, sistem)
      ? AppTheme.adminTheme()
      : AppTheme.adminLightTheme();
}
