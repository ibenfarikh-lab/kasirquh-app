import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notifikasi lokal (heads-up) — dipicu listener Firestore saat aplikasi
/// berjalan: pesanan baru (admin), status pesanan berubah (pelanggan),
/// chat belum dibaca. Push background sungguhan butuh Cloud Functions
/// (Blaze) — belum dipakai sesuai keputusan user.
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
      const channel = AndroidNotificationChannel(
        'kasirquh',
        'KasirQuh',
        description: 'Kabar pesanan & chat Warunge Mimi',
        importance: Importance.high,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      _siap = true;
    } catch (_) {
      // Notifikasi gagal init → aplikasi tetap jalan tanpa heads-up.
    }
  }

  static int _id = 0;

  /// Tampilkan heads-up sekali. Gagal diam-diam bila belum init.
  static Future<void> headsUp(String title, String body) async {
    if (!_siap) return;
    try {
      await _plugin.show(
        ++_id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'kasirquh',
            'KasirQuh',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (_) {}
  }
}
