import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService(this._auth, this._firestore);

  Stream<User?> authState() => _auth.authStateChanges();

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String? address,
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
    await _auth.signOut();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
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

  Future<bool> isCurrentUserAdmin() =>
      _hasAdminClaim(_auth.currentUser);

  Future<bool> isAdmin(User? user) => _hasAdminClaim(user);

  Future<void> signOut() => _auth.signOut();
}

class AdminNotAuthorized implements Exception {
  const AdminNotAuthorized();
}

class AuthPendingApproval implements Exception {
  const AuthPendingApproval();
}

class AdminWrongDoor implements Exception {
  const AdminWrongDoor();
}

final authServiceProvider = Provider<AuthService?>((ref) {
  try {
    return AuthService(FirebaseAuth.instance, FirebaseFirestore.instance);
  } catch (_) {
    return null;
  }
});
