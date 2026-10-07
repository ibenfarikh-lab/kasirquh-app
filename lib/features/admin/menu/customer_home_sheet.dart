import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../l10n/strings_id.dart';

/// Beranda Pelanggan (promo) — panel tugas cepat admin.
class CustomerHomeSheet extends ConsumerWidget {
  const CustomerHomeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(adminPromosProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.adminLine,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                Strings.modulBerandaPelanggan,
                style: const TextStyle(
                  color: AppColors.warmText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const _RunningTextSection(),
              const SizedBox(height: 20),
              const _PaketSection(),
              const SizedBox(height: 20),
              Text(
                Strings.promo,
                style: const TextStyle(
                  color: AppColors.warmMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              promosAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.orange),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (promos) {
                  if (promos.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Belum ada promo.',
                        style: TextStyle(color: AppColors.warmMuted),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final p in promos)
                        _PromoTile(promo: p),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              AppButton(
                label: Strings.tambahPromo,
                onPressed: () => _tambahPromoDialog(context, ref),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _tambahPromoDialog(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final judul = TextEditingController();
    final subjudul = TextEditingController();
    final nilai = TextEditingController();
    String jenis = 'none'; // none | percent | amount
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.panel2,
          title: Text(
            Strings.tambahPromo,
            style: const TextStyle(color: AppColors.warmText),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: judul,
                autofocus: true,
                style: const TextStyle(color: AppColors.warmText),
                decoration: _dekorasi(Strings.judulPromo),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subjudul,
                style: const TextStyle(color: AppColors.warmText),
                decoration: _dekorasi(Strings.subjudulPromo),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: jenis,
                dropdownColor: AppColors.panel2,
                style: const TextStyle(color: AppColors.warmText),
                decoration: _dekorasi(Strings.jenisDiskon),
                items: const [
                  DropdownMenuItem(
                      value: 'none', child: Text('Tanpa diskon')),
                  DropdownMenuItem(
                      value: 'percent', child: Text('Diskon persen (%)')),
                  DropdownMenuItem(
                      value: 'amount',
                      child: Text('Potongan nominal (Rp)')),
                ],
                onChanged: (v) => setState(() => jenis = v ?? 'none'),
              ),
              if (jenis != 'none') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: nilai,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.warmText),
                  decoration: _dekorasi(jenis == 'percent'
                      ? Strings.nilaiPersen
                      : Strings.nilaiNominal),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                Strings.batal,
                style: const TextStyle(color: AppColors.warmMuted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                Strings.simpan,
                style: TextStyle(color: AppColors.orange),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final t = judul.text.trim();
    if (t.isEmpty) return;
    try {
      await ref.read(adminRepositoryProvider).savePromo({
        'title': t,
        'subtitle': subjudul.text.trim(),
        'discountType': jenis == 'none' ? null : jenis,
        'discountValue': int.tryParse(nilai.text.trim()) ?? 0,
        'isActive': true,
      });
      messenger.showSnackBar(
        SnackBar(content: Text(Strings.berhasilDisimpan)),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(Strings.butuhInternetAdmin)),
      );
    }
  }
}

/// Seksi teks berjalan — stateful agar prefill + ketikan tidak hilang
/// saat stream store info me-refresh.
class _RunningTextSection extends ConsumerStatefulWidget {
  const _RunningTextSection();

  @override
  ConsumerState<_RunningTextSection> createState() =>
      _RunningTextSectionState();
}

class _RunningTextSectionState extends ConsumerState<_RunningTextSection> {
  final _c = TextEditingController();
  bool _terisi = false;
  bool _menyimpan = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final runningText = ref.watch(storeInfoProvider).valueOrNull?.runningText;
    if (!_terisi && runningText != null) {
      _c.text = runningText;
      _terisi = true;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          Strings.teksBerjalan,
          style: const TextStyle(
            color: AppColors.warmMuted,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _c,
          maxLines: 2,
          style: const TextStyle(color: AppColors.warmText),
          decoration: _dekorasi(Strings.teksBerjalan),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            label: Strings.simpan,
            fullWidth: false,
            onPressed: _menyimpan
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _menyimpan = true);
                    try {
                      await ref
                          .read(adminRepositoryProvider)
                          .saveStoreSettings(
                              {'runningText': _c.text.trim()});
                      messenger.showSnackBar(
                        SnackBar(content: Text(Strings.berhasilDisimpan)),
                      );
                    } catch (_) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(Strings.butuhInternetAdmin)),
                      );
                    } finally {
                      if (mounted) setState(() => _menyimpan = false);
                    }
                  },
          ),
        ),
      ],
    );
  }
}

