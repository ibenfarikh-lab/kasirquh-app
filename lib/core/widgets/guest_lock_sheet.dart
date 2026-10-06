import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../l10n/strings_id.dart';
import '../../features/auth/login_sheet.dart';
import '../../features/customer/session.dart';

/// Gembok tamu: "Mau lanjut? Login atau daftar dulu ya..."
/// Mengembalikan true bila pengguna berhasil masuk → panggil aksi tertunda.
class GuestLockSheet extends ConsumerWidget {
  const GuestLockSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 32,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              Strings.guestLockTitle,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              Strings.guestLockBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 15),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: Strings.masuk,
              onPressed: () => _openLogin(context, 0),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: Strings.daftar,
              kind: AppButtonKind.secondary,
              onPressed: () => _openLogin(context, 1),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLogin(BuildContext context, int tab) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => LoginSheet(initialTab: tab),
    );
    if (ok == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }
}

/// Minta login bila tamu; jalankan [onGranted] setelah berhasil masuk.
/// Mengembalikan true bila aksi dijalankan.
Future<bool> requireLogin(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() onGranted,
) async {
  final session = ref.read(sessionProvider).valueOrNull;
  if (session != null && !session.isGuest) {
    await onGranted();
    return true;
  }
  final ok = await showModalBottomSheet<bool>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const GuestLockSheet(),
  );
  if (ok == true) {
    await onGranted();
    return true;
  }
  return false;
}
