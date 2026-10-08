import 'package:flutter/material.dart';
import '../admin_nav.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../l10n/strings_id.dart';
import '../menu/ledger_page.dart';
import '../menu/online_orders_page.dart';
import '../menu/products_page.dart';
import '../pos/pos_tab.dart';
import '../menu/chat_page.dart';
import '../inbox/inbox_tab.dart';
import '../menu/store_notes_sheet.dart';

/// Tab Beranda admin — desain menyamakan PWA/prototipe.
/// Ringkasan operasional + 3 kartu metrik seragam + shortcut + banner.
class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  @override
  void initState() {
    super.initState();
    _maybeRefreshTopProducts();
  }

  Future<void> _maybeRefreshTopProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt('topProductsRefreshedAt') ?? 0;
      final sehari = DateTime.now()
          .subtract(const Duration(hours: 24))
          .millisecondsSinceEpoch;
      if (last > sehari) return;
      await ref.read(adminRepositoryProvider).refreshTopProducts();
      await prefs.setInt('topProductsRefreshedAt',
          DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(_todaySummaryProvider);
    final orders = ref.watch(adminOrdersProvider).valueOrNull ?? const [];
    final waiting =
        orders.where((o) => o.status == OrderStatus.menunggu).length;
    final lowStock = ref.watch(lowStockProductsProvider);
    final store = ref.watch(storeInfoProvider).valueOrNull;
    final todayStr =
        DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(_todaySummaryProvider);
        ref.invalidate(adminOrdersProvider);
        ref.invalidate(adminJournalProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header: nama warung.
          Row(
            children: [
              const Icon(Icons.storefront_outlined,
                  color: AppColors.orange, size: 28),
              const SizedBox(width: 10),
              Text(
                store?.storeName ?? 'Warunge Mimi',
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Lead: Ringkasan operasional / Hari ini + tanggal.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan operasional',
                    style: TextStyle(
                        color: context.teksRedup, fontSize: 13),
                  ),
                  const Text(
                    'Hari ini',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Text(
                todayStr,
                style:
                    TextStyle(color: context.teksRedup, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 3 kartu metrik seragam.
          summaryAsync.when(
            loading: () => const Center(
                child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )),
            error: (_, __) => const EmptyState(
              icon: Icons.bar_chart_outlined,
              title: Strings.belumAdaData,
            ),
            data: (s) {
              final omzetValue =
                  s.transaksi == 0 ? null : formatRp(s.masuk);
              return Row(
                children: [
                  Expanded(
                    child: _UniformMetricCard(
                      label: 'OMZET HARI INI',
                      value: omzetValue ?? 'Belum ada data',
                      sub: s.transaksi == 0
                          ? 'Transaksi & laba · belum ada data'
                          : '${s.transaksi} transaksi',
                      isPrimary: true,
                      onTap: () =>
                          _open(context, const LedgerPage()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _UniformMetricCard(
                      label: 'PESANAN MENUNGGU',
                      value: waiting == 0 ? '0' : '$waiting',
                      sub: 'Buka Kasir Online',
                      onTap: () =>
                          _open(context, const OnlineOrdersPage()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _UniformMetricCard(
                      label: 'STOK KRITIS',
                      value: lowStock.isEmpty
                          ? '0'
                          : '${lowStock.length}',
                      sub: 'Buka Produk',
                      onTap: () =>
                          _open(context, const ProductsPage()),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          // Buka pekerjaan utama + Ubah.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Buka pekerjaan utama',
                style: TextStyle(
                  color: context.teksUtama,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  // TODO: mode ubah susunan shortcut.
                },
                style: OutlinedButton.styleFrom(
                  side:
                      const BorderSide(color: AppColors.orange),
                  foregroundColor: AppColors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Ubah'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 6 shortcut.
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.15,
            children: [
              _ShortcutTile(
                icon: Icons.receipt_long_outlined,
                label: 'Buka Kasir',
                onTap: () => _open(context, const PosTab()),
              ),
              _ShortcutTile(
                icon: Icons.inbox_outlined,
                label: 'Cek Inbox',
                onTap: () => _open(context, const InboxTab()),
              ),
              _ShortcutTile(
                icon: Icons.book_outlined,
                label: 'Pembukuan',
                onTap: () => _open(context, const LedgerPage()),
              ),
              _ShortcutTile(
                icon: Icons.shopping_bag_outlined,
                label: 'Kasir Online',
                onTap: () =>
                    _open(context, const OnlineOrdersPage()),
              ),
              _ShortcutTile(
                icon: Icons.chat_bubble_outline,
                label: 'Chat & Rumpi',
                onTap: () => _open(context, const ChatPage()),
              ),
              _ShortcutTile(
                icon: Icons.note_outlined,
                label: 'Catatan Belanja',
                onTap: () =>
                    _open(context, const StoreNotesSheet()),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Banner peringatan.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.permukaanKartu,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_outlined,
                    color: AppColors.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    waiting == 0 && lowStock.isEmpty
                        ? 'Operasional warung siap diperiksa.'
                        : '$waiting pesanan menunggu dan '
                            '${lowStock.length} stok kritis perlu perhatian.',
                    style: TextStyle(
                        color: context.teksUtama, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    openAdminPage(context, page);
  }
}

/// Kartu metrik seragam — 3 kolom sejajar.
class _UniformMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final bool isPrimary;
  final VoidCallback onTap;

  const _UniformMetricCard({
    required this.label,
    required this.value,
    required this.sub,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isPrimary ? AppColors.orange : context.permukaanKartu;
    final muted = isPrimary ? Colors.black54 : context.teksRedup;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(color: context.garis),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                  color: muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: isPrimary ? Colors.black87 : AppColors.orange,
                fontSize: value.length > 10 ? 14 : 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(color: muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile shortcut 3 kolom.
class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: context.permukaanKartu,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.garis),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.orange, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.teksUtama, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

final _todaySummaryProvider = FutureProvider<JournalSummary>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, now.day);
  return repo.journalSummary(from: from);
});
