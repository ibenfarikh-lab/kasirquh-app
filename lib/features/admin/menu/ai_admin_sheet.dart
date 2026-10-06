import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/journal_entry.dart';
import '../../../data/models/order.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../l10n/strings_id.dart';

/// Satu saran berbasis data — ikon + teks. Fungsi pure di bawah.
class AiSaran {
  final IconData ikon;
  final String teks;
  const AiSaran(this.ikon, this.teks);
}

/// Hasilkan saran dari data lokal (tanpa backend AI).
/// Aturan jujur: hanya bicara berdasar data yang ada; tanpa data → saran
/// umum yang tidak mengklaim angka.
List<AiSaran> hasilkanSaran({
  required int omzetHariIni,
  required int transaksiHariIni,
  required int pesananMenunggu,
  required List<String> stokMenipis,
  required List<String> produkLaris,
}) {
  final saran = <AiSaran>[];
  if (pesananMenunggu > 0) {
    saran.add(AiSaran(
      Icons.shopping_bag_outlined,
      '$pesananMenunggu pesanan menunggu diproses di Kasir Online.',
    ));
  }
  if (stokMenipis.isNotEmpty) {
    final nama = stokMenipis.take(3).join(', ');
    final lebih = stokMenipis.length > 3
        ? ' (+${stokMenipis.length - 3} lainnya)'
        : '';
    saran.add(AiSaran(
      Icons.inventory_2_outlined,
      'Stok menipis: $nama$lebih. Pertimbangkan kulakan di Belanja Stok.',
    ));
  }
  if (produkLaris.isNotEmpty) {
    saran.add(AiSaran(
      Icons.trending_up_outlined,
      'Paling laris: ${produkLaris.first}. Pastikan stoknya aman.',
    ));
  }
  if (transaksiHariIni == 0) {
    saran.add(AiSaran(
      Icons.storefront_outlined,
      'Belum ada transaksi hari ini. Buka Kasir untuk mulai jualan.',
    ));
  } else if (omzetHariIni > 0) {
    saran.add(AiSaran(
      Icons.payments_outlined,
      'Omzet hari ini ${formatRp(omzetHariIni)} dari $transaksiHariIni transaksi. Pertahankan!',
    ));
  }
  return saran;
}

/// AI Admin — ringkasan & saran berbasis data lokal.
/// Bukan AI generatif: semua angka dari jurnal/pesanan/produk yang nyata.
class AiAdminSheet extends ConsumerWidget {
  const AiAdminSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(adminJournalProvider);
    final orders = ref.watch(adminOrdersProvider).valueOrNull ?? const [];
    final lowStock = ref.watch(lowStockProductsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.panel,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            const Row(
              children: [
                Icon(Icons.psychology_outlined,
                    color: AppColors.orange, size: 28),
                SizedBox(width: 10),
                Text(
                  'AI Admin',
                  style: TextStyle(
                    color: AppColors.warmText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Ringkasan & saran dari data tokomu. Tanpa data → tanpa klaim.',
              style: TextStyle(
                  color: AppColors.warmMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            journalAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.orange)),
              ),
              error: (_, __) => const EmptyState(
                icon: Icons.psychology_outlined,
                title: Strings.belumAdaData,
                hint: Strings.periksaKoneksi,
              ),
              data: (entries) =>
                  _isi(context, entries, orders, lowStock),
            ),
          ],
        ),
      ),
    );
  }

  Widget _isi(BuildContext context, List<JournalEntry> entries,
      List<Order> orders, List<Product> lowStock) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var omzet = 0;
    var transaksi = 0;
    for (final e in entries) {
      final c = e.createdAt;
      if (c.year == today.year &&
          c.month == today.month &&
          c.day == today.day &&
          e.amount > 0) {
        omzet += e.amount;
        transaksi++;
      }
    }
    final menunggu =
        orders.where((o) => o.status == OrderStatus.menunggu).length;
    final namaMenipis = lowStock.map((p) => p.name).toList();
    final laris = topProductsByQty(orders, limit: 3);
    // Nama produk laris dari orders (nama item, bukan id).
    final namaLaris = <String>[];
    for (final id in laris) {
      for (final o in orders) {
        final item = o.items.where((i) => i.productId == id);
        if (item.isNotEmpty) {
          namaLaris.add(item.first.name);
          break;
        }
      }
    }
    final saran = hasilkanSaran(
      omzetHariIni: omzet,
      transaksiHariIni: transaksi,
      pesananMenunggu: menunggu,
      stokMenipis: namaMenipis,
      produkLaris: namaLaris,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan hari ini',
          style: TextStyle(
            color: AppColors.warmText,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ringkasanCard(
                  'Omzet',
                  transaksi > 0
                      ? formatRp(omzet)
                      : 'Belum ada'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ringkasanCard(
                  'Transaksi',
                  transaksi > 0 ? '$transaksi' : 'Belum ada'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Saran',
          style: TextStyle(
            color: AppColors.warmText,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        if (saran.isEmpty)
          const EmptyState(
            icon: Icons.psychology_outlined,
            title: Strings.belumAdaData,
          )
        else
          for (final s in saran)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(s.ikon,
                        color: AppColors.orange, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.teks,
                        style: const TextStyle(
                          color: AppColors.warmText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _ringkasanCard(String label, String value) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                color: AppColors.warmMuted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.warmText,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
