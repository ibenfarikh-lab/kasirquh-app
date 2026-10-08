import 'dart:async';

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
import '../cart/cart_provider.dart';
import '../catalog/catalog_tab.dart';
import '../customer_shell.dart';
import '../session.dart';

/// Tab Beranda — 10 section ala PWA (urutan dikunci):
/// 1. Paket Tanggal Muda (diatur warung)
/// 2. Koin Warga (kartu saldo)
/// 3. Belanjaan siap diantar (banner pesanan aktif)
/// 4. Belanja dapur lebih ringan (promo pilihan toko)
/// 5. Kabar Warung (carousel status warung)
/// 6. Promo Kilat (flash sale + countdown)
/// 7. Layanan warga (titip belanja dkk.)
/// 8. Stok rumah habis? (catatan lokal)
/// 9. Ide masak warga (empty state jujur bila belum ada)
/// 10. Sedang laris (agregat pesanan)
/// Section tanpa data → disembunyikan atau empty state jujur.
/// Tanpa angka/data siluman.
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeAsync = ref.watch(storeInfoProvider);
    if (storeAsync.hasError) {
      // ignore: avoid_print
      print('[home_tab] Gagal muat storeInfo: ${storeAsync.error}');
    }
    final store = storeAsync.valueOrNull ?? const StoreInfo();
    final session = ref.watch(sessionProvider).valueOrNull;
    final promosAsync = ref.watch(promosProvider);
    if (promosAsync.hasError) {
      // ignore: avoid_print
      print('[home_tab] Gagal muat promos: ${promosAsync.error}');
    }
    final promos = promosAsync.valueOrNull ?? const <Promo>[];
    // Anti-gagal-diam-diam: error produk ditampilkan eksplisit (bukan kosong).
    final productsAsync = ref.watch(productsProvider);
    final products = productsAsync.valueOrNull ?? const <Product>[];
    final uid = memberUid(session ?? const Session.guest());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (productsAsync.hasError)
          _ErrorBanner(
            title: Strings.gagalMuatProduk,
            hint: Strings.periksaKoneksi,
            onRetry: () => ref.invalidate(productsProvider),
          ),
        _paketSection(store),
        _koinCard(context, ref, session),
        _pesananAktifSection(context, ref, uid),
        _promoPilihanSection(context, ref, promos, products),
        _kabarWarungSection(store),
        _promoKilatSection(context, ref, promos, products),
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

  // ---------- Kabar Warung (carousel ala PWA) ----------
  // Urutan PWA: setelah promo carousel, sebelum layanan warga.
  // Slide 1: status operasional warung (live dot + buka/tutup).
  // Slide 2: saran suasana berdasarkan jam.
  Widget _kabarWarungSection(StoreInfo store) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _KabarCarousel(store: store),
    );
  }

  // ---------- 6. Promo Kilat (flash sale ala PWA) ----------
  // Urutan PWA: setelah Kabar Warung, sebelum Layanan Warga.
  // Sumber: Promo discountType 'flash' + productId (koleksi promos).
  // Tanpa promo kilat aktif → disembunyikan (seperti PWA).
  Widget _promoKilatSection(BuildContext context, WidgetRef ref,
      List<Promo> promos, List<Product> products) {
    Promo? flash;
    for (final p in promos) {
      if (p.isActive &&
          p.discountType == 'flash' &&
          (p.productId ?? '').isNotEmpty) {
        flash = p;
        break;
      }
    }
    if (flash == null) return const SizedBox.shrink();
    Product? product;
    for (final p in products) {
      if (p.id == flash.productId) {
        product = p;
        break;
      }
    }
    if (product == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _PromoKilatCard(promo: flash, product: product),
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

/// Kartu Promo Kilat ala PWA: countdown live + harga coret + tombol Ambil.
/// Harga promo dikunci saat masuk keranjang (seperti PWA).
class _PromoKilatCard extends ConsumerStatefulWidget {
  final Promo promo;
  final Product product;

  const _PromoKilatCard({required this.promo, required this.product});

  @override
  ConsumerState<_PromoKilatCard> createState() => _PromoKilatCardState();
}

class _PromoKilatCardState extends ConsumerState<_PromoKilatCard> {
  Timer? _timer;
  late DateTime _endsAt;

  DateTime _defaultEnd() {
    final now = DateTime.now();
    // PWA: default akhir hari bila flashEndsAt tidak diatur.
    return DateTime(now.year, now.month, now.day, 24);
  }

  @override
  void initState() {
    super.initState();
    _endsAt = widget.promo.endsAt ?? _defaultEnd();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _PromoKilatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.promo.endsAt != oldWidget.promo.endsAt) {
      _endsAt = widget.promo.endsAt ?? _defaultEnd();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdown {
    final s = _endsAt.difference(DateTime.now()).inSeconds.clamp(0, 359999);
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final promo = widget.promo;
    final hargaPromo = promo.hargaPromo(product.price);
    final adaDiskon = hargaPromo < product.price;
    final habis = product.stock <= 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'PROMO KILAT · BERAKHIR DALAM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.04,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _countdown,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${product.name} cuma ${formatRp(hargaPromo)}',
                  style: TextStyle(
                    color: context.teksUtama,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (adaDiskon)
                      Text(
                        formatRp(product.price),
                        style: TextStyle(
                          color: context.teksRedup,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    if (adaDiskon) const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        promo.subtitle?.trim().isNotEmpty == true
                            ? promo.subtitle!.trim()
                            : 'Selama persediaan masih ada.',
                        style: TextStyle(
                            color: context.teksRedup, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: habis
                ? null
                : () {
                    final ok = ref
                        .read(cartProvider.notifier)
                        .add(product, harga: hargaPromo);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? 'Harga promo kilat aktif di keranjang'
                            : 'Stok habis'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
            child: const Text(
              '+ Ambil',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
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

/// Banner error inline — anti-gagal-diam-diam.
/// Tampil saat stream data gagal, dengan tombol coba lagi.
class _ErrorBanner extends StatelessWidget {
  final String title;
  final String hint;
  final VoidCallback onRetry;
  const _ErrorBanner({
    required this.title,
    required this.hint,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.danger.withValues(alpha: 0.1),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.danger),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: context.teksUtama,
                          fontWeight: FontWeight.w700)),
                  Text(hint,
                      style: TextStyle(
                          color: context.teksRedup, fontSize: 12)),
                ],
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}

/// Carousel "Kabar Warung" ala PWA.
///
/// Slide 1: status operasional warung (live dot hijau/abu + buka/tutup).
/// Slide 2: saran suasana berdasarkan jam (pagi/siang/sore/malam).
/// Auto-rotasi tiap 5,6 detik; jeda 8,5 detik setelah interaksi manual.
class _KabarCarousel extends StatefulWidget {
  final StoreInfo store;

  const _KabarCarousel({required this.store});

  @override
  State<_KabarCarousel> createState() => _KabarCarouselState();
}

class _KabarCarouselState extends State<_KabarCarousel> {
  static const _autoMs = 5600;
  static const _resumeMs = 8500;

  late final PageController _controller;
  Timer? _autoTimer;
  Timer? _resumeTimer;
  int _page = 0;
  bool _programmatic = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startAuto();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _resumeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAuto() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(
      const Duration(milliseconds: _autoMs),
      (_) {
        if (!mounted) return;
        _programmatic = true;
        _controller.animateToPage(
          (_page + 1) % 2,
          duration: const Duration(milliseconds: 380),
          curve: Curves.ease,
        );
      },
    );
  }

  void _pauseAuto() {
    _autoTimer?.cancel();
    _resumeTimer?.cancel();
    _resumeTimer = Timer(
      const Duration(milliseconds: _resumeMs),
      () {
        if (mounted) _startAuto();
      },
    );
  }

  void _goTo(int index) {
    _programmatic = true;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.ease,
    );
    _pauseAuto();
  }

  /// Status buka/tutup — PWA default "buka" bila jam tak bisa dihitung.
  bool get _open => widget.store.isOpenNow ?? true;

  String get _statusTitle =>
      _open ? 'Buka sekarang' : 'Warung sedang tutup';

  String get _statusDetail => _open
      ? 'Tutup ${widget.store.closeHour} · Belum ada pesanan disiapkan'
      : 'Buka lagi pukul ${widget.store.openHour} · '
          'pesanan bisa disiapkan nanti';

  /// Saran suasana berdasarkan jam — logika persis PWA (renderKabar).
  (String, String) get _mood {
    final hour = DateTime.now().hour;
    if (hour < 10) {
      return (
        'Saran untuk pagimu',
        'Kopi dan mi praktis buat mulai hari. Kalau hujan, pilih diantar.'
      );
    } else if (hour < 15) {
      return (
        'Saran waktu siang',
        'Air dingin dan snack siap menemani aktivitas. '
            'Kalau hujan, pilih diantar.'
      );
    } else if (hour < 19) {
      return (
        'Saran untuk soremu',
        'Teh dingin dan camilan cocok untuk waktu santai. '
            'Kalau hujan, pilih diantar.'
      );
    }
    return (
      'Saran untuk malammu',
      'Mi hangat dan kopi cocok untuk stok malam. '
          'Kalau hujan, pilih diantar.'
    );
  }

  @override
  Widget build(BuildContext context) {
    final mood = _mood;
    return Container(
      decoration: BoxDecoration(
        color: context.permukaanKartu,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Text(
              'KABAR WARUNG',
              style: TextStyle(
                color: Color(0xFFB5670B),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SizedBox(
            height: 86,
            child: Stack(
              children: [
                PageView(
                  controller: _controller,
                  onPageChanged: (i) {
                    setState(() => _page = i);
                    if (_programmatic) {
                      _programmatic = false;
                    } else {
                      _pauseAuto();
                    }
                  },
                  children: [
                    _slide(
                      context,
                      leading: Container(
                        width: 9,
                        height: 9,
                        margin:
                            const EdgeInsets.only(left: 5, top: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _open
                              ? const Color(0xFF4D9B65)
                              : const Color(0xFF9B8F89),
                          boxShadow: [
                            BoxShadow(
                              color: (_open
                                      ? const Color(0xFF4D9B65)
                                      : const Color(0xFF9B8F89))
                                  .withValues(alpha: 0.25),
                              blurRadius: 0,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      title: _statusTitle,
                      detail: _statusDetail,
                    ),
                    _slide(
                      context,
                      leading: const Icon(
                        Icons.auto_awesome_outlined,
                        color: AppColors.orange,
                        size: 22,
                      ),
                      title: mood.$1,
                      detail: mood.$2,
                    ),
                  ],
                ),
                // Dots vertikal ala PWA (kanan bawah).
                Positioned(
                  right: 11,
                  bottom: 10,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(2, (i) {
                      final active = i == _page;
                      return GestureDetector(
                        onTap: () => _goTo(i),
                        child: Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active
                                ? AppColors.orange
                                : context.teksRedup.withValues(alpha: 0.4),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _slide(
    BuildContext context, {
    required Widget leading,
    required String title,
    required String detail,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 42, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 30, child: leading),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.teksUtama,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    color: context.teksRedup,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
