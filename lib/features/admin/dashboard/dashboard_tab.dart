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
  /// Mode ubah susunan shortcut.
  bool _isEditing = false;

  /// ID shortcut yang tampil (tersimpan di SharedPreferences).
  List<String> _shortcutIds = [
    'kasir',
    'inbox',
    'pembukuan',
    'kasir_online',
    'chat',
    'catatan_belanja',
  ];

  /// Definisi semua shortcut yang tersedia.
  static const _allShortcuts = <String, Map<String, dynamic>>{
    'kasir': {'icon': Icons.receipt_long_outlined, 'label': 'Buka Kasir'},
    'inbox': {'icon': Icons.inbox_outlined, 'label': 'Cek Inbox'},
    'pembukuan': {'icon': Icons.book_outlined, 'label': 'Pembukuan'},
    'kasir_online': {
      'icon': Icons.shopping_bag_outlined,
      'label': 'Kasir Online'
    },
    'chat': {'icon': Icons.chat_bubble_outline, 'label': 'Chat & Rumpi'},
    'catatan_belanja': {'icon': Icons.note_outlined, 'label': 'Catatan Belanja'},
    'produk': {'icon': Icons.inventory_2_outlined, 'label': 'Data Produk'},
    'laporan': {'icon': Icons.bar_chart_outlined, 'label': 'Laporan'},
  };

  @override
  void initState() {
    super.initState();
    _maybeRefreshTopProducts();
    _loadShortcuts();
  }

  Future<void> _loadShortcuts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('dashboard_shortcuts');
      if (saved != null && saved.isNotEmpty && mounted) {
        setState(() {
          _shortcutIds = saved
              .where((id) => _allShortcuts.containsKey(id))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _saveShortcuts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('dashboard_shortcuts', _shortcutIds);
    } catch (_) {}
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
              // Layout ala PWA: OMZET besar kiri (span 2 baris),
              // PESANAN + STOK kecil numpuk kanan (sama tinggi).
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Expanded(
                    flex: 115,
                    child: _PwaMetricCard(
                      label: 'OMZET HARI INI',
                      value: omzetValue ?? 'Belum ada data',
                      sub: s.transaksi == 0
                          ? 'Transaksi & laba · belum ada data'
                          : '${s.transaksi} transaksi',
                      isPrimary: true,
                      tall: true,
                      onTap: () =>
                          _open(context, const LedgerPage()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 85,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _PwaMetricCard(
                            label: 'PESANAN MENUNGGU',
                            value:
                                waiting == 0 ? '0' : '$waiting',
                            sub: 'Buka Kasir Online',
                            onTap: () => _open(
                                context, const OnlineOrdersPage()),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _PwaMetricCard(
                            label: 'STOK KRITIS',
                            value: lowStock.isEmpty
                                ? '0'
                                : '${lowStock.length}',
                            sub: 'Buka Produk',
                            onTap: () => _open(
                                context, const ProductsPage()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Buka pekerjaan utama + Ubah/Selesai.
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
                  setState(() => _isEditing = !_isEditing);
                  if (!_isEditing) _saveShortcuts();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.orange),
                  foregroundColor: AppColors.orange,
                  backgroundColor: _isEditing
                      ? AppColors.orange
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _isEditing ? 'Selesai' : 'Ubah',
                  style: TextStyle(
                    color: _isEditing
                        ? Colors.black87
                        : AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Shortcut grid (dinamis + mode edit).
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.15,
            children: [
              for (final id in _shortcutIds)
                _ShortcutTile(
                  icon: _allShortcuts[id]!['icon'] as IconData,
                  label: _allShortcuts[id]!['label'] as String,
                  isEditing: _isEditing,
                  onRemove: () {
                    setState(() => _shortcutIds.remove(id));
                    _saveShortcuts();
                  },
                  onTap: () => _openShortcut(context, id),
                ),
              // Tile tambah (hanya saat edit).
              if (_isEditing)
                _AddShortcutTile(
                  onTap: () => _showShortcutPicker(context),
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

  /// Buka halaman sesuai ID shortcut.
  void _openShortcut(BuildContext context, String id) {
    switch (id) {
      case 'kasir':
        _open(context, const PosTab());
        break;
      case 'inbox':
        _open(context, const InboxTab());
        break;
      case 'pembukuan':
        _open(context, const LedgerPage());
        break;
      case 'kasir_online':
        _open(context, const OnlineOrdersPage());
        break;
      case 'chat':
        _open(context, const ChatPage());
        break;
      case 'catatan_belanja':
        _open(context, const StoreNotesSheet());
        break;
      case 'produk':
        _open(context, const ProductsPage());
        break;
      case 'laporan':
        _open(context, const LedgerPage());
        break;
    }
  }

  /// Dialog pilih shortcut untuk ditambah.
  Future<void> _showShortcutPicker(BuildContext context) async {
    final available = _allShortcuts.keys
        .where((id) => !_shortcutIds.contains(id))
        .toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Semua shortcut sudah ditampilkan')),
      );
      return;
    }
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Tambah shortcut'),
        children: [
          for (final id in available)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(id),
              child: Row(
                children: [
                  Icon(
                    _allShortcuts[id]!['icon'] as IconData,
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 12),
                  Text(_allShortcuts[id]!['label'] as String),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected != null && mounted) {
      setState(() => _shortcutIds.add(selected));
      _saveShortcuts();
    }
  }
}

/// Kartu metrik ala PWA — OMZET besar (tall), lainnya kecil.
class _PwaMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final bool isPrimary;
  final bool tall;
  final VoidCallback onTap;

  const _PwaMetricCard({
    required this.label,
    required this.value,
    required this.sub,
    this.isPrimary = false,
    this.tall = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isPrimary ? AppColors.orange : context.permukaanKartu;
    final muted = isPrimary ? Colors.black54 : context.teksRedup;
    // Kartu tall (OMZET) punya min-height agar span 2 baris.
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: tall ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment:
          tall ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: muted, fontSize: 9, fontWeight: FontWeight.w700),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: tall ? 16 : 6),
          child: Text(
            value,
            maxLines: tall ? 3 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isPrimary ? Colors.black87 : AppColors.orange,
              fontSize: isPrimary ? 20 : 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          sub,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: muted, fontSize: 10),
        ),
      ],
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border:
              isPrimary ? null : Border.all(color: context.garis),
        ),
        child: cardContent,
      ),
    );
  }
}

/// Tile shortcut 3 kolom — dukung mode edit (tombol hapus).
class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isEditing;
  final VoidCallback? onRemove;

  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isEditing = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEditing ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: context.permukaanKartu,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.garis,
            style: isEditing
                ? BorderStyle.solid
                : BorderStyle.solid,
          ),
        ),
        child: Stack(
          children: [
            Center(
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
            if (isEditing && onRemove != null)
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tile tambah shortcut (mode edit).
class _AddShortcutTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddShortcutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.orange,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.orange, size: 28),
            SizedBox(height: 4),
            Text(
              'Tambah',
              style:
                  TextStyle(color: AppColors.orange, fontSize: 12),
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
