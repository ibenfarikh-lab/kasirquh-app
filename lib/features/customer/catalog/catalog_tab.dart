import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../l10n/strings_id.dart';
import '../cart/cart_provider.dart';
import '../home/home_tab.dart';

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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: Strings.cariBarang,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _chip(Strings.semua, ''),
              for (final c in kProductCategories) _chip(c, c),
            ],
          ),
        ),
        const SizedBox(height: 4),
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
                  title: Strings.belumAdaProduk,
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

  Widget _chip(String label, String value) {
    final active = _category == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => setState(() => _category = value),
        selectedColor: AppColors.orange.withValues(alpha: 0.2),
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

class _ProductCard extends ConsumerWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final out = product.stock <= 0;
    // Promo produk: harga coret + harga promo (skema: discountType/Value).
    final promos = ref.watch(promosProvider).valueOrNull ?? const <Promo>[];
    final hargaAkhir = hargaJualAktif(product, promos);
    final adaDiskon = hargaAkhir < product.price;
    return AppCard(
      onTap: () => _showDetail(context, ref),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto (bila ada) — tanpa foto: blok kategori.
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.shopping_basket_outlined,
                size: 40,
                color: AppColors.orange,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 2),
          if (adaDiskon)
            Text(
              formatRp(product.price),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          Text(
            formatRp(hargaAkhir),
            style: const TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            out
                ? Strings.habis
                : product.stock <= product.lowStockAt
                    ? '${Strings.stokMenipis} (${product.stock})'
                    : 'Stok ${product.stock}',
            style: TextStyle(
              fontSize: 12,
              color: out ? AppColors.danger : AppColors.muted,
              fontWeight: out ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: out
                  ? null
                  : () {
                      final ok = ref
                          .read(cartProvider.notifier)
                          .add(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? '${product.name} masuk keranjang'
                              : Strings.stokMenipis),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
              child: const Text(Strings.tambahKeranjang,
                  style: TextStyle(fontSize: 12)),
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
      builder: (_) => _ProductDetailSheet(product: product),
    );
  }
}

class _ProductDetailSheet extends ConsumerStatefulWidget {
  final Product product;

  const _ProductDetailSheet({required this.product});

  @override
  ConsumerState<_ProductDetailSheet> createState() =>
      _ProductDetailSheetState();
}

class _ProductDetailSheetState
    extends ConsumerState<_ProductDetailSheet> {
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
            Text(p.name,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(p.category,
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            Row(
              children: [
                if (adaDiskon)
                  Text(
                    formatRp(p.price),
                    style: const TextStyle(
                      color: AppColors.muted,
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
                Text(
                  out
                      ? Strings.habis
                      : 'Stok ${p.stock}',
                  style: TextStyle(
                    color: out ? AppColors.danger : AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if ((p.barcode ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Barcode: ${p.barcode}',
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 13)),
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
                ),
                Text('$_qty',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(
                  onPressed: _qty < p.stock
                      ? () => setState(() => _qty++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppButton(
              label:
                  '${Strings.tambahKeranjang} • ${formatRp(harga * _qty)}',
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
          ],
        ),
      ),
    );
  }
}
