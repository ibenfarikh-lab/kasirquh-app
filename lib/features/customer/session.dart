import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/auth_service.dart';
import '../../data/remote/firestore_service.dart';

/// Sesi Mode Pelanggan: tamu (guest) atau member yang sudah disetujui.
/// Pendaftar pending/rejected diperlakukan sebagai tamu — AuthService
/// memang langsung signOut pendaftar yang belum disetujui.
class Session {
  final bool isGuest;
  final User? user;
  final String name;
  final String email;
  final int coins;

  const Session.guest()
      : isGuest = true,
        user = null,
        name = '',
        email = '',
        coins = 0;

  const Session.member({
    required this.user,
    required this.name,
    required this.email,
    required this.coins,
  }) : isGuest = false;
}

/// Stream sesi: authState + dokumen customers/{uid}.
/// Non-approved → tamu (aman untuk guard).
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
    // Anti-gagal-diam-diam: error baca dokumen DITERUSKAN (bukan jadi tamu).
    // "Dokumen tidak ada" sudah ditangani oleh cek data != null di bawah.
    final doc = await db.collection('customers').doc(user.uid).get();
    final data = doc.data();
    if (data != null && data['approvalStatus'] == 'approved') {
      yield Session.member(
        user: user,
        name: (data['name'] as String?) ?? '',
        email: (data['email'] as String?) ?? user.email ?? '',
        coins: (data['coins'] as num?)?.toInt() ?? 0,
      );
    } else {
      yield const Session.guest();
    }
  }
});

/// Ambil uid member; null bila tamu.
String? memberUid(Session s) =>
    s.isGuest ? null : s.user?.uid;

/// Nama tampilan: nama member, atau 'Tamu'.
String displayName(Session s) =>
    s.isGuest ? 'Tamu' : (s.name.isEmpty ? (s.email) : s.name);
