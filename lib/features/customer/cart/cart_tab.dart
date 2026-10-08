import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
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
/// Layout mengikuti PWA: judul + ringkasan + menu tersimpan + note grosir.
class CartTab extends ConsumerWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          Strings.keranjangJudul,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (cart.isEmpty)
          const EmptyState(
            icon: Icons.shopping_cart_outlined,
            title: Strings.keranjangKosong,
            hint: Strings.keranjangKosongHint,
          )
        else ...[
          for (var i = 0; i < cart.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _cartLineCard(context, ref, cart[i]),
            ),
          const SizedBox(height: 4),
          _summaryCard(context, ref, cart),
          const SizedBox(height: 12),
          _savedMenuButtons(context, ref),
          const SizedBox(height: 12),
          Text(
            Strings.noteGrosirOtomatis,
            style: TextStyle(
              color: context.teksRedup,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: Strings.pilihAmbilAtauDiantar,
            onPressed: () => _checkout(context, ref),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _cartLineCard(
      BuildContext context, WidgetRef ref, CartLine line) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  formatRp(line.harga),
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
    );
  }

  /// Kartu ringkasan ala PWA: Harga barang / Subtotal / Total pesanan.
  Widget _summaryCard(
      BuildContext context, WidgetRef ref, List<CartLine> cart) {
    final total = ref.read(cartProvider.notifier).total;
    final qty = ref.read(cartProvider.notifier).totalQty;
    return AppCard(
      child: Column(
        children: [
          _summaryRow(
              context, Strings.hargaBarang, formatRp(total)),
          const SizedBox(height: 6),
          _summaryRow(context, Strings.subtotal,
              '$qty barang • ${formatRp(total)}'),
          const Divider(height: 20),
          _summaryRow(
            context,
            Strings.totalPesanan,
            formatRp(total),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
      BuildContext context, String label, String value,
      {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      fontSize: bold ? 16 : 14,
      color: bold ? AppColors.orange : context.teksUtama,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: context.teksRedup,
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w400)),
        Text(value, style: style),
      ],
    );
  }

  /// Tombol "Simpan jadi menu" & "Isi menu tersimpan" ala PWA.
  Widget _savedMenuButtons(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedMenuProvider);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _simpanMenu(context, ref),
            icon: const Icon(Icons.bookmark_add_outlined, size: 18),
            label: const Text(Strings.simpanJadiMenu),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.orange,
              side: const BorderSide(color: AppColors.orange),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                saved.isEmpty ? null : () => _isiMenuTersimpan(context, ref),
            icon: const Icon(Icons.bookmark_outlined, size: 18),
            label: Text(
              saved.isEmpty
                  ? Strings.isiMenuTersimpan
                  : '${Strings.isiMenuTersimpan} (${saved.length})',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.orange,
              side: const BorderSide(color: AppColors.orange),
            ),
          ),
        ),
      ],
    );
  }

  void _simpanMenu(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Strings.isiKeranjangDulu)),
      );
      return;
    }
    ref.read(savedMenuProvider.notifier).state = List.of(cart);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(Strings.menuTersimpanBerhasil)),
    );
  }

  void _isiMenuTersimpan(BuildContext context, WidgetRef ref) {
    final saved = ref.read(savedMenuProvider);
    if (saved.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Strings.menuTersimpanKosong)),
      );
      return;
    }
    final notifier = ref.read(cartProvider.notifier);
    notifier.clear();
    for (final line in saved) {
      // Tambah ulang per qty agar batas stok tetap dihormati.
      for (var i = 0; i < line.qty; i++) {
        if (!notifier.add(line.product,
            harga: line.hargaSatuan)) {
          break;
        }
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(Strings.menuTersimpanDimuat)),
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
              Strings.pilihAmbilAtauDiantar,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              '${cart.length} jenis barang • Total ${formatRp(total)}',
              style: TextStyle(color: context.teksRedup),
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
                price: e.harga,
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
    } catch (e) {
      // ALAT DIAGNOSIS: tampilkan jenis error asli (bukan generik).
      // Log lengkap ke console untuk analisis.
      // ignore: avoid_print
      print('[checkout] ERROR ASLI: $e');
      final kode = _kodeError(e);
      setState(() => _error = 'Pesanan gagal ($kode). Coba lagi ya...');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Ambil kode error singkat dari exception untuk diagnosis.
  /// Contoh: "permission-denied", "not-found", "unavailable".
  String _kodeError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('permission-denied')) return 'permission-denied';
    if (s.contains('not-found')) return 'not-found';
    if (s.contains('unavailable')) return 'unavailable';
    if (s.contains('deadline-exceeded')) return 'timeout';
    if (s.contains('unauthenticated')) return 'belum-login';
    if (s.contains('already-exists')) return 'sudah-ada';
    if (s.contains('failed-precondition')) return 'gagal-prasyarat';
    if (s.contains('aborted')) return 'dibatalkan';
    // Potong 60 karakter pertama sebagai fallback.
    final raw = e.toString();
    return raw.length > 60 ? '${raw.substring(0, 60)}…' : raw;
  }

  Future<void> _showSuccess(
      BuildContext context, WidgetRef ref, String code) async {
    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
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
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(Strings.tutup),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref.read(customerTabProvider.notifier).state = 4;
            },
            child: const Text(Strings.lihatPesanan),
          ),
        ],
      ),
    );
  }
}
