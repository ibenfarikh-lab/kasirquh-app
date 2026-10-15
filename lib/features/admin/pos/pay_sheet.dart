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
import '../../../data/models/customer.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/store_repository.dart';
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
  String? memberName,
  String? memberCode,
  int koinDipakai = 0,
  int koinDidapat = 0,
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
  // Info member & koin (Opsi B) — ikut PWA.
  if (memberName != null && memberName.isNotEmpty) {
    b.writeln('-' * w);
    b.writeln(center('Member: $memberName'));
    if (memberCode != null && memberCode.isNotEmpty) {
      b.writeln(center('($memberCode)'));
    }
  }
  if (koinDipakai > 0) {
    b.writeln(row(
        'Koin dipakai: $koinDipakai',
        '(-${formatRp(koinDipakai)})'));
  }
  if (koinDidapat > 0) {
    b.writeln(row('Koin didapat:', '$koinDidapat'));
  }
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
  bool _pakaiKoin = false;
  int _saldoKoin = 0;

  @override
  void dispose() {
    _received.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Muat saldo koin member terkini (untuk toggle Pakai Koin).
    final member = ref.read(posMemberProvider);
    if (member != null) {
      _saldoKoin = member.coins;
      // Refresh dari DB agar tidak basi.
      ref
          .read(adminRepositoryProvider)
          .findCustomerByMemberCode(member.kodeMember)
          .then((c) {
        if (mounted && c != null) {
          setState(() => _saldoKoin = c.coins);
        }
      });
    }
  }

  int get _total => ref.read(posCartProvider.notifier).total;

  /// Koin maksimal yang bisa dipakai = min(saldo, total × redeemLimit%).
  /// Ikut aturan yang sama dengan belanja online.
  int _koinMaksimal(int total) {
    final settings =
        ref.read(coinSettingsProvider).valueOrNull ??
            const CoinSettings();
    if (!settings.enabled || _saldoKoin <= 0) return 0;
    final maksimal = (total * settings.redeemLimit ~/ 100);
    return _saldoKoin < maksimal ? _saldoKoin : maksimal;
  }

  /// Koin yang dipakai (0 jika toggle mati).
  int _koinDipakai(int total) =>
      _pakaiKoin ? _koinMaksimal(total) : 0;

  /// Total setelah potongan koin (1 koin = Rp1, ikut coinRate).
  int _totalSetelahKoin(int total) {
    final settings =
        ref.read(coinSettingsProvider).valueOrNull ??
            const CoinSettings();
    return total - (_koinDipakai(total) * settings.coinRate);
  }

  /// Koin yang akan didapat dari belanja ini.
  int _koinDidapat(int total) {
    final settings =
        ref.read(coinSettingsProvider).valueOrNull ??
            const CoinSettings();
    if (!settings.enabled || total <= 0) return 0;
    return (total ~/ settings.spendRule) *
        settings.spendReward;
  }

  int get _receivedInt =>
      int.tryParse(_received.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final lines = ref.watch(posCartProvider);
    // Total yang harus dibayar (setelah potongan koin jika dipakai).
    final totalBayar = _totalSetelahKoin(_total);
    final change = kembalian(_receivedInt, totalBayar);
    final canPay = _doneCode == null &&
        lines.isNotEmpty &&
        _receivedInt >= totalBayar &&
        totalBayar > 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          // Warna dari bottomSheetTheme (adaptif terang/gelap).
          color: Theme.of(context).bottomSheetTheme.backgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
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
        _rincianTotal(),
        const SizedBox(height: 16),
        // Toggle Pakai Koin — hanya jika ada member aktif.
        _koinToggle(),
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

  /// Rincian total: tampilkan potongan koin jika dipakai.
  Widget _rincianTotal() {
    final total = _total;
    final koinDipakai = _koinDipakai(total);
    final settings =
        ref.watch(coinSettingsProvider).valueOrNull ??
            const CoinSettings();
    final potongan = koinDipakai * settings.coinRate;
    final totalBayar = total - potongan;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(Strings.totalBayar,
                style: TextStyle(color: context.teksRedup)),
            Text(
              formatRp(total),
              style: TextStyle(
                color: context.teksRedup,
                fontSize: koinDipakai > 0 ? 14 : 24,
                fontWeight: FontWeight.w800,
                decoration: koinDipakai > 0
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ],
        ),
        if (koinDipakai > 0) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Potongan koin ($koinDipakai)',
                  style: TextStyle(
                      color: context.teksRedup, fontSize: 13)),
              Text('-${formatRp(potongan)}',
                  style: const TextStyle(
                      color: AppColors.ok,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total bayar',
                  style: TextStyle(
                      color: context.teksUtama,
                      fontWeight: FontWeight.w700)),
              Text(
                formatRp(totalBayar),
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Toggle "Pakai Koin" — tampil hanya jika ada member + saldo > 0.
  /// Switch ON = pakai MAKSIMAL yang diizinkan (tanpa konfirmasi tambahan).
  Widget _koinToggle() {
    final member = ref.watch(posMemberProvider);
    if (member == null) return const SizedBox.shrink();
    final settings =
        ref.watch(coinSettingsProvider).valueOrNull ??
            const CoinSettings();
    if (!settings.enabled || _saldoKoin <= 0) {
      return const SizedBox.shrink();
    }
    final maksimal = _koinMaksimal(_total);
    if (maksimal <= 0) return const SizedBox.shrink();
    final potongan = maksimal * settings.coinRate;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0A0908)
            : const Color(0xFFFFF0C8),
        border: Border.all(
            color: isDark
                ? AppColors.orange.withValues(alpha: 0.5)
                : const Color(0xFFECCB9E)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.monetization_on,
              color: Color(0xFF8B5910)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pakai Koin',
                    style:
                        TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  'Pakai $maksimal koin (${formatRp(potongan)})',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B5910)),
                ),
                Text(
                  'Saldo: $_saldoKoin koin',
                  style: TextStyle(
                      fontSize: 11,
                      color: context.teksRedup),
                ),
              ],
            ),
          ),
          Switch(
            value: _pakaiKoin,
            onChanged: (v) =>
                setState(() => _pakaiKoin = v),
            activeThumbColor: AppColors.orange,
          ),
        ],
      ),
    );
  }

  Future<void> _pay() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final lines = ref.read(posCartProvider).toList();
      final received = _receivedInt;
      final total = _total;
      final member = ref.read(posMemberProvider);
      // Koin: hitung sebelum bayar.
      final koinDipakai = _koinDipakai(total);
      final totalBayar = _totalSetelahKoin(total);
      final koinDidapat =
          member != null ? _koinDidapat(total) : 0;
      final items = lines
          .map((l) => OrderItem(
                productId: l.product.id,
                name: l.product.name,
                qty: l.qty,
                price: l.product.price,
              ))
          .toList();
      // 1. Tukar koin dulu (jika dipakai) — potong saldo + beban promosi.
      if (member != null && koinDipakai > 0) {
        await repo.adjustCoins(
            member.uid, -koinDipakai, 'tukar');
      }
      // 2. Catat penjualan (total setelah potongan koin).
      final code = await repo.recordCashSale(
        items: items,
        total: totalBayar,
        received: received,
        customerId: member?.uid,
        customerName: member?.name,
      );
      // 3. Beri koin perolehan (otomatis, ikut aturan spendRule).
      if (member != null && koinDidapat > 0) {
        await repo.adjustCoins(
            member.uid, koinDidapat, 'belanja');
      }
      // Salinan untuk struk (keranjang dikosongkan setelahnya).
      _lastLines = lines;
      _lastTotal = totalBayar;
      _lastReceived = received;
      _lastKoinDipakai = koinDipakai;
      _lastKoinDidapat = koinDidapat;
      _lastMember = member;
      // Simpan struk terakhir — bisa dibuka ulang dari modul Struk.
      final struk = buildReceipt(
        storeName: Strings.appName,
        code: code,
        date: DateTime.now(),
        lines: lines,
        total: totalBayar,
        received: received,
        memberName: member?.name,
        memberCode: member?.kodeMember,
        koinDipakai: koinDipakai,
        koinDidapat: koinDidapat,
      );
      unawaited(simpanStrukTerakhir(struk));
      ref.read(posCartProvider.notifier).clear();
      // Reset member setelah transaksi selesai.
      ref.read(posMemberProvider.notifier).state = null;
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
              memberName: _lastMember?.name,
              memberCode: _lastMember?.kodeMember,
              koinDipakai: _lastKoinDipakai,
              koinDidapat: _lastKoinDidapat,
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
  int _lastKoinDipakai = 0;
  int _lastKoinDidapat = 0;
  Customer? _lastMember;
}
