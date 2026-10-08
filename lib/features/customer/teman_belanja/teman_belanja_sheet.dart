import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/store_repository.dart';

/// Teman Belanja — asisten belanja ala PWA (FAB kotak hitam + panel).
/// Jawaban dihitung dari data produk real-time, tanpa angka siluman.
Future<void> showTemanBelanjaSheet(
    BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _TemanBelanjaPanel(),
  );
}

class _TemanBelanjaPanel extends ConsumerStatefulWidget {
  const _TemanBelanjaPanel();

  @override
  ConsumerState<_TemanBelanjaPanel> createState() =>
      _TemanBelanjaPanelState();
}

class _TemanBelanjaPanelState extends ConsumerState<_TemanBelanjaPanel> {
  String _message = 'Halo! Mau cari barang apa hari ini?';

  void _jawab(String kunci) {
    final products =
        ref.read(productsProvider).valueOrNull ?? const <Product>[];
    final aktif = products.where((p) => p.stock > 0).toList();
    String balasan;
    switch (kunci) {
      case 'minyak':
        Product? minyak;
        for (final p in aktif) {
          if (p.name.toLowerCase().contains('minyak')) {
            minyak = p;
            break;
          }
        }
        minyak ??= () {
          for (final p in products) {
            if (p.name.toLowerCase().contains('minyak')) return p;
          }
          return null;
        }();
        balasan = minyak == null
            ? 'Minyak goreng belum ada di Data Produk.'
            : '${minyak.name} tersedia ${minyak.stock} ${minyak.unit}, '
                'harganya ${formatRp(minyak.price)}.';
      case 'murah':
        if (aktif.isEmpty) {
          balasan = 'Belum ada produk untuk dibandingkan.';
        } else {
          final termurah = aktif.reduce(
              (a, b) => a.price <= b.price ? a : b);
          final snack = aktif
              .where((p) =>
                  p.category.toLowerCase().contains('snack'))
              .toList();
          balasan = '${termurah.name} paling murah saat ini, '
              '${formatRp(termurah.price)}.';
          if (snack.isNotEmpty) {
            final s = snack
                .reduce((a, b) => a.price <= b.price ? a : b);
            balasan += ' Untuk kategori snack, ${s.name} '
                '${formatRp(s.price)}.';
          }
        }
      case 'promo':
      default:
        final promos =
            ref.read(promosProvider).valueOrNull ?? const [];
        final aktif2 =
            promos.where((p) => p.isActive).toList();
        balasan = aktif2.isEmpty
            ? 'Belum ada promo aktif saat ini.'
            : '${aktif2.length} promo aktif, contoh: ${aktif2.first.title}.';
    }
    setState(() => _message = balasan);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.orange),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Teman Belanja',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                  Text('Tanya stok dan harga cepat',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.panel2
                  : AppColors.paper,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_message, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _chip('Stok minyak?', () => _jawab('minyak')),
              _chip('Camilan termurah', () => _jawab('murah')),
              _chip('Ada promo?', () => _jawab('promo')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
    );
  }
}
