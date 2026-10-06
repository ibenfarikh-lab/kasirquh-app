package com.kasirquh.app

import io.flutter.embedding.android.FlutterFragmentActivity

// WAJIB FlutterFragmentActivity (bukan FlutterActivity): plugin sidik jari
// (local_auth) memakai BiometricPrompt yang butuh FragmentActivity.
// Kalau pakai FlutterActivity biasa → authenticate() langsung ditolak
// (no_fragment_activity) tanpa dialog sistem pernah tampil.
class MainActivity : FlutterFragmentActivity()
