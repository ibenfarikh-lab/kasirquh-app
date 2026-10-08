import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/product_photo.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../l10n/strings_id.dart';
import '../../customer/cart/cart_provider.dart';
import 'pay_sheet.dart';
import 'scanner_sheet.dart';

/// Keranjang kasir — instance terpisah dari keranjang pelanggan.
final posCartProvider =
    StateNotifierProvider<CartNotifier, List<CartLine>>((ref) {
  return CartNotifier();
});

/// Tab Kasir (POS): cari produk, pindai barcode, keranjang,
/// bayar tunai + kembalian otomatis, struk 58mm.
class PosTab extends ConsumerStatefulWidget {
  const PosTab({super.key});

  @override
  ConsumerState<PosTab> createState() => _PosTabState();
}

class _PosTabState extends ConsumerState<PosTab> {
  final _search = TextEditingController();
  String _query = '';
  String _category = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider);
    final cart = ref.watch(posCartProvider);
    final notifier = ref.read(posCartProvider.notifier);
    final total = notifier.total;
    final totalQty = notifier.totalQty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header ala PWA: "Alat kasir cepat".
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            Strings.alatKasirCepat,
            style: TextStyle(
              color: context.teksUtama,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  style: TextStyle(color: context.teksUtama),
                  decoration: InputDecoration(
                    hintText: Strings.cariAtauPindai,
                    hintStyle:
                        TextStyle(color: context.teksRedup),
                    prefixIcon: Icon(Icons.search,
                        color: context.teksRedup),
                    border: const OutlineInputBorder(),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.adminLine),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                  onSubmitted: _submitBarcode,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _openScanner,
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text(Strings.pindai),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.adminBg,
                ),
              ),
            ],
          ),
        ),
        // Kategori + jumlah + muat ulang (ala PWA).
        productsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (all) {
            final cats = <String>{};
            for (final p in all) {
              if (p.category.isNotEmpty) cats.add(p.category);
            }
            final sortedCats = cats.toList()..sort();
            final list = filterProducts(all,
                    query: _query, category: _category)
                .where((p) => p.active)
                .toList();
            return Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: '',
                            child: Text(Strings.semuaKategori)),
                        for (final c in sortedCats)
                          DropdownMenuItem(
                              value: c, child: Text(c)),
                      ],
                      onChanged: (v) =>
                          setState(() => _category = v ?? ''),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${list.length}',
                    style: TextStyle(
                        color: context.teksRedup, fontSize: 13),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        ref.invalidate(adminProductsProvider),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text(Strings.muatUlangProduk,
                        style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: productsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) => const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: Strings.belumAdaProduk,
            ),
            data: (all) {
              final list = filterProducts(all,
                      query: _query, category: _category)
                  .where((p) => p.active)
                  .toList();
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: Strings.belumAdaProduk,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: list.length,
                itemBuilder: (_, i) => _ProductRow(product: list[i]),
              );
            },
          ),
        ),
        // Panel Transaksi Aktif — selalu tampil (ala PWA).
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: context.permukaanKartu,
            border: Border(top: BorderSide(color: AppColors.adminLine)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${Strings.transaksiAktif} $totalQty item',
                  style: TextStyle(
                    color: context.teksUtama,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (cart.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      Strings.belumAdaBarang,
                      style: TextStyle(
                          color: context.teksRedup, fontSize: 13),
                    ),
                  )
                else
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      itemCount: cart.length,
                      itemBuilder: (_, i) {
                        final line = cart[i];
                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${line.qty}× ${line.product.name}',
                                  style: TextStyle(
                                      color: context.teksUtama,
                                      fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                formatRp(line.subtotal),
                                style: TextStyle(
                                    color: context.teksRedup,
                                    fontSize: 13),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () => notifier.setQty(
                                    line.product.id, 0),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(Strings.subtotal,
                        style: TextStyle(
                            color: context.teksRedup, fontSize: 13)),
                    Text(
                      formatRp(total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: '${Strings.bayar} ${formatRp(total)}',
                    onPressed: cart.isEmpty
                        ? null
                        : () => _openPay(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _submitBarcode(String value) {
    final q = value.trim();
    if (q.isEmpty) return;
    _findAndAdd(q);
  }

  Future<void> _openScanner() async {
    final barcode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ScannerSheet(),
    );
    if (barcode != null && barcode.isNotEmpty && mounted) {
      _findAndAdd(barcode);
    }
  }

  Future<void> _findAndAdd(String barcode) async {
    final product =
        await ref.read(adminRepositoryProvider).findByBarcode(barcode);
    if (!mounted) return;
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Strings.barcodeTidakDikenal)),
      );
      return;
    }
    final ok = ref.read(posCartProvider.notifier).add(product);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${Strings.stokTidakCukup} ${product.name}')),
      );
    }
  }

  void _openPay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaySheet(),
    );
  }
}

class _ProductRow extends ConsumerWidget {
  final Product product;

  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inCart = ref.watch(posCartProvider
        .select((c) => c.where((e) => e.product.id == product.id)));
    final qty = inCart.isEmpty ? 0 : inCart.first.qty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ProductPhoto(
              photoPath: product.photoPath,
              size: 44,
              borderRadius: 10,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: context.teksUtama),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatRp(product.price)} · stok ${formatStok(product.stock)}',
                    style: TextStyle(
                        color: context.teksRedup, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (qty == 0)
              IconButton.filled(
                onPressed: product.stock > 0
                    ? () => ref.read(posCartProvider.notifier).add(product)
                    : null,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.adminBg,
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => ref
                        .read(posCartProvider.notifier)
                        .setQty(product.id, qty - 1),
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppColors.orange),
                  ),
                  Text('$qty',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: context.teksUtama)),
                  IconButton(
                    onPressed: () => ref
                        .read(posCartProvider.notifier)
                        .add(product),
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppColors.orange),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
