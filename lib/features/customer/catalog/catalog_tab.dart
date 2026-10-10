import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/product_photo.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../l10n/strings_id.dart';
import '../cart/cart_provider.dart';
import '../chat/toko_chat_page.dart';
import '../home/home_tab.dart';
import '../session.dart';

/// Tab Produk — katalog barang kemasan.
/// Harga & stok TERBUKA untuk tamu (keputusan dikunci).
class CatalogTab extends ConsumerStatefulWidget {
  const CatalogTab({super.key});

  @override
  ConsumerState<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends ConsumerState<CatalogTab> {
  final _search = TextEditingController();
  String _category = '';

  @override
  void initState() {
    super.initState();
    // Filter yang diminta dari Beranda (kategori cepat).
    final preset = ref.read(catalogFilterProvider);
    _category = preset.category;
    _search.text = preset.query;
    if (preset.category.isNotEmpty || preset.query.isNotEmpty) {
      ref.read(catalogFilterProvider.notifier).state = const CatalogFilter();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncProducts = ref.watch(productsProvider);
    return Column(
      children: [
        // Header ala PWA: kicker + judul + search.
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Katalog lengkap',
                style: TextStyle(
                  color: context.teksRedup,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'Cari kebutuhan rumah',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari sembako, minuman, snack...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 13, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Judul "Kategori" ala PWA.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Kategori',
              style: TextStyle(
                color: context.teksUtama,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              _chip('Semua', ''),
              for (final c in kProductCategories) _chip(c, c),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Header: "{Kategori}" + tombol Muat ulang (ala PWA).
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _category.isEmpty ? 'Semua produk' : _category,
                style: TextStyle(
                  color: context.teksUtama,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  ref.invalidate(productsProvider);
                  ref.invalidate(promosProvider);
                },
                icon: const Text('⟳',
                    style: TextStyle(fontSize: 16)),
                label: const Text('Muat ulang',
                    style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Hero promo kilat ala PWA (kondisional: hanya bila flash aktif).
        _flashHero(ref),
        Expanded(
          child: asyncProducts.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) => EmptyState(
              icon: Icons.cloud_off_outlined,
              title: Strings.gagalMuatProduk,
              hint: Strings.periksaKoneksi,
              actionLabel: Strings.cobaLagi,
              onAction: () => ref.invalidate(productsProvider),
            ),
            data: (products) {
              final filtered = filterProducts(
                products,
                query: _search.text,
                category: _category,
              );
              if (filtered.isEmpty) {
                return const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  // Teks PWA persis.
                  title: 'Produk tidak ditemukan.',
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: filtered.length,
                itemBuilder: (_, i) =>
                    _ProductCard(product: filtered[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Hero promo kilat ala PWA: gradient oranye, hanya bila flash aktif.
  Widget _flashHero(WidgetRef ref) {
    final store = ref.watch(storeInfoProvider).valueOrNull;
    final flashId = store?.flashProductId;
    if (flashId == null || flashId.isEmpty) {
      return const SizedBox.shrink();
    }
    final products =
        ref.watch(productsProvider).valueOrNull ?? const <Product>[];
    Product? product;
    for (final p in products) {
      if (p.id == flashId) {
        product = p;
        break;
      }
    }
    if (product == null) return const SizedBox.shrink();
    final flashPrice = store!.flashPrice;
    final hargaPromo = flashPrice > 0 ? flashPrice : product.price;
    final prod = product;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF9B3E), Color(0xFFE07F0A)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PROMO KILAT · TERBATAS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prod.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        formatRp(prod.price),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatRp(hargaPromo),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                builder: (_) => ProductDetailSheet(product: prod),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF34231C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Lihat Detail',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  /// Chip kategori ala PWA: border, aktif = krem #fdeeda, "✓ " utk Semua aktif.
  Widget _chip(String label, String value) {
    final active = _category == value;
    final text = (label == 'Semua' && active) ? '✓ $label' : label;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _category = value),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFDEEDA) : Colors.white,
            border: Border.all(
              color: active
                  ? const Color(0xFFFDEEDA)
                  : const Color(0xFF2B2B2B),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
      ),
    );
  }
}

/// Harga jual aktif produk: harga promo bila ada promo produk yang aktif,
/// selain itu harga normal. Skema: "harga tampilan = harga keranjang".
int hargaJualAktif(Product p, List<Promo> promos) {
  for (final pr in promos) {
    if (pr.isActive && pr.productId == p.id && pr.discountType != null) {
      final h = pr.hargaPromo(p.price);
      if (h < p.price) return h;
    }
  }
  return p.price;
}

/// Kartu produk ala PWA: flag PROMO/HABIS, foto, nama, harga, stok,
/// tombol "+" bulat kanan-bawah. Tap kartu → detail, tap "+" → +1 keranjang.
class _ProductCard extends ConsumerWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final out = product.stock <= 0;
    final promos = ref.watch(promosProvider).valueOrNull ?? const <Promo>[];
    final hargaAkhir = hargaJualAktif(product, promos);
    final adaDiskon = hargaAkhir < product.price;

    void tambahSatu() {
      final ok = ref.read(cartProvider.notifier).add(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? '${product.name} masuk keranjang'
              : Strings.stokMenipis),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    return AppCard(
      onTap: () => _showDetail(context, ref),
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto full-width 90px.
                SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: Builder(
                    builder: (_) {
                      final provider =
                          photoImageProvider(product.photoPath);
                      if (provider == null) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.orange
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.shopping_basket_outlined,
                            size: 36,
                            color: AppColors.orange,
                          ),
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image(
                          image: provider,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              color: AppColors.orange
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.shopping_basket_outlined,
                              size: 36,
                              color: AppColors.orange,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                if (adaDiskon)
                  Text(
                    formatRp(product.price),
                    style: TextStyle(
                      color: context.teksRedup,
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Text(
                  formatRp(hargaAkhir),
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stok ${formatStok(product.stock)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: out ? AppColors.danger : context.teksRedup,
                  ),
                ),
                // Ruang untuk tombol "+" absolute.
                const SizedBox(height: 28),
              ],
            ),
          ),
          // Flag PROMO / HABIS kiri-atas.
          if (adaDiskon || out)
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  color: out
                      ? const Color(0xFF999999)
                      : const Color(0xFFDF624F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  out ? 'HABIS' : 'PROMO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          // Tombol "+" bulat kanan-bawah.
          Positioned(
            right: 8,
            bottom: 8,
            child: Opacity(
              opacity: out ? 0.4 : 1,
              child: SizedBox(
                width: 44,
                height: 44,
                child: ElevatedButton(
                  onPressed: out ? null : tambahSatu,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: const Color(0xFF24170F),
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                    elevation: 2,
                  ),
                  child: const Text(
                    '+',
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ProductDetailSheet(product: product),
    );
  }
}

class ProductDetailSheet extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailSheet({super.key, required this.product});

  @override
  ConsumerState<ProductDetailSheet> createState() =>
      ProductDetailSheetState();
}

class ProductDetailSheetState
    extends ConsumerState<ProductDetailSheet> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final out = p.stock <= 0;
    final promos = ref.watch(promosProvider).valueOrNull ?? const <Promo>[];
    final harga = hargaJualAktif(p, promos);
    final adaDiskon = harga < p.price;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tombol Tutup (ala PWA).
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ),
            // Foto produk (bila ada) + badge PROMO ala PWA.
            if (p.photoPath != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Stack(
                    children: [
                      ProductPhoto(
                        photoPath: p.photoPath,
                        size: 160,
                      ),
                      if (adaDiskon)
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDF624F),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'PROMO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            Text(p.name,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            // KATEGORI: X (format PWA).
            Text('KATEGORI: ${p.category.isEmpty ? '-' : p.category}',
                style: TextStyle(color: context.teksRedup, fontSize: 13)),
            // SATUAN: X (format PWA).
            Text('SATUAN: ${p.unit}',
                style: TextStyle(color: context.teksRedup, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                if (adaDiskon)
                  Text(
                    formatRp(p.price),
                    style: TextStyle(
                      color: context.teksRedup,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                if (adaDiskon) const SizedBox(width: 8),
                Text(
                  formatRp(harga),
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                const Spacer(),
                // STOK: N pcs (format PWA).
                Text(
                  out
                      ? Strings.habis
                      : 'STOK: ${formatStok(p.stock)} ${p.unit}',
                  style: TextStyle(
                    color: out ? AppColors.danger : context.teksRedup,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            // Label GROSIR (ala PWA) — jika ada harga grosir.
            if (p.adaGrosir) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.orange.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'GROSIR: ${p.wholesaleLabel.isNotEmpty ? p.wholesaleLabel : 'Beli ${p.wholesaleQty} ${p.unit}'} · ${formatRp(p.wholesalePrice)}/${p.unit}',
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            if ((p.barcode ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Barcode: ${p.barcode}',
                  style: TextStyle(
                      color: context.teksRedup, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(Strings.jumlah,
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  onPressed: _qty > 1
                      ? () => setState(() => _qty--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Kurangi',
                ),
                Text('$_qty',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(
                  onPressed: _qty < p.stock
                      ? () => setState(() => _qty++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Tambah',
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppButton(
              label:
                  '+ Keranjang • ${formatRp(harga * _qty)}',
              onPressed: out
                  ? null
                  : () {
                      final cart = ref.read(cartProvider.notifier);
                      for (var i = 0; i < _qty; i++) {
                        if (!cart.add(p, harga: harga)) break;
                      }
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('${p.name} masuk keranjang'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
            ),
            const SizedBox(height: 8),
            // Tanya Toko + Pantau harga (ala PWA).
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Tanya Toko butuh login — tamu diarahkan ke gate.
                      final session = ref
                          .read(sessionProvider)
                          .valueOrNull;
                      final uid = memberUid(
                          session ?? const Session.guest());
                      if (uid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Masuk/Daftar dulu untuk chat dengan toko'),
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TokoChatPage(uid: uid),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline,
                        size: 18),
                    label: const Text('Tanya Toko'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _pantauHarga(context, ref, p),
                    icon: const Icon(Icons.notifications_outlined,
                        size: 18),
                    label: const Text('Pantau harga'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Pantau harga: simpan ke lokal, notifikasi saat harga turun.
  Future<void> _pantauHarga(
      BuildContext context, WidgetRef ref, Product p) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list =
          prefs.getStringList('pantau_harga') ?? <String>[];
      if (list.contains(p.id)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Harga produk ini sudah dipantau')),
          );
        }
        return;
      }
      // Simpan id + harga saat ini.
      list.add('${p.id}:${p.price}');
      await prefs.setStringList('pantau_harga', list);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Harga ${p.name} dipantau — kabari jika turun')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gagal menyimpan pantauan harga')),
        );
      }
    }
  }
}
