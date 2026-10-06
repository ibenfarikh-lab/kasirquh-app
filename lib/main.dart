import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/utils/startup_report.dart';
import 'core/widgets/notify.dart';
import 'data/local/app_database.dart';
import 'data/remote/messaging_service.dart';
import 'data/sync/sync_engine.dart';
import 'firebase_options.dart';

/// Bootstrap Fase 1: Firebase init → DB lokal → SyncEngine → runApp.
///
/// ATURAN KERAS: runApp() WAJIB tercapai apa pun yang terjadi.
/// Setiap langkah init dibungkus try-catch sendiri; kegagalan dicatat
/// di StartupReport dan aplikasi lanjut mode lokal (offline-first).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('id_ID');
  } catch (e) {
    StartupReport.add('format tanggal', e);
  }

  // DB lokal selalu diusahakan (offline-first).
  try {
    await AppDatabase.db;
  } catch (e) {
    StartupReport.add('database lokal', e);
  }

  SyncEngine? sync;
  final configured =
      !DefaultFirebaseOptions.android.apiKey.startsWith('TODO_');
  if (configured) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Handler FCM background (wajib setelah Firebase init).
      FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
      sync = SyncEngine(FirebaseFirestore.instance);
      await sync.start();
    } catch (e) {
      // Firebase gagal (mis. konfigurasi/API) → mode lokal, tanpa crash.
      StartupReport.add('firebase', e);
      debugPrint('Firebase init gagal, lanjut mode lokal: $e');
      sync = null;
    }
  } else {
    debugPrint(
        'Firebase belum dikonfigurasi (firebase_options placeholder) — '
        'jalan mode lokal saja. Lihat README > Setup.');
  }

  // Notifikasi lokal (heads-up pesanan/chat) — gagal diam-diam bila tak bisa.
  try {
    await Notify.init();
  } catch (e) {
    StartupReport.add('notifikasi lokal', e);
  }

  runApp(
    ProviderScope(
      overrides: [
        if (sync != null) syncEngineProvider.overrideWithValue(sync),
      ],
      child: const KasirQuhApp(),
    ),
  );
}
