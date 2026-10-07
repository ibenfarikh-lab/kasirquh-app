import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider);
    final cart = ref.watch(posCartProvider);
    final total = ref.read(posCartProvider.notifier).total;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  style: const TextStyle(color: AppColors.warmText),
                  decoration: InputDecoration(
                    hintText: Strings.cariAtauPindai,
                    hintStyle:
                        const TextStyle(color: AppColors.warmMuted),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.warmMuted),
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
              IconButton.filled(
                onPressed: _openScanner,
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: Strings.pindaiBarcode,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.adminBg,
                ),
              ),
            ],
          ),
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
              final list = filterProducts(all, query: _query)
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
        if (cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.panel,
              border: Border(top: BorderSide(color: AppColors.adminLine)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${ref.read(posCartProvider.notifier).totalQty} barang',
                          style: const TextStyle(
                              color: AppColors.warmMuted, fontSize: 12),
                        ),
                        Text(
                          formatRp(total),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: AppButton(
                      label: Strings.bayar,
                      onPressed: () => _openPay(context),
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.warmText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatRp(product.price)} · stok ${formatStok(product.stock)}',
                    style: const TextStyle(
                        color: AppColors.warmMuted, fontSize: 12),
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
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.warmText)),
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
