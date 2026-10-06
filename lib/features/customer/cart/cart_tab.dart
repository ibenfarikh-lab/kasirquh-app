import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/guest_lock_sheet.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../l10n/strings_id.dart';
import '../customer_shell.dart';
import '../session.dart';
import 'cart_provider.dart';

/// Tab Keranjang — tamu boleh isi; kunci HANYA di checkout.
/// Setelah login/daftar, checkout dilanjutkan otomatis.
class CartTab extends ConsumerWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    if (cart.isEmpty) {
      return const EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: Strings.keranjangKosong,
        hint: Strings.keranjangKosongHint,
      );
    }
    final total = ref.read(cartProvider.notifier).total;
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cart.length,
            itemBuilder: (_, i) {
              final line = cart[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.product.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatRp(line.product.price),
                              style: const TextStyle(
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => ref
                            .read(cartProvider.notifier)
                            .setQty(line.product.id, line.qty - 1),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('${line.qty}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      IconButton(
                        onPressed: () => ref
                            .read(cartProvider.notifier)
                            .setQty(line.product.id, line.qty + 1),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatRp(line.subtotal),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(top: BorderSide(color: AppColors.line)),
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
                      const Text('Total',
                          style: TextStyle(color: AppColors.muted)),
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
                ),
                SizedBox(
                  width: 160,
                  child: AppButton(
                    label: Strings.checkout,
                    onPressed: () => _checkout(context, ref),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    await requireLogin(context, ref, () async {
      if (!context.mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => const _CheckoutSheet(),
      );
    });
  }
}

class _CheckoutSheet extends ConsumerStatefulWidget {
  const _CheckoutSheet();

  @override
  ConsumerState<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<_CheckoutSheet> {
  String _payment = 'cod';
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = ref.read(cartProvider.notifier).total;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              Strings.checkout,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              '${cart.length} jenis barang • Total ${formatRp(total)}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            const Text(
              Strings.metodePembayaran,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            RadioGroup<String>(
              groupValue: _payment,
              onChanged: (v) => setState(() => _payment = v!),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'cod',
                    title: const Text(Strings.bayarDiTempat),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>(
                    value: 'transfer',
                    title: const Text(Strings.transferBank),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: Strings.catatanOpsional,
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            const SizedBox(height: 16),
            AppButton(
              label: '${Strings.buatPesanan} • ${formatRp(total)}',
              onPressed: _busy ? null : () => _submit(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = ref.read(sessionProvider).valueOrNull;
      final uid = session == null || session.isGuest ? null : session.user?.uid;
      if (uid == null) {
        setState(() => _error = Strings.guestLockBody);
        return;
      }
      final cart = ref.read(cartProvider);
      final items = cart
          .map((e) => OrderItem(
                productId: e.product.id,
                name: e.product.name,
                qty: e.qty,
                price: e.product.price,
              ))
          .toList();
      final code =
          await ref.read(orderRepositoryProvider).checkout(
                customerId: uid,
                customerName: displayName(session!),
                items: items,
                paymentMethod: _payment,
                note: _note.text.trim().isEmpty ? null : _note.text.trim(),
              );
      ref.read(cartProvider.notifier).clear();
      if (!context.mounted) return;
      Navigator.of(context).pop();
      await _showSuccess(context, ref, code);
    } on OfflineCheckout {
      setState(() => _error = Strings.butuhInternet);
    } on StockShortage catch (e) {
      setState(() =>
          _error = '${Strings.stokTidakCukup} ${e.productNames.join(', ')}');
    } catch (_) {
      setState(() => _error = Strings.checkoutGagal);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showSuccess(
      BuildContext context, WidgetRef ref, String code) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(Strings.pesananBerhasil),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(Strings.kodePesanan),
            const SizedBox(height: 4),
            Text(
              code,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(Strings.tutup),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(customerTabProvider.notifier).state = 4;
            },
            child: const Text(Strings.lihatPesanan),
          ),
        ],
      ),
    );
  }
}
