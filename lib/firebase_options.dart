// File ini dibuat otomatis dari google-services.json (Firebase Console).
// Project: kasirquh-app | Package: com.kasirquh.app
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Opsi Firebase untuk aplikasi KasirQuh-app.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Platform ini belum dikonfigurasi. Tambahkan aplikasi di Firebase Console.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCKaN5wwA7D3eWL65GkqDtr_aac0t2AQzY',
    appId: '1:279862438786:android:2e519e815db081c2b8fd9b',
    messagingSenderId: '279862438786',
    projectId: 'kasirquh-app',
    storageBucket: 'kasirquh-app.firebasestorage.app',
  );
}
