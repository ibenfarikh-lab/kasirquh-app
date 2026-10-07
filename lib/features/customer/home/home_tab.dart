import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/guest_lock_sheet.dart';
import '../../../core/widgets/product_photo.dart';
import '../../../data/models/order.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/home_stock_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/product_repository.dart';

import '../../../data/repositories/store_repository.dart';
import '../../../l10n/strings_id.dart';
import '../account/coin_history_page.dart';
import '../catalog/catalog_tab.dart';
import '../customer_shell.dart';
import '../session.dart';

/// Tab Beranda — 8 section ala prototipe v3 (urutan dikunci):
/// 1. Paket Tanggal Muda (diatur warung)
/// 2. Koin Warga (kartu saldo)
/// 3. Belanjaan siap diantar (banner pesanan aktif)
/// 4. Belanja dapur lebih ringan (promo pilihan toko)
/// 5. Layanan warga (titip belanja dkk.)
/// 6. Stok rumah habis? (catatan lokal)
/// 7. Ide masak warga (empty state jujur bila belum ada)
/// 8. Sedang laris (agregat pesanan)
/// Section tanpa data → disembunyikan atau empty state jujur.
/// Tanpa angka/data siluman.
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeInfoProvider).valueOrNull ?? const StoreInfo();
    final session = ref.watch(sessionProvider).valueOrNull;
    final promos = ref.watch(promosProvider).valueOrNull ?? const <Promo>[];
    final products =
        ref.watch(productsProvider).valueOrNull ?? const <Product>[];
    final uid = memberUid(session ?? const Session.guest());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _paketSection(store),
        _koinCard(context, ref, session),
        _pesananAktifSection(context, ref, uid),
        _promoPilihanSection(context, ref, promos, products),
        _layananSection(context, ref, uid),
        _stokRumahSection(context, ref),
        _ideMasakSection(),
        _larisSection(context, ref, store, products),
        const SizedBox(height: 24),
        Center(
          child: Text(
            Strings.poweredBy,
            style: TextStyle(color: context.teksRedup, fontSize: 11),
          ),
        ),
      ],
    );
  }

  // ---------- 1. Paket Tanggal Muda (diatur warung) ----------
  Widget _paketSection(StoreInfo store) {
    if (!store.paketEnabled || (store.paketTitle ?? '').trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // Aturan 2: oranye tunggal solid, bukan gradient.
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DIATUR WARUNG',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                store.paketTitle!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if ((store.paketSubtitle ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  store.paketSubtitle!,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------- 2. Kartu Koin Warga ----------
  Widget _koinCard(
      BuildContext context, WidgetRef ref, Session? session) {
    final member = (session != null && !session.isGuest) ? session : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        onTap: () {
          if (member == null) {
            requireLogin(context, ref, () async {});
            return;
          }
          final uid = memberUid(member);
          if (uid == null) return;
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => CoinHistoryPage(uid: uid)),
          );
        },
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.monetization_on_outlined,
                color: AppColors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Koin Warga',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member == null
                        ? 'Masuk untuk kumpulkan koin.'
                        : '${member.coins} koin · tukarkan saat checkout',
                    style: TextStyle(
                        color: context.teksRedup, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.teksRedup),
          ],
        ),
      ),
    );
  }

  // ---------- 3. Belanjaan siap diantar ----------
  Widget _pesananAktifSection(
      BuildContext context, WidgetRef ref, String? uid) {
    if (uid == null) return const SizedBox.shrink();
    final ordersAsync = ref.watch(_myOrdersProvider(uid));
    return ordersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (orders) {
        final aktif = orders
            .where((o) =>
                o.status == OrderStatus.menunggu ||
                o.status == OrderStatus.dikemas ||
                o.status == OrderStatus.dikirim)
            .toList();
        if (aktif.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                kicker: 'TETAP NYAMAN DI RUMAH',
                title: 'Belanjaan siap diantar',
              ),
              const SizedBox(height: 8),
              for (final o in aktif.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    // Ketuk → Tab Akun (daftar Pesanan Saya).
                    onTap: () => ref
                        .read(customerTabProvider.notifier)
                        .state = 4,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_shipping_outlined,
                          color: AppColors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                o.code,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${orderStatusLabel(o.status)} · ${formatRp(o.total)}',
                                style: TextStyle(
                                    color: context.teksRedup,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: context.teksRedup),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ---------- 4. Belanja dapur lebih ringan ----------
  Widget _promoPilihanSection(BuildContext context, WidgetRef ref,
      List<Promo> promos, List<Product> products) {
    // Promo yang menunjuk ke produk tertentu = pilihan toko.
    final pilihan = promos.where((p) => p.productId != null).toList();
    if (pilihan.isEmpty) return const SizedBox.shrink();
    final byId = {for (final p in products) p.id: p};
    final cards = <Widget>[];
    for (final promo in pilihan.take(6)) {
      final prod = byId[promo.productId];
      if (prod == null) continue;
      cards.add(_HomeProductCard(product: prod));
    }
    if (cards.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            kicker: 'PILIHAN TOKO',
            title: 'Belanja dapur lebih ringan',
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 12),
              itemBuilder: (_, i) => cards[i],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- 5. Layanan warga ----------
  Widget _layananSection(
      BuildContext context, WidgetRef ref, String? uid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            kicker: 'FITUR BELANJA KHAS WARUNG',
            title: 'Layanan warga',
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.05,
            children: [
              _serviceCard(
                context,
                icon: Icons.inventory_2_outlined,
                label: 'Titip belanja',
                hint: 'Dicari saat kulakan',
                featured: true,
                onTap: () => _titipSheet(context, ref, uid),
              ),
              _serviceCard(
                context,
                icon: Icons.account_balance_wallet_outlined,
                label: 'Mode anggaran',
                hint: 'Belanja sesuai uangmu',
                onTap: () => _layananInfoSheet(
                  context,
                  ref,
                  judul: 'Mode anggaran',
                  isi: 'Atur batas belanja bulananmu, lalu pantau '
                      'total keranjang agar tidak kebablasan.\n\n'
                      'Layanan ini masih disiapkan — tanya dulu ke toko '
                      'via chat ya.',
                ),
              ),
              _serviceCard(
                context,
                icon: Icons.group_outlined,
                label: 'Patungan',
                hint: 'Grosir bareng warga',
                onTap: () => _layananInfoSheet(
                  context,
                  ref,
                  judul: 'Patungan',
                  isi: 'Beli grosir bareng warga lain biar dapat harga '
                      'lebih miring.\n\n'
                      'Layanan ini masih disiapkan — tanya dulu ke toko '
                      'via chat ya.',
                ),
              ),
              _serviceCard(
                context,
                icon: Icons.qr_code_outlined,
                label: 'Harga grosir',
                hint: 'Otomatis per dus',
                onTap: () => _layananInfoSheet(
                  context,
                  ref,
                  judul: 'Harga grosir',
                  isi: 'Beli per dus langsung dapat harga grosir, '
                      'otomatis di keranjang.\n\n'
                      'Layanan ini masih disiapkan — tanya dulu ke toko '
                      'via chat ya.',
                ),
              ),
              _serviceCard(
                context,
                icon: Icons.refresh_outlined,
                label: 'Belanja rutin',
                hint: 'Paket mingguan',
                onTap: () => _layananInfoSheet(
                  context,
                  ref,
                  judul: 'Belanja rutin',
                  isi: 'Daftar belanja mingguan yang bisa dipesan ulang '
                      'sekali ketuk.\n\n'
                      'Layanan ini masih disiapkan — tanya dulu ke toko '
                      'via chat ya.',
                ),
              ),
              _serviceCard(
                context,
                icon: Icons.celebration_outlined,
                label: 'Paket hajatan',
                hint: 'Siap untuk acara',
                onTap: () => _layananInfoSheet(
                  context,
                  ref,
                  judul: 'Paket hajatan',
                  isi: 'Paket sembako siap saji untuk hajatan dan acara '
                      'keluarga.\n\n'
                      'Layanan ini masih disiapkan — tanya dulu ke toko '
                      'via chat ya.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String hint,
    required VoidCallback onTap,
    bool featured = false,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            // warmText (putih) hilang di kartu terang — ngikutin tema.
            color: featured
                ? AppColors.orange
                : (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.warmText
                    : AppColors.ink),
            size: 26,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            textAlign: TextAlign.center,
            style:
                TextStyle(color: context.teksRedup, fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// Titip belanja terstruktur (Domain B): form barang + catatan + metode
  /// → tulis ke `titip_requests`. Titip via pesan Chat Toko DICABUT.
  Future<void> _titipSheet(
      BuildContext context, WidgetRef ref, String? uid) async {
    if (uid == null) {
      await requireLogin(context, ref, () async {});
      return;
    }
    final session = ref.read(sessionProvider).valueOrNull;
    final nama = session == null ? 'Pelanggan' : displayName(session);
    if (!context.mounted) return;
    final itemCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var method = 'Ambil di warung';
    var busy = false;
    String? error;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom:
                  MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Titip belanja',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Barang yang belum ada di rak akan dicari saat '
                  'warung kulakan. Pilih ambil sendiri atau minta '
                  'diantar setelah barang tersedia.',
                  style: TextStyle(
                      color: context.teksRedup, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: itemCtrl,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Barang yang dicari',
                    hintText: 'Contoh: susu bayi ukuran 400 g',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  maxLength: 300,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Rincian atau merek',
                    hintText:
                        'Tulis ukuran, merek pilihan, dan jumlah',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final m in [
                      'Ambil di warung',
                      'Diantar ke rumah'
                    ])
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: m == 'Ambil di warung' ? 8 : 0),
                          child: ChoiceChip(
                            label: Text(m),
                            selected: method == m,
                            onSelected: (_) =>
                                setState(() => method = m),
                          ),
                        ),
                      ),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 13)),
                ],
                const SizedBox(height: 16),
                AppButton(
                  label: busy ? 'Mengirim...' : 'Kirim titipan',
                  fullWidth: true,
                  onPressed: busy
                      ? null
                      : () async {
                          final barang = itemCtrl.text.trim();
                          if (barang.isEmpty) {
                            setState(() => error =
                                'Tulis barang yang ingin dititipkan.');
                            return;
                          }
                          setState(() {
                            busy = true;
                            error = null;
                          });
                          try {
                            await ref
                                .read(orderRepositoryProvider)
                                .submitTitipRequest(
                                  customerId: uid,
                                  customerName: nama,
                                  item: barang,
                                  note: noteCtrl.text,
                                  method: method,
                                );
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Terkirim · warung akan memberi kabar'),
                                  ),
                                );
                            }
                          } catch (_) {
                            if (ctx.mounted) {
                              setState(() {
                                busy = false;
                                error =
                                    'Gagal mengirim. Periksa koneksi lalu coba lagi.';
                              });
                            }
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    itemCtrl.dispose();
    noteCtrl.dispose();
  }


  /// Layanan yang masih disiapkan: info jujur + pintu Chat Toko.
  Future<void> _layananInfoSheet(BuildContext context, WidgetRef ref,
      {required String judul, required String isi}) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                judul,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(isi,
                  style: TextStyle(
                      color: context.teksRedup, fontSize: 14)),
              const SizedBox(height: 16),
              AppButton(
                label: 'Chat Toko',
                fullWidth: true,
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final ok = await requireLogin(context, ref, () async {});
                  if (ok && context.mounted) {
                    ref.read(customerTabProvider.notifier).state = 3;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- 6. Stok rumah habis? ----------
  Widget _stokRumahSection(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(homeStockProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  kicker: 'DARI RIWAYAT BELANJAMU',
                  title: 'Stok rumah habis?',
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Catat'),
                onPressed: () => _tambahStokRumah(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 8),
          stockAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) {
              if (items.isEmpty) {
                return AppCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.kitchen_outlined,
                        color: context.teksRedup,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Belum ada catatan. Catat barang yang habis '
                          'di rumah biar tidak lupa saat belanja.',
                          style: TextStyle(
                              color: context.teksRedup, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  for (final item in items.take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    homeStockLabel(item.status),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: item.status == 'habis'
                                          ? AppColors.danger
                                          : AppColors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await ref
                                    .read(homeStockRepositoryProvider)
                                    .remove(item.id);
                                ref.invalidate(homeStockProvider);
                              },
                              child: const Text('Sudah beli'),
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
      ),
    );
  }

  Future<void> _tambahStokRumah(
      BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    var status = 'habis';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom:
                  MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catat stok rumah',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama barang',
                    hintText: 'Mis. "Minyak goreng"',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Habis'),
                      selected: status == 'habis',
                      onSelected: (_) =>
                          setState(() => status = 'habis'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Menipis'),
                      selected: status == 'menipis',
                      onSelected: (_) =>
                          setState(() => status = 'menipis'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Simpan',
                  fullWidth: true,
                  onPressed: () async {
                    final nama = ctrl.text.trim();
                    if (nama.isEmpty) return;
                    await ref
                        .read(homeStockRepositoryProvider)
                        .add(nama, status);
                    ref.invalidate(homeStockProvider);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    ctrl.dispose();
  }

  // ---------- 7. Ide masak warga ----------
  Widget _ideMasakSection() {
    // Belum ada modul resep di aplikasi — empty state jujur.
    return const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            kicker: 'DARI DAPUR TETANGGA',
            title: 'Ide masak warga',
          ),
          SizedBox(height: 8),
          EmptyState(
            icon: Icons.soup_kitchen_outlined,
            title: 'Belum ada ide masak',
            hint: 'Fitur resep warga masih disiapkan.',
          ),
        ],
      ),
    );
  }

  // ---------- 8. Sedang laris ----------
  Widget _larisSection(BuildContext context, WidgetRef ref,
      StoreInfo store, List<Product> products) {
    final ids = store.topProductIds;
    if (ids.isEmpty) return const SizedBox.shrink();
    final byId = {for (final p in products) p.id: p};
    final cards = <Widget>[];
    for (final id in ids) {
      final prod = byId[id];
      if (prod == null) continue;
      cards.add(_HomeProductCard(product: prod));
    }
    if (cards.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            kicker: 'DARI TRANSAKSI SELURUH PELANGGAN',
            title: 'Sedang laris',
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 12),
              itemBuilder: (_, i) => cards[i],
            ),
          ),
        ],
      ),
    );
  }
}

