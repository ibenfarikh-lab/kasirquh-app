import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_settings.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/guest_lock_sheet.dart';
import '../../../core/widgets/theme_picker.dart';
import '../../../data/models/order.dart';
import '../../../data/models/customer_note.dart';
import '../../../data/remote/auth_service.dart';
import '../../../data/repositories/customer_note_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../l10n/strings_id.dart';
import '../../gateway/gateway_screen.dart';
import '../session.dart';
import 'coin_history_page.dart';
import 'misi_koin_page.dart';

/// Tab Akun — bergembok untuk tamu.
/// Member: data akun + koin + riwayat pesanan + Keluar.
class AccountTab extends ConsumerWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).valueOrNull;
    if (session == null || session.isGuest) {
      // Seharusnya tak terlihat (gembok di navbar), tapi aman bila terjadi.
      return EmptyState(
        icon: Icons.lock_outline,
        title: Strings.guestLockTitle,
        hint: Strings.guestLockBody,
        actionLabel: Strings.masuk,
        onAction: () => requireLogin(context, ref, () async {}),
      );
    }
    final uid = session.user!.uid;
    final ordersAsync = ref.watch(_myOrdersProvider(uid));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 32,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName(session),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.email,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CoinHistoryPage(uid: uid),
              ),
            );
          },
          child: Row(
            children: [
              const Icon(Icons.monetization_on_outlined,
                  color: AppColors.orange),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  Strings.koinSaya,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${NumberFormat('#,###', 'id_ID').format(session.coins)} koin',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  color: AppColors.muted, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Tampilan: pemilih tema (Terang / Gelap / Ikuti HP).
        AppCard(
          onTap: () =>
              showThemePicker(context, temaPelangganProvider),
          child: Row(
            children: [
              const Icon(Icons.palette_outlined,
                  color: AppColors.orange),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tampilan',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                ref.watch(temaPelangganProvider).label,
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  color: AppColors.muted, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Catatan toko (kasbon digital): tagihan/catatan dari toko.
        _catatanTokoSection(context, ref, uid),
        const SizedBox(height: 12),
        // Misi koin: tantangan sederhana berhadiah koin.
        AppCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MisiKoinPage(),
              ),
            );
          },
          child: const Row(
            children: [
              Icon(Icons.emoji_events_outlined,
                  color: AppColors.orange),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Misi koin',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppColors.muted, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          Strings.pesananSaya,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ordersAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (_, __) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: Strings.gagalMuatPesanan,
            hint: Strings.periksaKoneksi,
            actionLabel: Strings.cobaLagi,
            onAction: () => ref.invalidate(_myOrdersProvider(uid)),
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: Strings.belumAdaPesanan,
              );
            }
            return Column(
              children: [
                for (final o in orders) _orderCard(context, o),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        AppButton(
          label: Strings.keluar,
          kind: AppButtonKind.danger,
          onPressed: () => _confirmLogout(context, ref),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            Strings.poweredBy,
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ),
      ],
    );
  }

  /// Section Catatan toko: daftar tagihan/catatan dari toko + sisa tagihan.
  /// Tanpa catatan → empty state jujur.
  Widget _catatanTokoSection(
      BuildContext context, WidgetRef ref, String uid) {
    final notesAsync = ref.watch(myCustomerNotesProvider(uid));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catatan toko',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        notesAsync.when(
          loading: () => const Center(
              child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )),
          error: (_, __) => const EmptyState(
            icon: Icons.note_outlined,
            title: 'Gagal memuat catatan toko',
            hint: Strings.periksaKoneksi,
          ),
          data: (notes) {
            if (notes.isEmpty) {
              return const EmptyState(
                icon: Icons.note_outlined,
                title: 'Belum ada catatan toko',
                hint:
                    'Tagihan atau catatan dari toko muncul di sini.',
              );
            }
            final tagihan = totalTagihan(notes);
            return Column(
              children: [
                AppCard(
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sisa tagihan',
                        style:
                            TextStyle(color: AppColors.muted),
                      ),
                      Text(
                        formatRp(tagihan),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: tagihan > 0
                              ? AppColors.danger
                              : AppColors.ok,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                for (final n in notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.note.isEmpty
                                      ? customerNoteTypeLabel(n.type)
                                      : n.note,
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  customerNoteTypeLabel(n.type),
                                  style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (n.amount > 0)
                            Text(
                              formatRp(n.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: n.type == 'tagihan'
                                    ? AppColors.danger
                                    : AppColors.ok,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _orderCard(BuildContext context, Order order) {
    final date = DateFormat('d MMM yyyy, HH:mm', 'id_ID')
        .format(order.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: () => _showDetail(context, order),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.items.fold(0, (s, e) => s + e.qty)} barang • ${formatRp(order.total)}',
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            _statusChip(order.status),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(OrderStatus s) {    final color = switch (s) {
      OrderStatus.menunggu => AppColors.orange,
      OrderStatus.dikemas || OrderStatus.dikirim => AppColors.orange,
      OrderStatus.selesai => AppColors.ok,
      OrderStatus.dibatalkan => AppColors.danger,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        orderStatusLabel(s).toUpperCase(),
        style: TextStyle(
            color: color, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }

  void _showDetail(BuildContext context, Order order) {
    final date = DateFormat('d MMM yyyy, HH:mm', 'id_ID')
        .format(order.createdAt);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      Strings.detailPesanan,
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                  _statusChip(order.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(date,
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 12),
              for (final it in order.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${it.qty}x ${it.name}'),
                      ),
                      Text(formatRp(it.price * it.qty),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              const Divider(),
              Row(
                children: [
                  const Expanded(
                    child: Text('Total',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Text(
                    formatRp(order.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(
      BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(Strings.keluar),
        content: const Text(Strings.yakinKeluar),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Strings.batal),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              Strings.keluar,
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(authServiceProvider)?.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const GatewayScreen()),
          (_) => false,
        );
      }
    }
  }
}

final _myOrdersProvider =
    StreamProvider.family<List<Order>, String>((ref, uid) {
  return ref.watch(orderRepositoryProvider).watchMyOrders(uid);
});
