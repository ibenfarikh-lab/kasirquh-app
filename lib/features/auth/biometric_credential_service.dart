import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Layanan kredensial sidik jari — "Fingerprint Jalur Tercepat".
///
/// Prinsip: `local_auth` sebagai GERBANG, `flutter_secure_storage`
/// sebagai BRANKAS. Kredensial hanya dibaca SETELAH biometric lolos.
///
/// - Setup sekali per akun (opt-in eksplisit).
/// - PIN tidak berubah (hash satu arah, gembok lokal terpisah).
/// - Fallback selalu ke login manual (tidak ada jalan buntu).
class BiometricCredentialService {
  static const _prefix = 'bio_cred_';
  static const _indexKey = 'bio_cred_index';

  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;

  BiometricCredentialService(this._storage, [LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  String _key(String accountId) => '$_prefix$accountId';

  /// Apakah perangkat mendukung biometric?
  Future<bool> get isAvailable async {
    try {
      return await _auth.canCheckBiometrics &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Minta verifikasi sidik jari. Return true bila lolos.
  Future<bool> verifyBiometric(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Simpan kredensial (panggil SETELAH biometric lolos saat opt-in).
  /// password diambil dari input form login (tidak bisa dari Firebase Auth).
  Future<void> save({
    required String accountId,
    required String email,
    required String password,
    required String mode, // 'admin' | 'customer'
    String? label,
  }) async {
    final data = jsonEncode({
      'email': email,
      'password': password,
      'mode': mode,
      'label': label ?? email,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _storage.write(key: _key(accountId), value: data);
    await _addToIndex(accountId);
  }

  /// Baca kredensial (panggil SETELAH biometric lolos).
  /// Return null bila tidak ada.
  Future<BiometricCredential?> read(String accountId) async {
    final raw = await _storage.read(key: _key(accountId));
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return BiometricCredential(
        accountId: accountId,
        email: m['email'] as String,
        password: m['password'] as String,
        mode: m['mode'] as String,
        label: (m['label'] as String?) ?? m['email'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  /// Hapus kredensial satu akun.
  Future<void> delete(String accountId) async {
    await _storage.delete(key: _key(accountId));
    await _removeFromIndex(accountId);
  }

  /// Daftar accountId yang sudah opt-in.
  Future<List<String>> listAccounts() async {
    final raw = await _storage.read(key: _indexKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _addToIndex(String accountId) async {
    final list = await listAccounts();
    if (!list.contains(accountId)) {
      list.add(accountId);
      await _storage.write(key: _indexKey, value: jsonEncode(list));
    }
  }

  Future<void> _removeFromIndex(String accountId) async {
    final list = await listAccounts();
    list.remove(accountId);
    await _storage.write(key: _indexKey, value: jsonEncode(list));
  }
}

/// Kredensial tersimpan untuk satu akun.
class BiometricCredential {
  final String accountId;
  final String email;
  final String password;
  final String mode; // 'admin' | 'customer'
  final String label;

  const BiometricCredential({
    required this.accountId,
    required this.email,
    required this.password,
    required this.mode,
    required this.label,
  });

  bool get isAdmin => mode == 'admin';
}

final biometricCredentialServiceProvider =
    Provider<BiometricCredentialService>((ref) {
  return BiometricCredentialService(const FlutterSecureStorage());
});
