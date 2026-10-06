import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/auth_service.dart';

/// Sesi Mode Admin: hanya user dengan custom claim `admin: true`.
/// Akun admin dibuat manual di Firebase (Auth + claim via Admin SDK);
/// aplikasi tidak pernah mendaftarkan admin sendiri.
class AdminSession {
  final User user;
  final String email;

  const AdminSession({required this.user, required this.email});
}

/// Stream sesi admin: null = belum login / bukan admin / mode lokal.
final adminSessionProvider = StreamProvider<AdminSession?>((ref) async* {
  final auth = ref.watch(authServiceProvider);
  if (auth == null) {
    yield null;
    return;
  }
  await for (final user in auth.authState()) {
    if (user == null) {
      yield null;
      continue;
    }
    try {
      if (await auth.isCurrentUserAdmin()) {
        yield AdminSession(user: user, email: user.email ?? '');
      } else {
        yield null;
      }
    } catch (_) {
      yield null;
    }
  }
});
