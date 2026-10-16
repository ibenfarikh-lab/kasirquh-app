import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Pencatat error ala PWA (2026-10-16).
/// Error tidak lagi cuma di console — dicatat agar terlihat.
/// - [entries]: 50 error terakhir di memori (untuk halaman Log Error admin)
/// - Firestore `client_errors`: untuk pantau remote (throttle 1/menit)
class ErrorEntry {
  final DateTime at;
  final String source;
  final String message;

  const ErrorEntry({
    required this.at,
    required this.source,
    required this.message,
  });
}

class ErrorLog {
  ErrorLog._();

  static final List<ErrorEntry> _entries = [];
  static DateTime? _lastRemoteAt;

  /// 50 error terakhir (terbaru di akhir).
  static List<ErrorEntry> get entries => List.unmodifiable(_entries);

  /// Catat error. Throttle kirim remote 1/menit, best-effort.
  static void log(String source, Object? error, [StackTrace? stack]) {
    String msg;
    if (error is String) {
      msg = error;
    } else {
      try {
        msg = error.toString();
      } catch (_) {
        msg = 'Unknown error';
      }
    }
    if (msg.length > 500) msg = msg.substring(0, 500);

    _entries.add(ErrorEntry(
      at: DateTime.now(),
      source: source,
      message: msg,
    ));
    if (_entries.length > 50) {
      _entries.removeRange(0, _entries.length - 50);
    }

    // Kirim remote: throttle 1/menit, hanya saat login.
    try {
      final now = DateTime.now();
      if (_lastRemoteAt != null &&
          now.difference(_lastRemoteAt!).inSeconds < 60) {
        return;
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      _lastRemoteAt = now;
      FirebaseFirestore.instance.collection('client_errors').add({
        'at': FieldValue.serverTimestamp(),
        'source': 'native:$source',
        'message': msg,
        'uid': user.uid,
      }).then((_) {}).catchError((_) {});
    } catch (_) {
      // best-effort: jangan crash karena gagal catat
    }
  }

  /// Hapus semua log lokal.
  static void clear() {
    _entries.clear();
  }
}
