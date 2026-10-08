import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/patungan.dart';
import '../../../data/repositories/admin_repository.dart';

/// Tab Mode Admin > Modul Patungan Warga: buat + kelola patungan.
/// Skema & alur SAMA PERSIS dengan PWA (koleksi `patungan`).
class PatunganPage extends ConsumerWidget {
  const PatunganPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(patunganListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Patungan Warga')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Buat Patungan'),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.black87,
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.groups_outlined,
          title: 'Gagal memuat',
          hint: '$e',
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.groups_outlined,
              title: 'Belum ada patungan',
              hint: 'Buat patungan baru lewat tombol di bawah.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) =>
                _PatunganAdminCard(patungan: list[i]),
          );
        },
      ),
    );
  }

  /// Bottom sheet form buat patungan — field SAMA PERSIS dengan PWA.
  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    final titleC = TextEditingController();
    final productC = TextEditingController();
    final priceC = TextEditingController();
    final slotsC = TextEditingController();
    final deadlineC = TextEditingController();
    final noteC = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Buat Patungan',
                style: TextStyle(
                  color: context.teksUtama,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _field(titleC, 'Nama patungan', 'Contoh: Patungan Minyak Goreng'),
              _field(productC, 'Produk', 'Contoh: Minyak Goreng 2L'),
              _field(priceC, 'Harga per slot (Rp)',
                  'Contoh: 25000',
                  numeric: true),
              _field(slotsC, 'Jumlah slot', 'Contoh: 10',
                  numeric: true),
              _field(deadlineC, 'Tenggat',
                  'Contoh: 12 Oktober 2026'),
              _field(noteC, 'Catatan', 'Opsional', maxLines: 2),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final title = titleC.text.trim();
                  final product = productC.text.trim();
                  final price = int.tryParse(
                          priceC.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                      0;
                  final slots = int.tryParse(slotsC.text) ?? 0;
                  if (title.isEmpty ||
                      product.isEmpty ||
                      price <= 0 ||
                      slots < 2) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Lengkapi nama, produk, harga, dan slot (min 2)')),
                    );
                    return;
                  }
                  try {
                    await ref
                        .read(adminRepositoryProvider)
                        .createPatungan(
                          title: title,
                          productName: product,
                          pricePerSlot: price,
                          totalSlots: slots,
                          deadline: deadlineC.text.trim(),
                          note: noteC.text.trim(),
                        );
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Patungan dibuat')),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Gagal: $e')),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.black87,
                ),
                child: const Text('Buat Patungan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    String hint, {
    bool numeric = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: numeric ? TextInputType.number : null,
        inputFormatters:
            numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// Kartu patungan untuk admin — daftar peserta + aksi selesai/batal.
/// Tampilan mengikuti PWA (renderPatunganAdminList).
class _PatunganAdminCard extends ConsumerWidget {
  final Patungan patungan;

  const _PatunganAdminCard({required this.patungan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = patungan;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.title.isEmpty ? p.productName : p.title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                _statusPill(p.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${p.productName} · ${formatRp(p.pricePerSlot)}/slot · '
              '${p.filledSlots}/${p.totalSlots} terisi',
              style:
                  TextStyle(color: context.teksRedup, fontSize: 13),
            ),
            if (p.deadline.isNotEmpty)
              Text(
                'Tenggat: ${p.deadline}',
                style:
                    TextStyle(color: context.teksRedup, fontSize: 13),
              ),
            if (p.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(p.note,
                    style: const TextStyle(fontSize: 13)),
              ),
            const SizedBox(height: 6),
            Text(
              p.participants.isEmpty
                  ? 'Belum ada peserta'
                  : 'Peserta: ${p.participants.map((x) => '${x.name} (${x.slots})').join(', ')}',
              style:
                  TextStyle(color: context.teksRedup, fontSize: 13),
            ),
            const SizedBox(height: 10),
            // Progress bar ala PWA.
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: p.totalSlots > 0
                    ? p.filledSlots / p.totalSlots
                    : 0,
                backgroundColor: context.garis,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.orange),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _setStatus(
                        context, ref, p.id, 'selesai'),
                    child: const Text('Selesai'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _setStatus(context, ref, p.id, 'batal'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger),
                    child: const Text('Batalkan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    final label = switch (status) {
      'aktif' => 'Aktif',
      'penuh' => 'Penuh',
      'selesai' => 'Selesai',
      'batal' => 'Batal',
      _ => status,
    };
    final color = switch (status) {
      'aktif' => AppColors.orange,
      'penuh' => Colors.blue,
      'selesai' => AppColors.ok,
      _ => AppColors.danger,
    };
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _setStatus(
      BuildContext context, WidgetRef ref, String id, String status) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .setPatunganStatus(id, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(status == 'selesai'
                  ? 'Patungan ditandai selesai'
                  : 'Patungan dibatalkan')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }
}
