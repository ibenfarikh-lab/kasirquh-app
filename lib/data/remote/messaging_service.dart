import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firestore_service.dart';

/// Handler background FCM — wajib top-level.
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  // Disengaja minimal: tanpa Cloud Functions (Blaze) tidak ada pengirim
  // push server; token tetap disimpan untuk kesiapan masa depan.
  debugPrint('FCM background: ${message.messageId}');
}

/// Layanan push (FCM):
/// - minta izin notifikasi (setelah penjelasan jujur di UI),
/// - ambil token & simpan ke customers/{uid}.fcmToken (member)
///   atau store_settings/main.adminFcmTokens (admin),
/// - pesan foreground diteruskan ke UI sebagai banner dalam aplikasi.
class MessagingService {
  final FirebaseFirestore? _db;
  bool _jalan = false;

  MessagingService(this._db);

  /// Minta izin + ambil token. Kembalikan token (null bila ditolak/gagal).
  /// [onForeground] dipanggil untuk pesan saat aplikasi terbuka.
  /// [simpanUlang] dipanggil saat token di-refresh (untuk simpan ulang).
  Future<String?> init({
    required Future<bool> Function() mintaIzinDulu,
    required void Function(String judul, String isi) onForeground,
    required Future<void> Function(String token) simpanUlang,
  }) async {
    if (_jalan) return FirebaseMessaging.instance.getToken();
    try {
      final boleh = await mintaIzinDulu();
      if (!boleh) return null;
      final settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus !=
              AuthorizationStatus.provisional) {
        return null;
      }
      final token = await FirebaseMessaging.instance.getToken();
      FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n != null) {
          onForeground(n.title ?? 'Warunge Mimi', n.body ?? '');
        }
      });
      FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
        try {
          await simpanUlang(t);
        } catch (e) {
          debugPrint('Simpan ulang FCM token gagal: $e');
        }
      });
      _jalan = true;
      return token;
    } catch (e) {
      debugPrint('FCM init gagal: $e');
      return null;
    }
  }

  /// Simpan token ke dokumen pelanggan (dipanggil setelah login member).
  Future<void> simpanTokenMember(String uid, String token) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('customers').doc(uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Simpan FCM token gagal: $e');
    }
  }

  /// Simpan token admin ke store_settings/main (tulis = admin, sesuai rules).
  Future<void> simpanTokenAdmin(String token) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('store_settings').doc('main').set(
        {
          'adminFcmTokens': FieldValue.arrayUnion([token]),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Simpan FCM token admin gagal: $e');
    }
  }
}

final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService(ref.watch(firestoreOrNullProvider));
});
