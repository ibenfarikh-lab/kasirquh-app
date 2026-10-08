import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/remote/auth_service.dart';
import '../../l10n/strings_id.dart';
import 'biometric_credential_service.dart';
import 'biometric_optin_dialogs.dart';
import 'fingerprint_login_button.dart';

/// Sheet Login/Daftar: dua panel — Masuk & Daftar (email + kata sandi).
/// Pendaftar baru → menunggu persetujuan admin.
class LoginSheet extends ConsumerStatefulWidget {
  /// Tab awal: 0 = Masuk, 1 = Daftar.
  final int initialTab;

  const LoginSheet({super.key, this.initialTab = 0});

  @override
  ConsumerState<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends ConsumerState<LoginSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(
        length: 2,
        vsync: this,
        initialIndex: widget.initialTab.clamp(0, 1));
  }

  @override
  void dispose() {
    _tab.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authServiceProvider);
    if (auth == null) {
      // Mode lokal: Firebase tidak tersedia.
      setState(() {
        _error = 'Mode lokal: login butuh layanan online. Coba lagi nanti.';
        _busy = false;
      });
      return;
    }
    try {
      final email = _email.text.trim();
      final password = _password.text;
      await auth.signIn(
            email: email,
            password: password,
          );
      if (!mounted) return;
      // Alur A: tawarkan opt-in login cepat (sandi masih di memori).
      await tawarkanOptInSidikJari(
        context: context,
        ref: ref,
        accountId: 'customer',
        email: email,
        password: password,
        mode: 'customer',
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AuthPendingApproval {
      setState(() => _error = Strings.belumDisetujui);
    } catch (_) {
      setState(() => _error = Strings.masukGagal);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signUp() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authServiceProvider);
    if (auth == null) {
      setState(() {
        _error = 'Mode lokal: pendaftaran butuh layanan online. Coba lagi nanti.';
        _busy = false;
      });
      return;
    }
    try {
      await auth.signUp(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.menungguPersetujuan)),
        );
        Navigator.of(context).pop(false);
      }
    } catch (e) {
      // Jangan tampilkan exception mentah (bisa Inggris + detail teknis).
      setState(() => _error = _pesanDaftar(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Petakan galat pendaftaran ke Bahasa Indonesia yang ramah.
  String _pesanDaftar(Object e) {
    final msg = e.toString();
    if (msg.contains('email-already-in-use')) {
      return Strings.emailTerdaftar;
    }
    if (msg.contains('invalid-email')) return Strings.emailTidakValid;
    if (msg.contains('weak-password')) return Strings.sandiTerlaluLemah;
    if (msg.contains('network-request-failed')) {
      return Strings.butuhInternetUmum;
    }
    return Strings.daftarGagal;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Identitas: kicker + judul (prototipe: chip + judul modal).
            const Text(
              Strings.fiturKhususPelanggan,
              style: TextStyle(
                color: AppColors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              Strings.akunWarungJudul,
              style: TextStyle(
                color: context.teksUtama, // Aturan 4: adaptif.
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tab,
              labelColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: Strings.masuk),
                Tab(text: Strings.daftar),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 320,
              child: TabBarView(
                controller: _tab,
                children: [
                  _form(isLogin: true, onSubmit: _signIn),
                  _form(isLogin: false, onSubmit: _signUp),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form({required bool isLogin, required VoidCallback onSubmit}) {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (!isLogin)
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: Strings.nama,
                border: OutlineInputBorder(),
              ),
            ),
          if (!isLogin) const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: Strings.email,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: Strings.kataSandi,
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 16),
          AppButton(
            label: isLogin ? Strings.masuk : Strings.daftar,
            isLoading: _busy,
            onPressed: onSubmit,
          ),
          // Fingerprint Jalur Tercepat — hanya untuk mode Masuk.
          if (isLogin) const SizedBox(height: 12),
          if (isLogin)
            FingerprintLoginButton(
              accountId: 'customer',
              onCredential: (cred) async {
                final auth = ref.read(authServiceProvider);
                if (auth == null) return;
                setState(() {
                  _busy = true;
                  _error = null;
                });
                try {
                  await auth.signIn(email: cred.email, password: cred.password);
                  if (mounted) Navigator.of(context).pop(true);
                } on AuthPendingApproval {
                  await ref
                      .read(biometricCredentialServiceProvider)
                      .delete('customer');
                  setState(() => _error = Strings.masukGagal);
                } catch (_) {
                  setState(() => _error = Strings.masukGagal);
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
            ),
        ],
      ),
    );
  }
}
