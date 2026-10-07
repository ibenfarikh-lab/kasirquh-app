import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../l10n/strings_id.dart';

/// Modul Bukti Transfer (Mode Admin): daftar pesanan transfer yang
/// menunggu verifikasi → admin verifikasi (lanjut dikemas) atau tolak.
/// Tanpa pesanan transfer menunggu → empty state jujur.
class TransferOrdersPage extends ConsumerWidget {
  const TransferOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bukti Transfer')),
      body: ordersAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyState(
          icon: Icons.cloud_off_outlined,
          title: Strings.gagalMuatPesanan,
          hint: Strings.periksaKoneksi,
        ),
        data: (orders) {
          final menunggu = orders
              .where((o) =>
                  o.payment == 'transfer' &&
                  o.status == OrderStatus.menunggu)
              .toList();
          if (menunggu.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Belum ada transfer menunggu',
              hint:
                  'Pesanan transfer yang belum diverifikasi muncul di sini.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: menunggu.length,
            itemBuilder: (context, i) {
              final o = menunggu[i];
              return Card(
                color: AppColors.panel,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              o.customerName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                          Text(
                            formatRp(o.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${o.code} · ${o.items.length} barang',
                        style: const TextStyle(
                            color: AppColors.warmMuted,
                            fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 18),
                              label: const Text('Verifikasi'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.ok,
                              ),
                              onPressed: () => _verifikasi(
                                  context, ref, o, true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(
                                  Icons.cancel_outlined,
                                  size: 18),
                              label: const Text('Tolak'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    AppColors.danger,
                              ),
                              onPressed: () => _verifikasi(
                                  context, ref, o, false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _verifikasi(BuildContext context, WidgetRef ref,
      Order order, bool terima) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        // Aturan 3: dialog = L3.
        backgroundColor: AppColors.panel2,
        title: Text(terima
            ? 'Verifikasi transfer ini?'
            : 'Tolak pesanan ini?'),
        content: Text(
          '${order.customerName} · ${formatRp(order.total)}\n'
          '${terima ? 'Pesanan lanjut ke status Dikemas.' : 'Pesanan dibatalkan.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(Strings.batal),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              terima ? 'Verifikasi' : 'Tolak',
              style: TextStyle(
                  color: terima
                      ? AppColors.ok
                      : AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(adminRepositoryProvider).setOrderStatus(
            order.id,
            terima ? OrderStatus.dikemas : OrderStatus.dibatalkan,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(terima
                  ? 'Transfer diverifikasi.'
                  : 'Pesanan ditolak.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(Strings.butuhInternetAdmin)),
        );
      }
    }
  }
}
