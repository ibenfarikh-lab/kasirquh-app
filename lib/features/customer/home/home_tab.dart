import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../l10n/strings_id.dart';
import '../customer_shell.dart';

/// Tab Beranda — konten dari pengaturan admin (store_settings) + promo.
/// Jujur: section yang tak ada datanya tidak ditampilkan (bukan contoh).
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeInfoProvider).valueOrNull ?? const StoreInfo();
    final promos = ref.watch(promosProvider).valueOrNull ?? const [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _promoSection(context, ref, promos),
        const SizedBox(height: 16),
        _quickCategories(context, ref),
        const SizedBox(height: 16),
        _storeInfoCard(store),
        if ((store.runningText ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          _runningTextCard(store.runningText!),
        ],
        const SizedBox(height: 24),
        const Center(
          child: Text(
            Strings.poweredBy,
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _promoSection(
      BuildContext context, WidgetRef ref, List<Promo> promos) {
    if (promos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          Strings.promoSpesial,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 132,
          child: PageView.builder(
            itemCount: promos.length,
            itemBuilder: (_, i) {
              final p = promos[i];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.ctaGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        p.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if ((p.subtitle ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          p.subtitle!,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _quickCategories(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          Strings.tabProduk,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in kProductCategories)
              ActionChip(
                label: Text(c),
                onPressed: () {
                  ref.read(catalogFilterProvider.notifier).state =
                      CatalogFilter(category: c);
                  ref.read(customerTabProvider.notifier).state = 1;
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _storeInfoCard(StoreInfo store) {
    final open = store.isOpenNow;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  Strings.infoToko,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              if (open != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (open ? AppColors.ok : AppColors.danger)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    open ? Strings.bukaSekarang : Strings.tutupSekarang,
                    style: TextStyle(
                      color: open ? AppColors.ok : AppColors.danger,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            store.storeName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          if ((store.infoText ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(store.infoText!,
                style: const TextStyle(color: AppColors.muted)),
          ],
          if ((store.address ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.muted),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(store.address!,
                        style: const TextStyle(color: AppColors.muted))),
              ],
            ),
          ],
          if ((store.phone ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_outlined,
                    size: 16, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(store.phone!,
                    style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ],
          if ((store.infoText ?? '').isEmpty &&
              (store.address ?? '').isEmpty &&
              (store.phone ?? '').isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Info toko belum diisi admin.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _runningTextCard(String text) {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.campaign_outlined, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

/// Filter katalog yang diminta dari Beranda (kategori cepat / pencarian).
class CatalogFilter {
  final String query;
  final String category;
  const CatalogFilter({this.query = '', this.category = ''});
}

final catalogFilterProvider =
    StateProvider<CatalogFilter>((ref) => const CatalogFilter());
