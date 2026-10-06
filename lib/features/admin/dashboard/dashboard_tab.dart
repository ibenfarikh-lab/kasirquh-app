import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../l10n/strings_id.dart';
import '../menu/ledger_page.dart';
import '../menu/online_orders_page.dart';
import '../menu/products_page.dart';

/// Tab Beranda admin: metrik harian + deep link.
/// Jujur: belum ada data → "Belum ada data", bukan angka 0.
class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  /// Agregat "Sedang laris" dihitung ulang maks. 1x sehari saat Beranda
  /// dibuka — pelanggan hanya membaca hasilnya dari store_settings.
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
    } catch (_) {
      // Gagal (offline) → agregat lama tetap dipakai, coba lagi besok.
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(_todaySummaryProvider);
    final orders = ref.watch(adminOrdersProvider).valueOrNull ?? const [];
    final waiting =
        orders.where((o) => o.status == OrderStatus.menunggu).length;
    final lowStock = ref.watch(lowStockProductsProvider);
    final store = ref.watch(storeInfoProvider).valueOrNull;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(_todaySummaryProvider);
        ref.invalidate(adminOrdersProvider);
        ref.invalidate(adminJournalProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _greeting(store?.storeName),
          const SizedBox(height: 16),
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
            data: (s) => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _MetricCard(
                  icon: Icons.payments_outlined,
                  label: Strings.omzetHariIni,
                  value: s.transaksi == 0 ? null : formatRp(s.masuk),
                  onTap: () => _open(context, const LedgerPage()),
                ),
                _MetricCard(
                  icon: Icons.receipt_long_outlined,
                  label: Strings.transaksiHariIni,
                  value:
                      s.transaksi == 0 ? null : '${s.transaksi} transaksi',
                  onTap: () => _open(context, const LedgerPage()),
                ),
                _MetricCard(
                  icon: Icons.inbox_outlined,
                  label: Strings.pesananMenunggu,
                  value: waiting == 0 ? null : '$waiting pesanan',
                  badge: waiting,
                  onTap: () => _open(context, const OnlineOrdersPage()),
                ),
                _MetricCard(
                  icon: Icons.inventory_2_outlined,
                  label: Strings.stokMenipisJudul,
                  value:
                      lowStock.isEmpty ? null : '${lowStock.length} produk',
                  badge: lowStock.length,
                  onTap: () => _open(context, const ProductsPage()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _QuickTips(),
        ],
      ),
    );
  }

  Widget _greeting(String? storeName) {
    final hour = DateTime.now().hour;
    final sapaan =
        hour < 11 ? 'Selamat pagi' : hour < 15 ? 'Selamat siang' : 'Selamat sore';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sapaan,
          style: const TextStyle(color: AppColors.warmMuted, fontSize: 14),
        ),
        Text(
          storeName ?? Strings.appName,
          style: const TextStyle(
            color: AppColors.warmText,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

final _todaySummaryProvider = FutureProvider<JournalSummary>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, now.day);
  return repo.journalSummary(from: from);
});

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value; // null = belum ada data (jujur)
  final int badge;
  final VoidCallback onTap;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.orange, size: 22),
              const Spacer(),
              if (badge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value ?? Strings.belumAdaData,
            style: TextStyle(
              color: value == null
                  ? AppColors.warmMuted
                  : AppColors.warmText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.warmMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _QuickTips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline,
              color: AppColors.orange2),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mulai dari ${Strings.tabKasir} untuk jualan, '
              '${Strings.tabInbox} untuk pesanan & pendaftar.',
              style: const TextStyle(
                  color: AppColors.warmMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
