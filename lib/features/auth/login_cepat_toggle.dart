import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/strings_id.dart';
import 'biometric_credential_service.dart';
import 'biometric_optin_dialogs.dart';

/// Toggle "Login cepat sidik jari" — reusable untuk admin & pelanggan.
///
/// accountId: 'admin' atau 'customer'
/// verifySignIn: callback untuk verifikasi sandi (signInAdmin vs signIn)
class LoginCepatToggle extends ConsumerStatefulWidget {
  final String accountId;
  final Future<void> Function(String email, String password) verifySignIn;

  const LoginCepatToggle({
    super.key,
    required this.accountId,
    required this.verifySignIn,
  });

  @override
  ConsumerState<LoginCepatToggle> createState() => _LoginCepatToggleState();
}

class _LoginCepatToggleState extends ConsumerState<LoginCepatToggle> {
  bool _aktif = false;
  bool _didukung = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _muat());
  }

  Future<void> _muat() async {
    final svc = ref.read(biometricCredentialServiceProvider);
    final didukung = await svc.isAvailable;
    final ada = await svc.read(widget.accountId) != null;
    if (!mounted) return;
    setState(() {
      _didukung = didukung;
      _aktif = ada;
    });
  }

  Future<void> _toggle(bool v) async {
    final svc = ref.read(biometricCredentialServiceProvider);
    if (v) {
      final password = await mintaKataSandiOptIn(context);
      if (password == null || password.isEmpty || !mounted) return;
      final okBio = await svc.verifyBiometric(Strings.alasanVerifikasiSidikJari);
      if (!okBio || !mounted) return;
      try {
        final email = FirebaseAuth.instance.currentUser?.email;
        if (email == null || email.isEmpty) return;
        await widget.verifySignIn(email, password);
        await svc.save(
          accountId: widget.accountId,
          email: email,
          password: password,
          mode: widget.accountId,
        );
        if (!mounted) return;
        setState(() => _aktif = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.sidikJariTersimpan)),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kata sandi salah')),
        );
      }
    } else {
      final ya = await konfirmasiNonaktifkanSidikJari(context);
      if (!ya || !mounted) return;
      await svc.delete(widget.accountId);
      setState(() => _aktif = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Strings.sidikJariDihapus)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_didukung) return const SizedBox.shrink();
    return SwitchListTile(
      value: _aktif,
      activeThumbColor: AppColors.orange,
      secondary: const Icon(Icons.fingerprint, color: AppColors.orange),
      title: const Text(Strings.loginCepatSidikJari),
      subtitle: const Text(Strings.loginCepatSidikJariHint),
      onChanged: _toggle,
    );
  }
}
