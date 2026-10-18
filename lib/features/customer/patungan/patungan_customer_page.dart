import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/patungan.dart';
import '../../../data/repositories/admin_repository.dart';
import '../session.dart';

/// Halaman pelanggan: daftar patungan aktif + ikut.
/// Tampilan mengikuti PWA (renderPatunganList).
class PatunganCustomerPage extends ConsumerWidget {
  const PatunganCustomerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(patunganListProvider);
    final session = ref.watch(sessionProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Patungan Warga')),
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
              hint: 'Patungan aktif dari warung akan tampil di sini.',
            );
          }
          final uid = session?.user?.uid ?? '';
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _PatunganCustomerCard(
              patungan: list[i],
              customerId: uid,
              customerName: session?.name ?? '',
              isGuest: session?.isGuest ?? true,
            ),
          );
        },
      ),
    );
  }
}

/// Kartu patungan untuk pelanggan — progress + tombol ikut / tanda.
/// Mengikuti PWA (renderPatunganList).
class _PatunganCustomerCard extends ConsumerWidget {
  final Patungan patungan;
  final String customerId;
  final String customerName;
  final bool isGuest;

  const _PatunganCustomerCard({
    required this.patungan,
    required this.customerId,
    required this.customerName,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = patungan;
    final joined = !isGuest && p.isJoined(customerId);
    final isFull = p.status == 'penuh' || p.remainingSlots <= 0;

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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    // Aturan tema: dark = full black, tanpa warna lain.
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2A2A2A)
                        : context.garis,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${p.filledSlots}/${p.totalSlots} slot',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar ala PWA.
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: p.totalSlots > 0
                    ? p.filledSlots / p.totalSlots
                    : 0,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : context.garis,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.orange),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${p.productName} · ${formatRp(p.pricePerSlot)}/slot'
              '${p.deadline.isNotEmpty ? ' · s/d ${p.deadline}' : ''}',
              style:
                  TextStyle(color: context.teksRedup, fontSize: 13),
            ),
            if (p.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(p.note,
                    style: const TextStyle(fontSize: 13)),
              ),
            const SizedBox(height: 10),
            if (joined)
              Builder(
                builder: (context) {
                  final saya = p.participants.firstWhere(
                    (x) => x.customerId == customerId,
                    orElse: () => p.participants.first,
                  );
                  final lunas = saya.paymentStatus == 'lunas';
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (lunas ? AppColors.ok : AppColors.orange)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      lunas
                          ? 'Sudah ikut · Lunas'
                          : 'Sudah ikut · Menunggu bayar '
                              '(tunai/transfer, konfirmasi admin)',
                      style: TextStyle(
                          color:
                              lunas ? AppColors.ok : AppColors.orange,
                          fontWeight: FontWeight.w700),
                    ),
                  );
                },
              )
            else if (isFull)
              const Text(
                'Penuh',
                style: TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w700),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isGuest
                      ? () => _needLogin(context)
                      : () => _showJoinSheet(context, ref, p),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text('Ikut Patungan'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _needLogin(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Login dulu untuk ikut patungan')),
    );
  }

  /// Halaman pilih slot (1-10) + total — ala PWA (openJoinPatungan).
  /// Dulu bottom sheet; kini halaman penuh (aturan user 2026-10-18).
  void _showJoinSheet(
      BuildContext context, WidgetRef ref, Patungan p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _JoinPatunganPage(
          patungan: p,
          customerId: customerId,
          customerName: customerName,
        ),
      ),
    );
  }
}

/// Halaman konfirmasi ikut patungan: pilih slot + total.
class _JoinPatunganPage extends ConsumerStatefulWidget {
  final Patungan patungan;
  final String customerId;
  final String customerName;

  const _JoinPatunganPage({
    required this.patungan,
    required this.customerId,
    required this.customerName,
  });

  @override
  ConsumerState<_JoinPatunganPage> createState() =>
      _JoinPatunganPageState();
}

class _JoinPatunganPageState
    extends ConsumerState<_JoinPatunganPage> {
  int _qty = 1;

  Future<void> _konfirmasi(BuildContext context) async {
    final p = widget.patungan;
    try {
      await ref.read(adminRepositoryProvider).joinPatungan(
            patunganId: p.id,
            customerId: widget.customerId,
            customerName: widget.customerName,
            slots: _qty,
          );
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil ikut patungan')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final msg = e is StateError ? e.message : '$e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $msg')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patungan;
    final total = p.pricePerSlot * _qty;
    return Scaffold(
      appBar: AppBar(title: const Text('Ikut Patungan')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              p.title.isEmpty ? p.productName : p.title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '${p.productName} · ${formatRp(p.pricePerSlot)}/slot',
              style:
                  TextStyle(color: context.teksRedup, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _qty > 1
                      ? () => setState(() => _qty--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$_qty',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed:
                      _qty < 10 && _qty < p.remainingSlots
                          ? () => setState(() => _qty++)
                          : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ${formatRp(total)} untuk $_qty slot',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _konfirmasi(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.black87,
              ),
              child: const Text('Konfirmasi Ikut'),
            ),
          ],
        ),
      ),
    );
  }
}
