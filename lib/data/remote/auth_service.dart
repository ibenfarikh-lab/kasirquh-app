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
    String? address, // opsional — selaras Web ?v=20261020ar
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    await _firestore.collection('customers').doc(uid).set({
      'name': name,
      'email': email,
      if (address != null && address.trim().isNotEmpty)
        'address': address.trim(),
      'approvalStatus': 'pending',
      'coins': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _auth.signOut(); // keluar dulu sampai disetujui admin
  }

  /// Masuk → tolak jika approvalStatus != approved.
  /// Admin (claim admin:true) boleh masuk tanpa dokumen customers.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Pola Web (2026-10-17): admin yang login via pintu pelanggan DITOLAK.
    // "Ini akun admin — masuk lewat pintu admin"
    if (await _hasAdminClaim(cred.user)) {
      await _auth.signOut();
      throw const AdminWrongDoor();
    }
    final doc = await _firestore
        .collection('customers')
        .doc(cred.user!.uid)
        .get();
    final status = doc.data()?['approvalStatus'] as String?;
    if (status != 'approved') {
      await _auth.signOut();
      throw const AuthPendingApproval();
    }
  }

  /// Masuk KHUSUS admin: email + kata sandi, lalu wajib claim admin:true.
  /// Akun admin dibuat manual di Firebase (bukan dari aplikasi).
  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (!await _hasAdminClaim(cred.user, forceRefresh: true)) {
      await _auth.signOut();
      throw const AdminNotAuthorized();
    }
  }

  /// Cek custom claim `admin: true` dari ID token.
  Future<bool> _hasAdminClaim(User? user,
      {bool forceRefresh = false}) async {
    if (user == null) return false;
    try {
      final token = await user.getIdTokenResult(forceRefresh);
      return token.claims?['admin'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Apakah pengguna saat ini admin (untuk guard UI).
  Future<bool> isCurrentUserAdmin() =>
      _hasAdminClaim(_auth.currentUser);

  /// Apakah user tertentu adalah admin (untuk session).
  Future<bool> isAdmin(User? user) => _hasAdminClaim(user);

  Future<void> signOut() => _auth.signOut();
}

/// Dilempar saat login admin tapi akun tidak punya claim admin:true.
class AdminNotAuthorized implements Exception {
  const AdminNotAuthorized();
}

/// Dilempar saat login tapi akun belum disetujui admin.
class AuthPendingApproval implements Exception {
  const AuthPendingApproval();
}

/// Dilempar saat akun admin login via pintu/form pelanggan.
/// Pola Web: "Ini akun admin — masuk lewat pintu admin".
class AdminWrongDoor implements Exception {
  const AdminWrongDoor();
}

/// Provider auth — NULLABLE: null berarti Firebase tidak tersedia
/// (mode lokal). Pemanggil wajib menangani null dengan pesan ramah,
/// bukan meledak dengan [core/no-app].
final authServiceProvider = Provider<AuthService?>((ref) {
  try {
    return AuthService(FirebaseAuth.instance, FirebaseFirestore.instance);
  } catch (_) {
    return null; // mode lokal: lanjut tanpa login online
  }
});
