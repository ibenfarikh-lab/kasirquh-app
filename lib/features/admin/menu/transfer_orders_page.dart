import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../l10n/strings_id.dart';

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
          final daftar = orders
              .where((o) =>
                  o.payment == 'transfer' &&
                  o.status != OrderStatus.selesai &&
                  o.status != OrderStatus.dibatalkan)
              .toList();
          if (daftar.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Belum ada transfer',
              hint:
                  'Pesanan transfer (menunggu & ditolak) muncul di sini.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: daftar.length,
            itemBuilder: (context, i) {
              final o = daftar[i];
              final ditolak = o.transferStatus == 'rejected';
              return Card(
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
                          _statusPill(ditolak),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${o.code} · ${o.items.length} barang · '
                        '${formatRp(o.total)}',
                        style: TextStyle(
                            color: context.teksRedup,
                            fontSize: 13),
                      ),
                      if (o.transferReference.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 4),
                          child: Text(
                            'Ref: ${o.transferReference}',
                            style: TextStyle(
                                color: context.teksUtama,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      if (ditolak &&
                          o.transferRejectReason.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 4),
                          child: Text(
                            'Alasan: ${o.transferRejectReason}',
                            style: const TextStyle(
                                color: AppColors.danger,
                                fontSize: 13),
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (!ditolak)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                    Icons.check_circle_outline,
                                    size: 18),
                                label:
                                    const Text('Verifikasi'),
                                style:
                                    OutlinedButton.styleFrom(
                                  foregroundColor:
                                      AppColors.ok,
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
                                label:
                                    const Text('Tolak'),
                                style:
                                    OutlinedButton.styleFrom(
                                  foregroundColor:
                                      AppColors.danger,
                                ),
                                onPressed: () => _verifikasi(
                                    context, ref, o, false),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(
                                Icons.refresh_outlined,
                                size: 18),
                            label: const Text(
                                'Verifikasi ulang (sudah dibayar)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.ok,
                            ),
                            onPressed: () =>
                                _verifikasiUlang(
                                    context, ref, o),
                          ),
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

  Widget _statusPill(bool ditolak) {
    final color = ditolak ? AppColors.danger : AppColors.orange;
    final label = ditolak ? 'DITOLAK' : 'PERIKSA';
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
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _verifikasi(BuildContext context, WidgetRef ref,
      Order order, bool terima) async {
    String alasan = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(terima
              ? 'Verifikasi transfer ini?'
              : 'Tolak bukti transfer?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                '${order.customerName} · ${formatRp(order.total)}\n'
                '${terima ? 'Pesanan lanjut ke status Dikemas.' : 'Kartu tetap tampil dengan status DITOLAK.'}',
              ),
              if (!terima) ...[
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Alasan penolakan',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => alasan = v,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(false),
              child: const Text(Strings.batal),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(true),
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
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (terima) {
        await repo.setOrderStatus(
            order.id, OrderStatus.dikemas);
      } else {
        await repo.rejectTransfer(order.id, alasan);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(terima
                  ? 'Transfer diverifikasi.'
                  : 'Transfer ditolak.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  Future<void> _verifikasiUlang(
      BuildContext context, WidgetRef ref, Order order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verifikasi ulang?'),
        content: Text(
            '${order.customerName} · ${formatRp(order.total)}\n'
            'Pesanan lanjut ke status Dikemas.'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(false),
            child: const Text(Strings.batal),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(true),
            child: const Text('Verifikasi',
                style: TextStyle(color: AppColors.ok)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .clearTransferRejection(
              order.id, OrderStatus.dikemas);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Transfer diverifikasi ulang.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }
}
