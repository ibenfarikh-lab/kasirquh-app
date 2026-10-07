import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/product.dart';
import '../../../data/models/stock_note.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../l10n/strings_id.dart';

/// Saran harga jual: modal +25%, dibulatkan KE ATAS ke kelipatan Rp500.
/// Contoh: 8000 -> 10000 -> 10000; 8300 -> 10375 -> 10500.
int saranHargaJual(int modalPcs) {
  final s = (modalPcs * 1.25).ceil();
  return ((s + 499) ~/ 500) * 500;
}

class _BelanjaRow {
  bool dibeli = false;
  bool pakaiBaru = true;
  final TextEditingController qty = TextEditingController();
  final TextEditingController isi = TextEditingController();
  final TextEditingController hargaKemasan = TextEditingController();
  final TextEditingController hargaJual = TextEditingController();

  void dispose() {
    qty.dispose();
    isi.dispose();
    hargaKemasan.dispose();
    hargaJual.dispose();
  }
}

int _parseAngka(TextEditingController c) =>
    int.tryParse(c.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

class StockShoppingSheet extends ConsumerStatefulWidget {
  const StockShoppingSheet({super.key});

  @override
  ConsumerState<StockShoppingSheet> createState() => _StockShoppingSheetState();
}

class _StockShoppingSheetState extends ConsumerState<StockShoppingSheet> {
  final Map<String, _BelanjaRow> _rows = {};
  final TextEditingController _supplier = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _supplier.dispose();
    for (final r in _rows.values) {
      r.dispose();
    }
    super.dispose();
  }

  /// Sinkronisasi baris dengan daftar produk stok menipis terbaru.
  void _sinkronRows(List<Product> products, int batas) {
    final ids = products.map((p) => p.id).toSet();
    for (final id in _rows.keys.toList()) {
      if (!ids.contains(id)) {
        _rows[id]!.dispose();
        _rows.remove(id);
      }
    }
    for (final p in products) {
      final row = _rows.putIfAbsent(p.id, () => _BelanjaRow());
      if (row.qty.text.isEmpty) {
        final saranQty = (batas * 2 - p.stock).clamp(1.0, 1048576.0);
        row.qty.text = formatStok(saranQty);
        row.isi.text = '1';
        row.hargaJual.text =
            (p.price > 0 ? p.price : saranHargaJual(p.cost)).toString();
      }
    }
  }

  Future<void> _simpan(List<Product> products) async {
    final repo = ref.read(adminRepositoryProvider);
    final dipilih = <Product, _BelanjaRow>{};
    for (final p in products) {
      final row = _rows[p.id];
      if (row == null || !row.dibeli) continue;
      final qty = parseDesimal(row.qty.text);
      final isi = parseDesimal(row.isi.text);
      final hargaKemasan = _parseAngka(row.hargaKemasan);
      if (qty <= 0 || isi <= 0 || hargaKemasan <= 0) continue;
      dipilih[p] = row;
    }
    if (dipilih.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.perluDikulak)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final items = <StockNoteItem>[];
      var tunai = 0.0; // UANG NYATA yang dibayar = Σ(qty kemasan × harga kemasan).
      for (final e in dipilih.entries) {
        final p = e.key;
        final row = e.value;
        final qty = parseDesimal(row.qty.text);
        final isi = parseDesimal(row.isi.text);
        final hargaKemasan = _parseAngka(row.hargaKemasan);
        final hargaJual = _parseAngka(row.hargaJual);
        // Harga jual wajib > 0: produk Rp0 = dijual gratis di kasir.
        if (hargaJual <= 0) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${Strings.hargaJualNol}: ${p.name}')),
          );
          setState(() => _saving = false);
          return;
        }
        final modalPcsBaru = (hargaKemasan / isi).round();
        final qtyTotal = qty * isi;
        final costAkhir = row.pakaiBaru
            ? modalPcsBaru
            : ((p.cost * p.stock + modalPcsBaru * qtyTotal) /
                    (p.stock + qtyTotal))
                .round();
        await repo.adjustStock(p.id, qtyTotal, costPrice: costAkhir);
        await repo.saveProduct(
          id: p.id,
          name: p.name,
          category: p.category,
          price: hargaJual,
          cost: costAkhir,
          stock: p.stock + qtyTotal,
          barcode: p.barcode,
          active: p.active,
        );
        // Arsip nota = struk nyata: jumlah kemasan × harga kemasan.
        // (modal/pcs adalah ekonomi satuan, tersimpan di produk.)
        items.add(StockNoteItem(
            name: p.name, qty: qty, price: hargaKemasan));
        tunai += qty * hargaKemasan;
      }

      final supplier =
          _supplier.text.trim().isEmpty ? 'Supplier' : _supplier.text.trim();
      final now = DateTime.now();
      final note = StockNote(
        id: '',
        date:
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        supplier: supplier,
        items: items,
        total: tunai.round(),
        source: 'belanja_stok',
        createdAt: now,
      );
      final noteId = await repo.saveStockNote(note);
      await repo.addJournal(
        kind: 'kulakan',
        label: 'Kulakan · $supplier',
        amount: -tunai.round(),
        refId: noteId,
      );
      // Modal sebagai delta antrean: tidak dilewati diam-diam saat offline.
      await repo.adjustModal(-tunai.round());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.belanjaTersimpan)),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.butuhInternetAdmin)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(lowStockProductsProvider);
    final storeInfo = ref.watch(storeInfoProvider).valueOrNull;
    final batas = storeInfo?.lowStockDefault ?? 5;
    _sinkronRows(products, batas);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            // Aturan 1&3: ikut bottomSheetTheme (adaptif).
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
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
                Strings.modulBelanjaStok,
                style: TextStyle(
                  color: context.teksUtama,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _supplier,
                style: TextStyle(color: context.teksUtama),
                decoration: _dekorasi('Supplier'),
              ),
              const SizedBox(height: 20),
              Text(
                Strings.perluDikulak,
                style: TextStyle(
                  color: context.teksRedup,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (products.isEmpty)
                EmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: Strings.tanpaSaran,
                )
              else ...[
                for (final p in products) _kartuProduk(p),
                const SizedBox(height: 8),
                AppButton(
                  label: Strings.simpanBelanja,
                  onPressed: _saving ? null : () => _simpan(products),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _kartuProduk(Product p) {
    final row = _rows[p.id]!;
    final hargaKemasan = _parseAngka(row.hargaKemasan);
    final isi = parseDesimal(row.isi.text);
    final saranQty = parseDesimal(row.qty.text);
    final modalPcs = isi > 0 ? (hargaKemasan / isi).round() : 0;

    return Card(
      // Aturan 3: kartu = L2.
      color: AppColors.panel,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          CheckboxListTile(
            value: row.dibeli,
            activeColor: AppColors.orange,
            checkColor: context.teksUtama,
            title: Text(
              p.name,
              style: TextStyle(
                color: context.teksUtama,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Stok ${formatStok(p.stock)} · ${Strings.saranJumlah}: ${formatStok(saranQty)}',
              style: TextStyle(color: context.teksRedup),
            ),
            onChanged: (v) => setState(() => row.dibeli = v ?? false),
          ),
          if (row.dibeli)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(color: AppColors.adminLine),
                  Row(
                    children: [
                      Expanded(
                        child: _fieldAngka(
                          row.qty,
                          'Jumlah beli',
                          onChanged: (_) => setState(() {}),
                          decimal: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _fieldAngka(
                          row.isi,
                          Strings.isiPerKemasan,
                          onChanged: (_) => setState(() {}),
                          decimal: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _fieldAngka(
                    row.hargaKemasan,
                    Strings.hargaPerKemasan,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${Strings.modalBaru}: ${modalPcs > 0 ? formatRp(modalPcs) : '-'}',
                    style: TextStyle(color: context.teksRedup),
                  ),
                  const SizedBox(height: 12),
                  _fieldAngka(row.hargaJual, Strings.hargaJualBaru,
                      onChanged: (_) => setState(() {})),
                  const SizedBox(height: 4),
                  RadioGroup<bool>(
                    groupValue: row.pakaiBaru,
                    onChanged: (v) =>
                        setState(() => row.pakaiBaru = v ?? true),
                    child: Column(
                      children: [
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Radio<bool>(value: true),
                          title: Text(
                            Strings.pakaiModalBaru,
                            style: TextStyle(color: context.teksUtama),
                          ),
                          onTap: () =>
                              setState(() => row.pakaiBaru = true),
                        ),
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Radio<bool>(value: false),
                          title: Text(
                            Strings.rataRataModal,
                            style: TextStyle(color: context.teksUtama),
                          ),
                          onTap: () =>
                              setState(() => row.pakaiBaru = false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _fieldAngka(
    TextEditingController c,
    String label, {
    ValueChanged<String>? onChanged,
    bool decimal = false,
  }) {
    return TextField(
      controller: c,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: decimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))]
          : [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(color: context.teksUtama),
      decoration: _dekorasi(label),
      onChanged: onChanged,
    );
  }

  InputDecoration _dekorasi(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: context.teksRedup),
      filled: true,
      fillColor: AppColors.panel2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.adminLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.orange),
      ),
    );
  }
}