/// Paket Tanggal Muda — section Beranda pelanggan yang diatur warung.
/// Mati = section disembunyikan (bukan contoh).
class _PaketSection extends ConsumerStatefulWidget {
  const _PaketSection();

  @override
  ConsumerState<_PaketSection> createState() => _PaketSectionState();
}

class _PaketSectionState extends ConsumerState<_PaketSection> {
  final _judul = TextEditingController();
  final _subjudul = TextEditingController();
  bool _terisi = false;
  bool _aktif = false;
  bool _menyimpan = false;

  @override
  void dispose() {
    _judul.dispose();
    _subjudul.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(storeInfoProvider).valueOrNull;
    if (!_terisi && info != null) {
      _judul.text = info.paketTitle ?? '';
      _subjudul.text = info.paketSubtitle ?? '';
      _aktif = info.paketEnabled;
      _terisi = true;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Paket Tanggal Muda',
          style: TextStyle(
            color: AppColors.warmMuted,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text(
            'Tampilkan di Beranda pelanggan',
            style: TextStyle(color: AppColors.warmText),
          ),
          value: _aktif,
          activeThumbColor: AppColors.orange,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _aktif = v),
        ),
        TextField(
          controller: _judul,
          style: const TextStyle(color: AppColors.warmText),
          decoration: _dekorasi('Judul paket'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _subjudul,
          maxLines: 2,
          style: const TextStyle(color: AppColors.warmText),
          decoration: _dekorasi('Subjudul paket (opsional)'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            label: Strings.simpan,
            fullWidth: false,
            onPressed: _menyimpan
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _menyimpan = true);
                    try {
                      await ref
                          .read(adminRepositoryProvider)
                          .saveStoreSettings({
                        'paketEnabled': _aktif,
                        'paketTitle': _judul.text.trim(),
                        'paketSubtitle': _subjudul.text.trim(),
                      });
                      messenger.showSnackBar(
                        const SnackBar(
                            content: Text(Strings.berhasilDisimpan)),
                      );
                    } catch (_) {
                      messenger.showSnackBar(
                        const SnackBar(
                            content:
                                Text(Strings.butuhInternetAdmin)),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _menyimpan = false);
                      }
                    }
                  },
          ),
        ),
      ],
    );
  }
}

class _PromoTile extends ConsumerWidget {
  final Promo promo;

  const _PromoTile({required this.promo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      // Aturan 3: kartu = L2.
      color: AppColors.panel,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          promo.title,
          style: const TextStyle(
            color: AppColors.warmText,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: (promo.subtitle ?? '').isNotEmpty
            ? Text(
                promo.subtitle!,
                style: const TextStyle(color: AppColors.warmMuted),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: promo.isActive,
              activeThumbColor: AppColors.orange,
              onChanged: (v) async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ref
                      .read(adminRepositoryProvider)
                      .savePromo({'isActive': v}, id: promo.id);
                } catch (_) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(Strings.butuhInternetAdmin)),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.panel2,
                    title: const Text(
                      Strings.hapus,
                      style: TextStyle(color: AppColors.warmText),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(
                          Strings.batal,
                          style:
                              const TextStyle(color: AppColors.warmMuted),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(
                          Strings.hapus,
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                );
                if (ok != true) return;
                try {
                  await ref
                      .read(adminRepositoryProvider)
                      .deletePromo(promo.id);
                  messenger.showSnackBar(
                    SnackBar(content: Text(Strings.berhasilDihapus)),
                  );
                } catch (_) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(Strings.butuhInternetAdmin)),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _dekorasi(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.warmMuted),
    filled: true,
    // Aturan 3: input = L3.
    fillColor: AppColors.panel2,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.adminLine),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.orange),
    ),
  );
}