/// Judul section ala prototipe: kicker kecil + judul tebal.
class _SectionTitle extends StatelessWidget {
  final String kicker;
  final String title;

  const _SectionTitle({required this.kicker, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kicker,
          style: TextStyle(
            color: context.teksRedup,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

/// Kartu produk horizontal untuk section Beranda.
class _HomeProductCard extends ConsumerWidget {
  final Product product;

  const _HomeProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promos = ref.watch(promosProvider).valueOrNull ?? const <Promo>[];
    final harga = hargaJualAktif(product, promos);
    return SizedBox(
      width: 140,
      child: AppCard(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (_) => ProductDetailSheet(product: product),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ProductPhoto(
                photoPath: product.photoPath,
                size: 84,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              formatRp(harga),
              style: const TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pesanan saya (member) — dipakai banner "Belanjaan siap diantar".
final _myOrdersProvider =
    StreamProvider.family<List<Order>, String>((ref, uid) {
  return ref.watch(orderRepositoryProvider).watchMyOrders(uid);
});

/// Filter katalog yang diminta dari Beranda (kategori cepat / pencarian).
class CatalogFilter {
  final String query;
  final String category;
  const CatalogFilter({this.query = '', this.category = ''});
}

final catalogFilterProvider =
    StateProvider<CatalogFilter>((ref) => const CatalogFilter());
