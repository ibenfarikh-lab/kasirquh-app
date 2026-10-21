import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/auth_service.dart';
import '../../data/remote/firestore_service.dart';

class Session {
  final bool isGuest;
  final bool isAdmin;
  final User? user;
  final String name;
  final String email;
  final int coins;
  final String? photoURL;
  final String? address;

  const Session.guest()
      : isGuest = true,
        isAdmin = false,
        user = null,
        name = '',
        email = '',
        coins = 0,
        photoURL = null,
        address = null;

  const Session.member({
    required this.user,
    required this.name,
    required this.email,
    required this.coins,
    this.photoURL,
    this.address,
  })  : isGuest = false,
        isAdmin = false;

  const Session.admin({
    required this.user,
    required this.email,
  })  : isGuest = false,
        isAdmin = true,
        name = 'Admin',
        coins = 0,
        photoURL = null,
        address = null;
}

final sessionProvider = StreamProvider<Session>((ref) async* {
  final auth = ref.watch(authServiceProvider);
  final db = ref.watch(firestoreOrNullProvider);
  if (auth == null || db == null) {
    yield const Session.guest();
    return;
  }
  await for (final user in auth.authState()) {
    if (user == null) {
      yield const Session.guest();
      continue;
    }
    if (await auth.isAdmin(user)) {
      yield Session.admin(user: user, email: user.email ?? '');
      continue;
    }
    final doc = await db.collection('customers').doc(user.uid).get();
    final data = doc.data();
    if (data != null && data['approvalStatus'] == 'approved') {
      yield Session.member(
        user: user,
        name: (data['name'] as String?) ?? '',
        email: (data['email'] as String?) ?? user.email ?? '',
        coins: (data['coins'] as num?)?.toInt() ?? 0,
        photoURL: data['photoURL'] as String?,
        address: data['address'] as String?,
      );
    } else {
      yield const Session.guest();
    }
  }
});

String? memberUid(Session s) =>
    s.isGuest ? null : s.user?.uid;

String displayName(Session s) {
  if (s.isGuest) return 'Tamu';
  if (s.isAdmin) return 'Admin';
  return s.name.isEmpty ? s.email : s.name;
}
