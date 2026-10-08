import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/strings_id.dart';
import 'biometric_credential_service.dart';

/// Dialog penawaran opt-in "Login cepat sidik jari" (Alur A).
///
/// Ditampilkan setelah login manual berhasil, bila:
/// - biometric tersedia di HP
/// - belum ada kredensial tersimpan untuk akun ini
///
/// Return true bila user mengaktifkan (kredensial tersimpan).
Future<bool> tawarkanOptInSidikJari({
  required BuildContext context,
  required WidgetRef ref,
  required String accountId,
  required String email,
  required String password,
  required String mode, // 'admin' | 'customer'
}) async {
  final svc = ref.read(biometricCredentialServiceProvider);

  // Sudah ada? Jangan tawarkan lagi.
  if (await svc.read(accountId) != null) return false;
  if (!await svc.isAvailable) return false;

  if (!context.mounted) return false;
  final aktifkan = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Aktifkan login cepat?'),
      content: const Text(
        'Simpan info login dengan aman di HP ini. '
        'Selanjutnya cukup verifikasi sidik jari untuk masuk.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Nanti'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Aktifkan'),
        ),
      ],
    ),
  );

  if (aktifkan != true || !context.mounted) return false;

  // Verifikasi biometric dulu, baru simpan.
  final ok = await svc.verifyBiometric(Strings.alasanVerifikasiSidikJari);
  if (!ok) return false; // dibatalkan/gagal → diam

  await svc.save(
    accountId: accountId,
    email: email,
    password: password,
    mode: mode,
  );

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(Strings.sidikJariTersimpan)),
    );
  }
  return true;
}

/// Dialog minta kata sandi untuk opt-in dari Pengaturan (Alur B).
///
/// Return password bila user mengisi, null bila batal.
Future<String?> mintaKataSandiOptIn(BuildContext context) async {
  final ctrl = TextEditingController();
  try {
    return await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Masukkan kata sandi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diperlukan untuk mengaktifkan login cepat sidik jari.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Kata sandi',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) =>
                  Navigator.of(ctx).pop(ctrl.text.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
  } finally {
    ctrl.dispose();
  }
}

/// Dialog konfirmasi nonaktifkan (Alur C).
Future<bool> konfirmasiNonaktifkanSidikJari(BuildContext context) async {
  final ya = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Matikan login cepat?'),
      content: const Text(
        'Info login yang tersimpan akan dihapus dari HP ini.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Ya, matikan'),
        ),
      ],
    ),
  );
  return ya == true;
}
