import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/auth_service.dart';

class AdminSession {
  final User user;
  final String email;

  const AdminSession({required this.user, required this.email});
}

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
