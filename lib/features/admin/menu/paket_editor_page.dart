import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/paket_belanja.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/admin_repository.dart';

enum JenisPaket { rutin, hajatan }

class PaketEditorPage extends ConsumerStatefulWidget {
  final JenisPaket jenis;
  const PaketEditorPage({super.key, required this.jenis});

  @override
  ConsumerState<PaketEditorPage> createState() => _PaketEditorPageState();
}

class _PaketEditorPageState extends ConsumerState<PaketEditorPage> {
  final _nama = TextEditingController();
  final _deskripsi = TextEditingController();
  final List<PaketItem> _items = [];
  String? _editingId;
  String? _pilihProdukId;
  int _pilihQty = 1;

  bool get _isRutin => widget.jenis == JenisPaket.rutin;
  String get _judul => _isRutin ? 'Paket Rutin' : 'Paket Hajatan';

  StreamProvider<List<PaketBelanja>> get _provider =>
      _isRutin ? rutinPackagesProvider : hajatanPackagesProvider;

  @override
  void dispose() {
    _nama.dispose();
    _deskripsi.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _editingId = null;
      _items.clear();
      _nama.clear();
      _deskripsi.clear();
      _pilihProdukId = null;
      _pilihQty = 1;
    });
  }

  void _tambahItem(List<Product> products) {
    final pid = _pilihProdukId;
    if (pid == null || pid.isEmpty) return;
    if (_items.any((e) => e.productId == pid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk sudah ada di paket')),
      );
      return;
    }
    setState(() {
      _items.add(PaketItem(productId: pid, qty: _pilihQty.clamp(1, 999)));
      _pilihQty = 1;
    });
  }

  Future<void> _simpan() async {
    final nama = _nama.text.trim();
    if (nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nama paket')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 produk')),
      );
      return;
    }
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (_isRutin) {
        await repo.saveRutinPackage(
            _editingId, nama, _deskripsi.text.trim(), _items);
      } else {
        await repo.saveHajatanPackage(
            _editingId, nama, _deskripsi.text.trim(), _items);
      }
      _resetForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paket tersimpan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal simpan: $e')),
        );
      }
    }
  }

  void _edit(PaketBelanja p) {
    setState(() {
      _editingId = p.id;
      _nama.text = p.name;
      _deskripsi.text = p.description;
      _items
        ..clear()
        ..addAll(p.items
            .map((e) => PaketItem(productId: e.productId, qty: e.qty)));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit paket: ${p.name}')),
    );
  }

  Future<void> _hapus(PaketBelanja p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus paket ini?'),
        content: Text(p.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (_isRutin) {
        await repo.deleteRutinPackage(p.id);
      } else {
        await repo.deleteHajatanPackage(p.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paket dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal hapus: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paketAsync = ref.watch(_provider);
    final productsAsync = ref.watch(adminProductsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_judul)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _editingId == null ? 'Buat paket baru' : 'Ubah paket',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nama,
            decoration: const InputDecoration(
              labelText: 'Nama paket',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _deskripsi,
            decoration: const InputDecoration(
              labelText: 'Deskripsi (opsional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Produk dalam paket',
              style:
                  TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          if (_items.isEmpty)
            Text('Belum ada produk. Tambahkan di bawah.',
                style:
                    TextStyle(color: context.teksRedup))
          else
            ..._items.asMap().entries.map((e) {
              final i = e.key;
              final it = e.value;
              return productsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) =>
                    const SizedBox.shrink(),
                data: (products) {
                  final p = products
                      .where((x) => x.id == it.productId);
                  final nama =
                      p.isEmpty ? '?' : p.first.name;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(nama),
                    subtitle:
                        Text('Qty: ${it.qty}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.danger),
                      onPressed: () => setState(
                          () => _items.removeAt(i)),
                    ),
                  );
                },
              );
            }),
          const SizedBox(height: 8),
          productsAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator()),
            error: (_, __) => const Text(
                'Gagal muat produk'),
            data: (products) {
              final tersedia = products
                  .where((p) => p.stock > 0)
                  .toList()
                ..sort((a, b) =>
                    a.name.compareTo(b.name));
              if (_pilihProdukId != null &&
                  !tersedia.any(
                      (p) => p.id == _pilihProdukId)) {
                _pilihProdukId = null;
              }
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child:
                        DropdownButtonFormField<String>(
                      initialValue: _pilihProdukId,
                      decoration:
                          const InputDecoration(
                        labelText: 'Produk',
                        border:
                            OutlineInputBorder(),
                      ),
                      items: [
                        for (final p in tersedia)
                          DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              '${p.name} · ${formatRp(p.price)}',
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(
                          () => _pilihProdukId = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: '$_pilihQty',
                      keyboardType:
                          TextInputType.number,
                      decoration:
                          const InputDecoration(
                        labelText: 'Qty',
                        border:
                            OutlineInputBorder(),
                      ),
                      onChanged: (v) => _pilihQty =
                          int.tryParse(v) ?? 1,
                    ),
                  ),
                  IconButton.filled(
                    onPressed: () =>
                        _tambahItem(tersedia),
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          AppColors.orange,
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _simpan,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.black87,
                  ),
                  child: Text(_editingId == null
                      ? 'Simpan Paket'
                      : 'Simpan Perubahan'),
                ),
              ),
              if (_editingId != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _resetForm,
                  child: const Text('Batal'),
                ),
              ],
            ],
          ),
          const Divider(height: 32),
          const Text('Daftar paket',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          paketAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator()),
            error: (_, __) => const EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Gagal muat paket',
              hint: 'Periksa koneksi internet.',
            ),
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(
                  icon:
                      Icons.inventory_2_outlined,
                  title: 'Belum ada paket',
                  hint: 'Buat paket di atas.',
                );
              }
              return Column(
                children: [
                  for (final p in list)
                    Card(
                      child: ListTile(
                        title: Text(p.name,
                            style: const TextStyle(
                                fontWeight:
                                    FontWeight.w700)),
                        subtitle: Text(
                          '${p.description.isEmpty ? '' : '${p.description} · '}${p.items.length} produk',
                        ),
                        trailing: Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  _edit(p),
                              child:
                                  const Text('Ubah'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _hapus(p),
                              child: const Text('Hapus',
                                  style: TextStyle(
                                      color: AppColors
                                          .danger)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
