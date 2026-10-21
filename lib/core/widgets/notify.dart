import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/dering.dart';

/// Notifikasi lokal (heads-up) — dipicu listener Firestore saat aplikasi
/// berjalan: pesanan baru (admin), status pesanan berubah (pelanggan),
/// chat belum dibaca. Push background sungguhan butuh Cloud Functions
/// (Blaze) — belum dipakai sesuai keputusan user.
///
/// Bunyi mengikuti pilihan dering pemilik mode (perbaikan 2026-10-21:
/// sebelumnya pilihan dering hanya disimpan, tidak pernah diterapkan):
/// - bawaan → kanal 'kasirquh' (nada bawaan perangkat),
/// - khas   → kanal 'kasirquh_khas' (bunyi mimi_chime di res/raw),
/// - hening → kanal 'kasirquh_hening' (tanpa suara, getar saja).
class Notify {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _siap = false;

  static Future<void> init() async {
    if (_siap) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        const InitializationSettings(android: android),
        onDidReceiveNotificationResponse: (_) {},
      );
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await impl?.createNotificationChannel(
        const AndroidNotificationChannel(
          'kasirquh',
          'Warunge Mimi',
          description: 'Kabar pesanan & chat Warunge Mimi',
          importance: Importance.high,
        ),
      );
      await impl?.createNotificationChannel(
        const AndroidNotificationChannel(
          'kasirquh_khas',
          'Warunge Mimi · Khas Mimi',
          description: 'Kabar pesanan & chat dengan bunyi khas Mimi',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('mimi_chime'),
        ),
      );
      await impl?.createNotificationChannel(
        const AndroidNotificationChannel(
          'kasirquh_hening',
          'Warunge Mimi · Hening',
          description: 'Kabar pesanan & chat tanpa suara (getar saja)',
          importance: Importance.high,
          playSound: false,
        ),
      );
      _siap = true;
    } catch (_) {
      // Notifikasi gagal init → aplikasi tetap jalan tanpa heads-up.
    }
  }

  static int _id = 0;

  /// Tampilkan heads-up sekali dengan bunyi sesuai [dering].
  /// Gagal diam-diam bila belum init.
  static Future<void> headsUp(
    String title,
    String body, {
    ModeDering dering = ModeDering.bawaan,
    bool getar = true,
  }) async {
    if (!_siap) return;
    try {
      await _plugin.show(
        ++_id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            idKanalDering(dering),
            switch (dering) {
              ModeDering.khas => 'Warunge Mimi · Khas Mimi',
              ModeDering.hening => 'Warunge Mimi · Hening',
              ModeDering.bawaan => 'Warunge Mimi',
            },
            importance: Importance.high,
            priority: Priority.high,
            playSound: dering != ModeDering.hening,
            sound: dering == ModeDering.khas
                ? const RawResourceAndroidNotificationSound('mimi_chime')
                : null,
            enableVibration: getar,
          ),
        ),
      );
    } catch (_) {}
  }
}
