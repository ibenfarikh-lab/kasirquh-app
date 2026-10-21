import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/patungan.dart';
import '../../../data/repositories/admin_repository.dart';
import '../admin_nav.dart';

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
        onPressed: () => _bukaBuatPatungan(context),
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

  /// Halaman penuh form buat patungan (migrasi dari bottom sheet).
  void _bukaBuatPatungan(BuildContext context) {
    openAdminPage(context, const _BuatPatunganPage());
  }
}

/// Halaman penuh "Buat Patungan" — field SAMA PERSIS dengan PWA.
class _BuatPatunganPage extends ConsumerStatefulWidget {
  const _BuatPatunganPage();

  @override
  ConsumerState<_BuatPatunganPage> createState() =>
      _BuatPatunganPageState();
}

class _BuatPatunganPageState extends ConsumerState<_BuatPatunganPage> {
  final _titleC = TextEditingController();
  final _productC = TextEditingController();
  final _priceC = TextEditingController();
  final _slotsC = TextEditingController();
  final _deadlineC = TextEditingController();
  final _noteC = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _titleC.dispose();
    _productC.dispose();
    _priceC.dispose();
    _slotsC.dispose();
    _deadlineC.dispose();
    _noteC.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (_busy) return;
    final title = _titleC.text.trim();
    final product = _productC.text.trim();
    final price =
        int.tryParse(_priceC.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final slots = int.tryParse(_slotsC.text) ?? 0;
    if (title.isEmpty || product.isEmpty || price <= 0 || slots < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Lengkapi nama, produk, harga, dan slot (min 2)')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).createPatungan(
            title: title,
            productName: product,
            pricePerSlot: price,
            totalSlots: slots,
            deadline: _deadlineC.text.trim(),
            note: _noteC.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patungan dibuat')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Patungan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field(_titleC, 'Nama patungan',
              'Contoh: Patungan Minyak Goreng'),
          _field(_productC, 'Produk', 'Contoh: Minyak Goreng 2L'),
          _field(_priceC, 'Harga per slot (Rp)', 'Contoh: 25000',
              numeric: true),
          _field(_slotsC, 'Jumlah slot', 'Contoh: 10', numeric: true),
          _field(
              _deadlineC, 'Tenggat', 'Contoh: 12 Oktober 2026'),
          _field(_noteC, 'Catatan', 'Opsional', maxLines: 2),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _simpan,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.black87,
            ),
            child: Text(_busy ? 'Menyimpan...' : 'Buat Patungan'),
          ),
        ],
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
            // Daftar peserta + status bayar (keputusan user: admin
            // konfirmasi lunas manual setelah tunai/transfer).
            if (p.participants.isEmpty)
              Text(
                'Belum ada peserta',
                style:
                    TextStyle(color: context.teksRedup, fontSize: 13),
              )
            else
              for (final ps in p.participants)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${ps.name} (${ps.slots} slot)',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      _bayarPill(ps),
                      const SizedBox(width: 8),
                      if (ps.belumLunas)
                        TextButton(
                          onPressed: () => _konfirmasiBayar(
                              context, ref, p.id, ps),
                          child: const Text('Konfirmasi Lunas'),
                        ),
                    ],
                  ),
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

  Widget _bayarPill(PatunganParticipant ps) {
    // Definisi lunas tunggal di model — nilai warisan 'menunggu'
    // tetap tampil "Menunggu bayar" (belum lunas).
    final lunas = ps.sudahLunas;
    final color = lunas ? AppColors.ok : AppColors.orange;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        lunas ? 'Lunas' : 'Menunggu bayar',
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _konfirmasiBayar(BuildContext context, WidgetRef ref,
      String patunganId, PatunganParticipant ps) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Konfirmasi pembayaran'),
        content: Text(
            'Tandai ${ps.name} (${ps.slots} slot) sudah lunas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(d).pop(true),
            child: const Text('Ya, Lunas'),
          ),
        ],
      ),
    );
    if (ya != true || !context.mounted) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .setPatunganPayment(patunganId, ps.customerId, true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pembayaran ditandai lunas')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
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
