import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../l10n/strings_id.dart';

final _statusFilterProvider = StateProvider<OrderStatus?>((ref) => null);

String _statusName(OrderStatus status) => switch (status.name) {
      'menunggu' => Strings.statusMenunggu,
      'dikemas' => Strings.statusDikemas,
      'dikirim' => Strings.statusDikirim,
      'selesai' => Strings.statusSelesai,
      'dibatalkan' => Strings.statusDibatalkan,
      _ => status.name,
    };

Color _statusColor(OrderStatus status) => switch (status) {
      OrderStatus.menunggu => AppColors.orange,
      OrderStatus.dikemas => AppColors.orange,
      OrderStatus.dikirim => Colors.blue,
      OrderStatus.selesai => AppColors.ok,
      OrderStatus.dibatalkan => AppColors.danger,
    };

String _formatDateTime(DateTime d) =>
    '${d.day}/${d.month}/${d.year} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

class OnlineOrdersPage extends ConsumerWidget {
  const OnlineOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_statusFilterProvider);
    final ordersAsync = ref.watch(adminOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(Strings.modulKasirOnline)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: DropdownButton<OrderStatus?>(
              value: filter,
              items: [
                const DropdownMenuItem<OrderStatus?>(
                  value: null,
                  child: Text(Strings.semuaStatus),
                ),
                for (final s in OrderStatus.values)
                  DropdownMenuItem<OrderStatus?>(
                    value: s,
                    child: Text(_statusName(s)),
                  ),
              ],
              onChanged: (v) =>
                  ref.read(_statusFilterProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: ordersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => const EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: Strings.pesananKosong,
                hint: Strings.pesananKosongHint,
              ),
              data: (orders) {
                final shown = orders
                    .where((o) => filter == null || o.status == filter)
                    .toList();
                if (shown.isEmpty) {
                  return const EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: Strings.pesananKosong,
                    hint: Strings.pesananKosongHint,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: shown.length,
                  itemBuilder: (context, i) {
                    final order = shown[i];
                    return Card(
                      child: ListTile(
                        title: Text(
                          order.customerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${order.items.length} barang · '
                          '${formatRp(order.total)} · ${order.payment}\n'
                          '${_formatDateTime(order.createdAt)}',
                        ),
                        trailing: Chip(
                          label: Text(
                            _statusName(order.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: _statusColor(order.status),
                        ),
                        onTap: () => _showDetail(context, ref, order),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetail(
      BuildContext context, WidgetRef ref, Order order) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
          title: const Text(Strings.detailPesanan),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(_formatDateTime(order.createdAt)),
                const Divider(height: 20),
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${item.qty}× ${item.name} — '
                      '${formatRp(item.qty * item.price)}',
                    ),
                  ),
                const Divider(height: 20),
                Text(
                  'Total: ${formatRp(order.total)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(Strings.ubahStatus),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<OrderStatus>(
                        value: order.status,
                        isExpanded: true,
                        items: [
                          for (final s in OrderStatus.values)
                            DropdownMenuItem<OrderStatus>(
                              value: s,
                              child: Text(_statusName(s)),
                            ),
                        ],
                        onChanged: (v) async {
                          if (v == null || v == order.status) return;
                          try {
                            await ref
                                .read(adminRepositoryProvider)
                                .setOrderStatus(order.id, v);
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text(Strings.berhasilDisimpan)),
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        Strings.butuhInternetAdmin)),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (order.status != OrderStatus.selesai &&
                    order.status != OrderStatus.dibatalkan) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(
                              Icons.check_circle_outline,
                              size: 18),
                          label: const Text('Selesaikan'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.ok,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _settle(
                              context,
                              ref,
                              dialogContext,
                              order),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (order.status ==
                          OrderStatus.menunggu)
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(
                                Icons.cancel_outlined,
                                size: 18),
                            label:
                                const Text('Batalkan'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  AppColors.danger,
                            ),
                            onPressed: () => _batal(
                                context,
                                ref,
                                dialogContext,
                                order),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Hapus pesanan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    onPressed: () => _hapus(
                        context, ref, dialogContext, order),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(Strings.tutup),
            ),
          ],
        ),
    );
  }

  Future<void> _hapus(BuildContext context, WidgetRef ref,
      BuildContext dialogContext, Order order) async {
    final belumSelesai = order.status != OrderStatus.selesai &&
        order.status != OrderStatus.dibatalkan;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus pesanan?'),
        content: Text(
          '${order.customerName} · ${formatRp(order.total)}\n'
          '${belumSelesai ? 'Pesanan belum selesai: stok & koin pelanggan dikembalikan dulu, baru pesanan dihapus. ' : ''}'
          'Pesanan yang dihapus tidak bisa dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(Strings.batal),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteOrder(order.id);
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan dihapus.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.butuhInternetAdmin)),
        );
      }
    }
  }

  Future<void> _settle(BuildContext context, WidgetRef ref,
      BuildContext dialogContext, Order order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesaikan pesanan?'),
        content: Text(
          '${order.customerName} · ${formatRp(order.total)}\n'
          'Pesanan ditandai selesai dan masuk Pembukuan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(Strings.batal),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Selesaikan',
                style: TextStyle(color: AppColors.ok)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminRepositoryProvider).settleOrder(order.id);
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pesanan selesai, masuk Pembukuan.')),
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

  Future<void> _batal(BuildContext context, WidgetRef ref,
      BuildContext dialogContext, Order order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: Text(
          '${order.customerName} · ${formatRp(order.total)}\n'
          'Stok dan koin dikembalikan ke pelanggan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(Strings.batal),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Batalkan',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminRepositoryProvider).cancelOrder(order.id);
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pesanan dibatalkan.')),
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
