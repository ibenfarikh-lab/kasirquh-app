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
        // Header ala PWA: "Belanjaanmu" / "Keranjang" + tombol Kosongkan.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Belanjaanmu',
                  style: TextStyle(
                    color: context.teksRedup,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Keranjang',
                  style: TextStyle(
                      fontSize: 25, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            if (cart.isNotEmpty)
              OutlinedButton(
                onPressed: () => _kosongkan(context, ref),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF6B4A3A)),
                  foregroundColor: const Color(0xFFFF9D6B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800),
                ),
                child: const Text('Kosongkan'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Area menu tersimpan ala PWA.
        _savedMenuArea(context, ref),
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

  /// Konfirmasi kosongkan keranjang ala PWA.
  Future<void> _kosongkan(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Kosongkan keranjang?'),
        content:
            const Text('Kosongkan semua isi keranjang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(d).pop(true),
            child: const Text('Ya, kosongkan'),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(cartProvider.notifier).clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Keranjang dikosongkan')),
        );
      }
    }
  }

  /// Area "Menu belanja rumah" ala PWA (tampil bila ada menu tersimpan).
  Widget _savedMenuArea(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedMenuProvider);
    if (saved.isEmpty) return const SizedBox.shrink();
    final count = saved.fold(0.0, (s, e) => s + e.qty);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Menu belanja rumah',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                    '${formatStok(count)} barang · tersimpan selama sesi ini',
                    style: TextStyle(
                        color: context.teksRedup, fontSize: 12),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => _isiMenuTersimpan(context, ref),
              child: const Text('Gunakan'),
            ),
          ],
        ),
      ),
    );
  }

  /// Baris item ala PWA: foto + nama + "harga × qty unit" + note + stepper.
  Widget _cartLineCard(
      BuildContext context, WidgetRef ref, CartLine line) {
    final p = line.product;
    final qtyText = isWeightUnit(p.unit)
        ? '${formatStok(line.qty)} ${p.unit}'
        : '${formatStok(line.qty)} ${p.unit}';
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          // Foto 60px.
          SizedBox(
            width: 60,
            height: 60,
            child: Builder(
              builder: (_) {
                final provider = photoImageProvider(p.photoPath);
                if (provider == null) {
                  return Container(
                    decoration: BoxDecoration(
                      color:
                          AppColors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shopping_basket_outlined,
                      size: 28,
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
                        size: 28,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatRp(line.harga)} × $qtyText',
                  style: TextStyle(
                      color: context.teksRedup, fontSize: 12),
                ),
                if (p.adaGrosir &&
                    line.qty >= p.wholesaleQty &&
                    p.wholesaleQty > 0)
                  Text(
                    'Harga ${p.wholesaleLabel.isNotEmpty ? p.wholesaleLabel : 'grosir'} aktif',
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          // Stepper ala PWA ?v=20261012v: timbangan step 0,1,
          // di 0,1 klik "-" → item langsung hilang.
          IconButton(
            onPressed: () {
              final notifier = ref.read(cartProvider.notifier);
              if (isWeightUnit(p.unit)) {
                final nq =
                    ((line.qty - 0.1) * 10).roundToDouble() / 10;
                notifier.setQty(p.id, nq < 0.1 ? 0 : nq);
              } else {
                notifier.setQty(p.id, line.qty - 1);
              }
            },
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            formatStok(line.qty),
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 16),
          ),
          IconButton(
            onPressed: () {
              final notifier = ref.read(cartProvider.notifier);
              if (isWeightUnit(p.unit)) {
                final nq =
                    ((line.qty + 0.1) * 10).roundToDouble() / 10;
                notifier.setQty(p.id, nq);
              } else {
                notifier.setQty(p.id, line.qty + 1);
              }
            },
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  /// Kartu ringkasan ala PWA: Harga barang / Hemat / Subtotal / Total pesanan.
  Widget _summaryCard(
      BuildContext context, WidgetRef ref, List<CartLine> cart) {
    final notifier = ref.read(cartProvider.notifier);
    final total = notifier.total;
    final qty = notifier.totalQty;
    // Hemat: selisih harga normal vs harga aktual (grosir/promo).
    final gross = cart.fold<int>(
        0, (s, e) => s + (e.product.price * e.qty).round());
    final hemat = gross - total;
    return AppCard(
      child: Column(
        children: [
          _summaryRow(
              context, Strings.hargaBarang, formatRp(total)),
          if (hemat > 0) ...[
            const SizedBox(height: 6),
            _summaryRow(
              context,
              'Hemat',
              '−${formatRp(hemat)}',
              highlight: true,
            ),
          ],
          const SizedBox(height: 6),
          _summaryRow(context, Strings.subtotal,
              '${formatStok(qty)} barang • ${formatRp(total)}'),
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
      {bool bold = false, bool highlight = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      fontSize: bold ? 16 : 14,
      color: bold
          ? AppColors.orange
          : highlight
              ? const Color(0xFF2E7D32)
              : context.teksUtama,
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
      // Tambah ulang sekaligus agar batas stok tetap dihormati.
      notifier.add(line.product,
          harga: line.hargaSatuan, qty: line.qty);
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
  String _fulfillment = 'pickup'; // pickup | delivery
  String _payment = 'cod';
  final _address = TextEditingController();
  String _slot = 'Secepatnya · 15–30 menit';
  final _transferRef = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _pakaiKoin = false;

  static const _ongkir = 5000;

  @override
  void dispose() {
    _address.dispose();
    _transferRef.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final belanja = ref.read(cartProvider.notifier).total;
    final ongkir = _fulfillment == 'delivery' ? _ongkir : 0;
    final koinDipakai = _koinDipakai(ref, belanja);
    // 1 koin = Rp1 (ikut peta PWA).
    final potonganKoin = koinDipakai;
    final grand = belanja + ongkir - potonganKoin;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header ala PWA: kicker + judul + ×.
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selesaikan pesanan',
                          style: TextStyle(
                            color: context.teksRedup,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Ambil atau Diantar',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Metode ambil/diantar.
              _segmented(
                context,
                options: const [
                  ('pickup', 'Ambil di warung'),
                  ('delivery', 'Diantar · Rp5.000'),
                ],
                value: _fulfillment,
                onChanged: (v) =>
                    setState(() => _fulfillment = v),
              ),
              const SizedBox(height: 8),
              // Metode pembayaran.
              _segmented(
                context,
                options: const [
                  ('cod', 'Tunai / COD'),
                  ('transfer', 'Transfer'),
                ],
                value: _payment,
                onChanged: (v) => setState(() => _payment = v),
              ),
              // Referensi transfer (kondisional).
              if (_payment == 'transfer') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _transferRef,
                  decoration: const InputDecoration(
                    labelText: 'Referensi / no. transfer',
                    hintText: 'Contoh: TRF-987654 (dari m-banking)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tulis nomor referensi setelah transfer · tanpa foto bukti.',
                  style: TextStyle(
                      color: context.teksRedup, fontSize: 12),
                ),
              ],
              // Field antar (kondisional).
              if (_fulfillment == 'delivery') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _address,
                  decoration: const InputDecoration(
                    labelText: 'Patokan rumah',
                    hintText:
                        'Contoh: rumah pagar hijau dekat pos',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _slot,
                  decoration: const InputDecoration(
                    labelText: 'Waktu antar',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    'Secepatnya · 15–30 menit',
                    '12.00–13.00',
                    '16.00–17.00',
                    '19.00–20.00',
                  ]
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _slot = v ?? _slot),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
              // Box Tukar Koin Warga ala PWA.
              const SizedBox(height: 12),
              _koinBox(context, ref, belanja),
              // Ringkasan ala PWA.
              const SizedBox(height: 16),
              _ringkasRow('Belanja', formatRp(belanja)),
              const SizedBox(height: 6),
              _ringkasRow('Ongkir', formatRp(ongkir)),
              if (potonganKoin > 0) ...[
                const SizedBox(height: 6),
                _ringkasRow(
                  'Koin Warga (-$koinDipakai)',
                  '-${formatRp(potonganKoin)}',
                ),
              ],
              const Divider(height: 20),
              _ringkasRow(
                'Total dibayar',
                formatRp(grand),
                bold: true,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style:
                        const TextStyle(color: AppColors.danger),
                  ),
                ),
              const SizedBox(height: 16),
              AppButton(
                label: _fulfillment == 'delivery'
                    ? 'Pesan & minta diantar'
                    : 'Pesan & ambil di warung',
                onPressed: _busy ? null : () => _submit(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Box Tukar Koin Warga ala PWA.
  /// Rumus: maksimal = total × 50% / 100; koin = min(saldo, maksimal).
  Widget _koinBox(BuildContext context, WidgetRef ref, int belanja) {
    final session = ref.watch(sessionProvider).valueOrNull;
    final saldo = session?.coins ?? 0;
    if (saldo <= 0) return const SizedBox.shrink();

    // Batas 50% dari total belanja (ikut peta PWA).
    final maksimal = (belanja * 50 ~/ 100);
    final koinBisa = saldo < maksimal ? saldo : maksimal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0C8),
        border: Border.all(color: const Color(0xFFECCB9E)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.monetization_on, color: Color(0xFF8B5910)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tukar Koin Warga',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Saldo: $saldo koin · Bisa pakai: $koinBisa koin',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF8B5910)),
                ),
              ],
            ),
          ),
          Switch(
            value: _pakaiKoin,
            onChanged: (v) => setState(() => _pakaiKoin = v),
            activeThumbColor: AppColors.orange,
          ),
        ],
      ),
    );
  }

  /// Hitung koin yang dipakai (0 jika tidak dicentang).
  int _koinDipakai(WidgetRef ref, int belanja) {
    if (!_pakaiKoin) return 0;
    final session = ref.read(sessionProvider).valueOrNull;
    final saldo = session?.coins ?? 0;
    final maksimal = (belanja * 50 ~/ 100);
    return saldo < maksimal ? saldo : maksimal;
  }

  /// Segmented control ala PWA.
  Widget _segmented(
    BuildContext context, {
    required List<(String, String)> options,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.teksRedup.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final (v, label) in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(v),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: v == value
                        ? Theme.of(context).cardColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    border: v == value
                        ? Border.all(color: AppColors.orange)
                        : null,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: v == value
                          ? AppColors.orange
                          : context.teksUtama,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ringkasRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: context.teksRedup,
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w400)),
        Text(value,
            style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                fontSize: bold ? 16 : 14,
                color: bold ? AppColors.orange : null)),
      ],
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    // Validasi: diantar wajib isi patokan rumah.
    if (_fulfillment == 'delivery' && _address.text.trim().isEmpty) {
      setState(() => _error = 'Isi patokan rumah untuk diantar.');
      return;
    }
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
      // Info fulfillment digabung ke catatan (skema order belum ada field khusus).
      final info = <String>[];
      info.add(_fulfillment == 'delivery' ? 'Diantar' : 'Ambil di warung');
      if (_fulfillment == 'delivery') {
        info.add('Patokan: ${_address.text.trim()}');
        info.add('Waktu: $_slot');
      }
      if (_payment == 'transfer' && _transferRef.text.trim().isNotEmpty) {
        info.add('Ref: ${_transferRef.text.trim()}');
      }
      final noteUser = _note.text.trim();
      final note =
          ([...info, if (noteUser.isNotEmpty) noteUser]).join(' · ');
      final belanjaTotal =
          ref.read(cartProvider.notifier).total;
      final koinDipakai = _koinDipakai(ref, belanjaTotal);
      final code =
          await ref.read(orderRepositoryProvider).checkout(
                customerId: uid,
                customerName: displayName(session!),
                items: items,
                paymentMethod: _payment,
                note: note.isEmpty ? null : note,
                koinDipakai: koinDipakai,
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
