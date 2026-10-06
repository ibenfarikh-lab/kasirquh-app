import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/theme_settings.dart';

/// Pemilih tema (Terang / Gelap / Ikuti HP) — dipakai Pengaturan admin
/// dan sisi pelanggan. Bukan tile mati: pilihan tersimpan persisten.
class ThemePickerSheet extends ConsumerWidget {
  /// Provider yang dipakai (temaPelangganProvider / temaAdminProvider).
  final StateNotifierProvider<ThemeSettings, TemaPilihan> provider;

  const ThemePickerSheet({super.key, required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aktif = ref.watch(provider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tampilan',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih tema aplikasi.',
              style: TextStyle(
                  color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            RadioGroup<TemaPilihan>(
              groupValue: aktif,
              onChanged: (v) {
                if (v == null) return;
                ref.read(provider.notifier).pilih(v);
                Navigator.of(context).pop();
              },
              child: Column(
                children: [
                  for (final pilihan in TemaPilihan.values)
                    RadioListTile<TemaPilihan>(
                      value: pilihan,
                      title: Text(pilihan.label),
                      secondary: Icon(pilihan.icon,
                          color: AppColors.orange),
                      activeColor: AppColors.orange,
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tampilkan pemilih tema sebagai bottom sheet.
Future<void> showThemePicker(
  BuildContext context,
  StateNotifierProvider<ThemeSettings, TemaPilihan> provider,
) {
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => ThemePickerSheet(provider: provider),
  );
}
