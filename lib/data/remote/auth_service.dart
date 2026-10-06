import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Layanan Auth: email + kata sandi (keputusan dikunci — bukan OTP).
/// Pendaftar baru → customers/{uid} approvalStatus=pending → wajib
/// disetujui admin sebelum bisa login penuh.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService(this._auth, this._firestore);

  Stream<User?> authState() => _auth.authStateChanges();

  /// Daftar → buat user Auth + dokumen customers/{uid} pending.
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    await _firestore.collection('customers').doc(uid).set({
      'name': name,
      'email': email,
      'approvalStatus': 'pending',
      'coins': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _auth.signOut(); // keluar dulu sampai disetujui admin
  }

  /// Masuk → tolak jika approvalStatus != approved.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final doc = await _firestore
        .collection('customers')
        .doc(cred.user!.uid)
        .get();
    final status = doc.data()?['approvalStatus'] as String?;
    if (status != 'approved' && !_isAdminEmail(email)) {
      await _auth.signOut();
      throw const AuthPendingApproval();
    }
  }

  /// Admin: email+password + custom claim admin:true (dibuat manual).
  bool _isAdminEmail(String email) => email == 'admin@warung.id';

  Future<void> signOut() => _auth.signOut();
}

/// Dilempar saat login tapi akun belum disetujui admin.
class AuthPendingApproval implements Exception {
  const AuthPendingApproval();
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance, FirebaseFirestore.instance);
});
