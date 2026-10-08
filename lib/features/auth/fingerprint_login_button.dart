import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/strings_id.dart';
import 'biometric_credential_service.dart';

/// Tombol "Masuk dengan sidik jari" — reusable untuk login cepat.
///
/// Tampil hanya bila: biometric tersedia + ada kredensial tersimpan
/// untuk accountId yang diminta.
class FingerprintLoginButton extends ConsumerStatefulWidget {
  final String accountId;
  final Future<void> Function(BiometricCredential cred) onCredential;

  const FingerprintLoginButton({
    super.key,
    required this.accountId,
    required this.onCredential,
  });

  @override
  ConsumerState<FingerprintLoginButton> createState() =>
      _FingerprintLoginButtonState();
}

class _FingerprintLoginButtonState
    extends ConsumerState<FingerprintLoginButton> {
  bool _visible = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final svc = ref.read(biometricCredentialServiceProvider);
    final available = await svc.isAvailable;
    final cred = await svc.read(widget.accountId);
    if (mounted) {
      setState(() => _visible = available && cred != null);
    }
  }

  Future<void> _login() async {
    setState(() => _busy = true);
    try {
      final svc = ref.read(biometricCredentialServiceProvider);
      final ok = await svc.verifyBiometric(Strings.alasanVerifikasiSidikJari);
      if (!ok) return; // dibatalkan/gagal → diam, fallback manual
      final cred = await svc.read(widget.accountId);
      if (cred == null) {
        if (mounted) setState(() => _visible = false);
        return;
      }
      await widget.onCredential(cred);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return OutlinedButton.icon(
      onPressed: _busy ? null : _login,
      icon: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.fingerprint, color: AppColors.orange),
      label: Text(
        Strings.masukDenganSidikJari,
        style: const TextStyle(color: AppColors.orange),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.orange),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }
}
