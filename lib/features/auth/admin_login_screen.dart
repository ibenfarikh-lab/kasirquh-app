import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../data/remote/auth_service.dart';
import '../../l10n/strings_id.dart';
import '../admin/admin_shell.dart';

/// Login KHUSUS admin: email + kata sandi SAJA (tidak ada pendaftaran).
/// Akun admin dibuat manual di Firebase + custom claim `admin: true`.
/// Sukses → cek claim → Mode Admin.
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _skipIfAlreadyAdmin();
  }

  Future<void> _skipIfAlreadyAdmin() async {
    final auth = ref.read(authServiceProvider);
    if (auth == null) return;
    try {
      if (await auth.isCurrentUserAdmin() && mounted) {
        _goAdmin();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
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
      setState(() {
        _error = Strings.butuhInternetAdmin;
        _busy = false;
      });
      return;
    }
    try {
      await auth.signInAdmin(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (mounted) _goAdmin();
    } on AdminNotAuthorized {
      setState(() => _error = Strings.bukanAdmin);
    } catch (_) {
      setState(() => _error = Strings.masukGagal);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goAdmin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.warmText,
        title: const Text(Strings.appName),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                Strings.adminMasuk,
                style: TextStyle(
                  color: AppColors.warmText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                Strings.adminMasukHint,
                style: TextStyle(color: AppColors.warmMuted),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.warmText),
                decoration: const InputDecoration(
                  labelText: Strings.email,
                  labelStyle: TextStyle(color: AppColors.warmMuted),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.adminLine),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                style: const TextStyle(color: AppColors.warmText),
                decoration: const InputDecoration(
                  labelText: Strings.kataSandi,
                  labelStyle: TextStyle(color: AppColors.warmMuted),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.adminLine),
                  ),
                ),
                onSubmitted: (_) => _busy ? null : _signIn(),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              const SizedBox(height: 16),
              AppButton(
                label: Strings.masuk,
                isLoading: _busy,
                onPressed: _signIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
