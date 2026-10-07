import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/product_photo.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../l10n/strings_id.dart';

/// Halaman Data Barang (Mode Admin): daftar produk + tambah/ubah/hapus.
class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.modulProduk)),
      body: const _ProductsBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.orange,
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  static void _openForm(BuildContext context, [Product? existing]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            // Aturan 3: sheet = L3.
            color: AppColors.panel2,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ProductFormSheet(
            existing: existing,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }
}

class _ProductsBody extends ConsumerStatefulWidget {
  const _ProductsBody();

  @override
  ConsumerState<_ProductsBody> createState() => _ProductsBodyState();
}

class _ProductsBodyState extends ConsumerState<_ProductsBody> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: Strings.cariBarang,
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        ),
        Expanded(
          child: productsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$e',
                    style: const TextStyle(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Coba lagi',
                    kind: AppButtonKind.secondary,
                    onPressed: () =>
                        ref.invalidate(adminProductsProvider),
                  ),
                ],
              ),
            ),
            data: (products) {
              final q = _query.toLowerCase();
              final filtered = products.where((p) {
                if (q.isEmpty) return true;
                final nameHit =
                    p.name.toLowerCase().contains(q);
                final barcodeHit =
                    (p.barcode ?? '').toLowerCase().contains(q);
                return nameHit || barcodeHit;
              }).toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: Strings.belumAdaProduk,
                    hint: Strings.cariBarang,
                  ),
                );
              }

              return ListView.builder(
                itemCount: filtered.length,
                padding: const EdgeInsets.only(
                    left: 16, right: 16, bottom: 88),
                itemBuilder: (context, i) {
                  final p = filtered[i];
                  return Card(
                    child: ListTile(
                      onTap: () =>
                          ProductsPage._openForm(context, p),
                      leading: ProductPhoto(
                        photoPath: p.photoPath,
                        size: 48,
                      ),
                      title: Text(
                        p.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.teksUtama,
                        ),
                      ),
                      subtitle: Text(
                        // formatRp SUDAH ber-prefix "Rp" — jangan tambah literal.
                        '${formatRp(p.price)} · stok ${formatStok(p.stock)} · ${p.category}',
                        style: TextStyle(
                            color: context.teksRedup),
                      ),
                      trailing: p.active
                          ? const Icon(Icons.chevron_right)
                          : Chip(
                              label: const Text(
                                  Strings.produkNonaktif),
                              backgroundColor: AppColors.danger
                                  .withValues(alpha: 0.15),
                              labelStyle: const TextStyle(
                                  color: AppColors.danger),
                            ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Formulir tambah/ubah produk dalam bottom sheet.
class ProductFormSheet extends ConsumerStatefulWidget {
  final Product? existing;
  final ScrollController scrollController;

  const ProductFormSheet({
    super.key,
    this.existing,
    required this.scrollController,
  });

  @override
  ConsumerState<ProductFormSheet> createState() =>
      _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<ProductFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _photoUrlCtrl;
  late bool _active;
  bool _saving = false;
  // Foto lokal per-perangkat (data URI) — dipilih dari HP, resize ≤300px.
  String? _localPhoto;
  bool _pickingPhoto = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _categoryCtrl = TextEditingController(text: p?.category ?? '');
    _priceCtrl = TextEditingController(
        text: p == null ? '' : p.price.toString());
    _costCtrl =
        TextEditingController(text: p == null ? '' : p.cost.toString());
    _stockCtrl = TextEditingController(
        text: p == null ? '' : formatStok(p.stock));
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    // URL online vs data URI dipisah: URL bisa diedit, data URI tidak.
    final existing = p?.photoPath ?? '';
    _photoUrlCtrl = TextEditingController(
        text: existing.startsWith('http') ? existing : '');
    if (existing.startsWith('data:image')) _localPhoto = existing;
    _active = p?.active ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _stockCtrl.dispose();
    _barcodeCtrl.dispose();
    _photoUrlCtrl.dispose();
    super.dispose();
  }

  int _parseDigits(String text) =>
      int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  /// Stok boleh desimal (cth. 3,75 kg) — terima koma maupun titik.
  double _parseDesimal(String text) {
    final t =
        text.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(t) ?? 0;
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Foto efektif: lokal (dari HP) menang atas URL online.
  String? get _photoPath {
    if (_localPhoto != null) return _localPhoto;
    final url = _photoUrlCtrl.text.trim();
    return url.isEmpty ? null : url;
  }

  Future<void> _pilihFotoDariHp() async {
    setState(() => _pickingPhoto = true);
    final uri = await pickProductPhoto();
    if (!mounted) return;
    setState(() => _pickingPhoto = false);
    if (uri == null) {
      _snack(Strings.fotoTidakTerbaca);
      return;
    }
    setState(() => _localPhoto = uri);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = _parseDigits(_priceCtrl.text);
    if (name.isEmpty || price <= 0 || _saving) return;
    setState(() => _saving = true);
    try {
      final barcode = _barcodeCtrl.text.trim();
      await ref.read(adminRepositoryProvider).saveProduct(
            id: widget.existing?.id,
            name: name,
            category: _categoryCtrl.text.trim(),
            price: price,
            cost: _parseDigits(_costCtrl.text),
            stock: _parseDesimal(_stockCtrl.text),
            barcode: barcode.isEmpty ? null : barcode,
            active: _active,
            photoPath: _photoPath,
          );
      if (!mounted) return;
      _snack(Strings.berhasilDisimpan);
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      _snack(Strings.butuhInternetAdmin);
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.existing?.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(Strings.hapusProdukTanya),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(Strings.batal),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(Strings.hapus),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(adminRepositoryProvider).deleteProduct(id);
      if (!mounted) return;
      _snack(Strings.berhasilDihapus);
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      _snack(Strings.butuhInternetAdmin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Text(
          isEdit ? Strings.ubahProduk : Strings.tambahProduk,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.teksUtama,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameCtrl,
          decoration:
              const InputDecoration(labelText: Strings.namaProduk),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _categoryCtrl,
          keyboardType: TextInputType.text,
          decoration:
              const InputDecoration(labelText: Strings.kategori),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _priceCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration:
              const InputDecoration(labelText: Strings.hargaJual),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _costCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration:
              const InputDecoration(labelText: Strings.hargaModal),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _stockCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))
          ],
          decoration: const InputDecoration(labelText: Strings.stok),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _barcodeCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
              labelText: Strings.barcodeOpsional),
        ),
        const SizedBox(height: 16),
        // Foto produk: pilih dari HP (lokal) atau tempel URL online.
        Text(
          Strings.fotoProduk,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: context.teksUtama,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductPhoto(photoPath: _photoPath, size: 84),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    icon: _pickingPhoto
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text(_pickingPhoto
                        ? Strings.mengirim
                        : Strings.pilihDariHp),
                    onPressed: _pickingPhoto ? null : _pilihFotoDariHp,
                  ),
                  if (_photoPath != null)
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text(Strings.hapusFoto),
                      onPressed: () => setState(() {
                        _localPhoto = null;
                        _photoUrlCtrl.clear();
                      }),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _photoUrlCtrl,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: Strings.fotoUrlLabel,
            hintText: Strings.fotoUrlHint,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text(Strings.tampilkanDiKatalog),
          value: _active,
          onChanged: (v) => setState(() => _active = v),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        AppButton(
          label: _saving ? Strings.menyimpan : Strings.simpan,
          fullWidth: true,
          onPressed: _saving ? null : _save,
        ),
        if (isEdit) ...[
          const SizedBox(height: 12),
          AppButton(
            label: Strings.hapus,
            kind: AppButtonKind.danger,
            fullWidth: true,
            onPressed: _delete,
          ),
        ],
      ],
    );
  }
}
