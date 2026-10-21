import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/utils/error_log.dart';
import 'core/utils/startup_report.dart';
import 'core/widgets/notify.dart';
import 'data/local/app_database.dart';
import 'data/remote/messaging_service.dart';
import 'data/sync/sync_engine.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    try {
      ErrorLog.log('flutter', details.exception, details.stack);
    } catch (_) {}
    FlutterError.presentError(details);
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    try {
      ErrorLog.log('async', error, stack);
    } catch (_) {}
    return true;
  };

  try {
    await initializeDateFormatting('id_ID');
  } catch (e) {
    StartupReport.add('format tanggal', e);
  }

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
      FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
      sync = SyncEngine(FirebaseFirestore.instance);
      await sync.start();
    } catch (e) {
      StartupReport.add('firebase', e);
      debugPrint('Firebase init gagal, lanjut mode lokal: $e');
      sync = null;
    }
  } else {
    debugPrint(
        'Firebase belum dikonfigurasi (firebase_options placeholder) — '
        'jalan mode lokal saja. Lihat README > Setup.');
  }

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
