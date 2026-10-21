import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/dering.dart';

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
    }
  }

  static int _id = 0;

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
