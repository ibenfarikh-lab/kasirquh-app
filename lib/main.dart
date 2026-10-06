import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/local/app_database.dart';
import 'data/sync/sync_engine.dart';
import 'firebase_options.dart';

/// Bootstrap Fase 1: Firebase init → DB lokal → SyncEngine → runApp.
/// firebase_options.dart masih PLACEHOLDER — Firebase dilewati dengan aman
/// sampai `flutterfire configure` dijalankan (lihat README).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  // DB lokal selalu siap (offline-first).
  await AppDatabase.db;

  SyncEngine? sync;
  final configured =
      !DefaultFirebaseOptions.android.apiKey.startsWith('TODO_');
  if (configured) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    sync = SyncEngine(FirebaseFirestore.instance);
    await sync.start();
  } else {
    debugPrint(
        'Firebase belum dikonfigurasi (firebase_options placeholder) — '
        'jalan mode lokal saja. Lihat README > Setup.');
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
