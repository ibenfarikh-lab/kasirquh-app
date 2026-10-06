import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// PIN Admin 6 digit — disimpan sebagai hash SHA-256 di secure storage.
/// Pertama kali: buat + konfirmasi. Lupa PIN → alur reset (hapus + buat baru).
class PinService {
  static const _key = 'admin_pin_hash';
  final FlutterSecureStorage _storage;

  PinService(this._storage);

  Future<bool> get hasPin async =>
      await _storage.read(key: _key) != null;

  String _hash(String pin) =>
      sha256.convert(utf8.encode('kasirquh-pin:$pin')).toString();

  Future<void> setPin(String pin) =>
      _storage.write(key: _key, value: _hash(pin));

  Future<bool> verify(String pin) async {
    final stored = await _storage.read(key: _key);
    return stored != null && stored == _hash(pin);
  }

  Future<void> reset() => _storage.delete(key: _key);
}

final pinServiceProvider = Provider<PinService>((ref) {
  return PinService(const FlutterSecureStorage());
});
