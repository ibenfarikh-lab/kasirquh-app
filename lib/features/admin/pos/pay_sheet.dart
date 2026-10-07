import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../l10n/strings_id.dart';
import '../../customer/cart/cart_provider.dart';
import 'pos_tab.dart';

/// Kembalian = diterima - total. Negatif = uang kurang.
int kembalian(int diterima, int total) => diterima - total;

/// Kunci struk terakhir di SharedPreferences.
const kLastReceiptKey = 'strukTerakhir';

/// Simpan teks struk terakhir agar bisa dibuka ulang dari modul Struk.
/// Fungsi terpisah agar bisa di-test/di-mock.
Future<void> simpanStrukTerakhir(String teks) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(kLastReceiptKey, teks);
}

/// Baca struk terakhir; null bila belum pernah ada.
Future<String?> bacaStrukTerakhir() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(kLastReceiptKey);
}

/// Bangun teks struk 58mm (32 kolom, teks rata).
/// Tanpa istilah siluman — hanya data transaksi nyata.
String buildReceipt({
  required String storeName,
  required String code,
  required DateTime date,
  required List<CartLine> lines,
  required int total,
  required int received,
}) {
  const w = 32;
  final b = StringBuffer();
  String center(String s) {
    if (s.length >= w) return s.substring(0, w);
    final pad = (w - s.length) ~/ 2;
    return '${' ' * pad}$s';
  }

  String row(String left, String right) {
    final space = w - left.length - right.length;
    if (space < 1) return '$left $right'.substring(0, w);
    return '$left${' ' * space}$right';
  }

  b.writeln(center(storeName));
  b.writeln(center(_fmtDate(date)));
  b.writeln(center(code));
  b.writeln('-' * w);
  for (final l in lines) {
    var name = l.product.name;
    if (name.length > w) name = name.substring(0, w);
    b.writeln(name);
    b.writeln(row(
        '${l.qty} x ${formatRp(l.product.price)}', formatRp(l.subtotal)));
  }
  b.writeln('-' * w);
  b.writeln(row('Total', formatRp(total)));
  b.writeln(row('Tunai', formatRp(received)));
  b.writeln(row('Kembali', formatRp(kembalian(received, total))));
  b.writeln('-' * w);
  b.writeln(center(Strings.terimaKasih));
  return b.toString();
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Sheet Bayar: input uang diterima → kembalian otomatis → simpan → struk.
class PaySheet extends ConsumerStatefulWidget {
  const PaySheet({super.key});

  @override
  ConsumerState<PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends ConsumerState<PaySheet> {
  final _received = TextEditingController();
  bool _busy = false;
  String? _doneCode;

  @override
  void dispose() {
    _received.dispose();
    super.dispose();
  }

  int get _total => ref.read(posCartProvider.notifier).total;

  int get _receivedInt =>
      int.tryParse(_received.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final lines = ref.watch(posCartProvider);
    final change = kembalian(_receivedInt, _total);
    final canPay = _doneCode == null &&
        lines.isNotEmpty &&
        _receivedInt >= _total &&
        _total > 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          // Aturan 1&3: ikut bottomSheetTheme (adaptif).
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: _doneCode == null
            ? _payForm(controller, change, canPay)
            : _receiptView(controller),
      ),
    );
  }

  Widget _payForm(
      ScrollController controller, int change, bool canPay) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.adminLine,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          Strings.bayar,
          style: TextStyle(
            color: context.teksUtama,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(Strings.totalBayar,
                style: TextStyle(color: context.teksRedup)),
            Text(
              formatRp(_total),
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _received,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
              color: context.teksUtama,
              fontSize: 20,
              fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            labelText: Strings.uangDiterima,
            labelStyle: TextStyle(color: context.teksRedup),
            prefixText: 'Rp ',
            prefixStyle: TextStyle(color: context.teksRedup),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.adminLine),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [10000, 20000, 50000, 100000].map((n) {
            return ActionChip(
              label: Text(formatRp(n)),
              onPressed: () => setState(() => _received.text = '$n'),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(Strings.kembalian,
                style: TextStyle(color: context.teksRedup)),
            Text(
              change < 0 ? Strings.uangKurang : formatRp(change),
              style: TextStyle(
                color: change < 0 ? AppColors.danger : AppColors.ok,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AppButton(
          label: _busy ? '...' : Strings.bayar,
          onPressed: !canPay || _busy ? null : _pay,
        ),
      ],
    );
  }

  Future<void> _pay() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final lines = ref.read(posCartProvider).toList();
      final received = _receivedInt;
      final total = _total;
      final items = lines
          .map((l) => OrderItem(
                productId: l.product.id,
                name: l.product.name,
                qty: l.qty,
                price: l.product.price,
              ))
          .toList();
      final code = await repo.recordCashSale(
        items: items,
        total: total,
        received: received,
      );
      // Salinan untuk struk (keranjang dikosongkan setelahnya).
      _lastLines = lines;
      _lastTotal = total;
      _lastReceived = received;
      // Simpan struk terakhir — bisa dibuka ulang dari modul Struk.
      final struk = buildReceipt(
        storeName: Strings.appName,
        code: code,
        date: DateTime.now(),
        lines: lines,
        total: total,
        received: received,
      );
      unawaited(simpanStrukTerakhir(struk));
      ref.read(posCartProvider.notifier).clear();
      if (mounted) setState(() => _doneCode = code);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Strings.checkoutGagal} ($e)')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _receiptView(ScrollController controller) {
    // Struk dibangun dari data terakhir sebelum keranjang dikosongkan —
    // simpan salinan saat bayar. Di sini bangun ulang ringkas dari kode.
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.check_circle, color: AppColors.ok, size: 56),
        const SizedBox(height: 12),
        Text(
          Strings.penjualanTersimpan,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: context.teksUtama,
              fontSize: 18,
              fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          _doneCode ?? '',
          textAlign: TextAlign.center,
          style:
              TextStyle(color: context.teksRedup, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Text(
          Strings.strukBelanja,
          style: TextStyle(
              color: context.teksRedup, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // Kertas struk ngikutin tema (aturan: tema gelap tanpa putih).
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.panel2
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            buildReceipt(
              storeName: Strings.appName,
              code: _doneCode ?? '',
              date: DateTime.now(),
              lines: _lastLines,
              total: _lastTotal,
              received: _lastReceived,
            ),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? context.teksUtama
                  : Colors.black87,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: Strings.tutup,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // Salinan data struk (diisi saat _pay).
  List<CartLine> _lastLines = const [];
  int _lastTotal = 0;
  int _lastReceived = 0;
}
