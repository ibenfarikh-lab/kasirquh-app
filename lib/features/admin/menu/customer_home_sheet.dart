import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/recipe.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../l10n/strings_id.dart';

/// Pusat Kendali Beranda — selaras PWA `homeControlModal` (index.html:168).
/// Admin mengatur konten Beranda pelanggan: promo, info & kabar, slide
/// gateway, bagian Beranda (tampil/sembunyi + urutan), promo carousel,
/// dan Ide Masak. Perubahan berlaku langsung (live via Firestore).
class CustomerHomeSheet extends ConsumerWidget {
  const CustomerHomeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              // Header ala PWA: kicker + judul + tombol tutup.
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Toko',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.08,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pusat Kendali Beranda',
                          style: TextStyle(
                            color: context.teksUtama,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: context.teksRedup,
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Intro ala PWA.
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.permukaanKartu,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.garis),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.home_outlined,
                        color: AppColors.orange, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kendali Beranda pelanggan',
                            style: TextStyle(
                              color: context.teksUtama,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Perubahan berlaku langsung.',
                            style: TextStyle(
                                color: context.teksRedup, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _KendaliFormSection(),
              const SizedBox(height: 20),
              const _SectionOrderSection(),
              const SizedBox(height: 20),
              const _PromoCarouselSection(),
              const SizedBox(height: 20),
              const _IdeMasakSection(),
              const SizedBox(height: 20),
              const _PaketSection(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

/// Form utama: info & kabar, slide gateway, promo pilihan, promo kilat.
/// Disimpan sekaligus via tombol "Terapkan ke Beranda" (ala PWA).
class _KendaliFormSection extends ConsumerStatefulWidget {
  const _KendaliFormSection();

  @override
  ConsumerState<_KendaliFormSection> createState() =>
      _KendaliFormSectionState();
}

class _KendaliFormSectionState extends ConsumerState<_KendaliFormSection> {
  final _info = TextEditingController();
  final _gwT1 = TextEditingController();
  final _gwC1 = TextEditingController();
  final _gwT2 = TextEditingController();
  final _gwC2 = TextEditingController();
  final _gwT3 = TextEditingController();
  final _gwC3 = TextEditingController();
  final _promoTitle = TextEditingController();
  final _flashPrice = TextEditingController();
  final _flashRule = TextEditingController();
  final _kabarStatus = TextEditingController();
  final _kabarMood = TextEditingController();
  String? _promoProductId;
  String? _flashProductId;
  bool _terisi = false;
  bool _menyimpan = false;

  @override
  void dispose() {
    _info.dispose();
    _gwT1.dispose();
    _gwC1.dispose();
    _gwT2.dispose();
    _gwC2.dispose();
    _gwT3.dispose();
    _gwC3.dispose();
    _promoTitle.dispose();
    _flashPrice.dispose();
    _flashRule.dispose();
    _kabarStatus.dispose();
    _kabarMood.dispose();
    super.dispose();
  }

  void _prefill(StoreInfo s) {
    _info.text = s.runningText ?? '';
    _gwT1.text = s.gatewayTitle1;
    _gwC1.text = s.gatewayCopy1;
    _gwT2.text = s.gatewayTitle2;
    _gwC2.text = s.gatewayCopy2;
    _gwT3.text = s.gatewayTitle3;
    _gwC3.text = s.gatewayCopy3;
    _promoTitle.text = s.promoTitle ?? '';
    _promoProductId = s.promoProductId;
    _flashProductId = s.flashProductId;
    _flashPrice.text = s.flashPrice > 0 ? s.flashPrice.toString() : '';
    _flashRule.text = s.flashRule ?? '';
    _kabarStatus.text = s.kabarStatus ?? '';
    _kabarMood.text = s.kabarMood ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeInfoProvider).valueOrNull;
    if (!_terisi && store != null) {
      _prefill(store);
      _terisi = true;
    }
    final products =
        ref.watch(adminProductsProvider).valueOrNull ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _blockTitle(context, 'Promo, info & kabar'),
        const SizedBox(height: 8),
        _field(context, _info, 'Info toko & teks berjalan', maxLines: 2),
        const SizedBox(height: 12),
        _slideFields(context, 'Slide 1 · Promo utama', _gwT1, _gwC1),
        const SizedBox(height: 12),
        _slideFields(context, 'Slide 2 · Sembako', _gwT2, _gwC2),
        const SizedBox(height: 12),
        _slideFields(context, 'Slide 3 · Jajan & minuman', _gwT3, _gwC3),
        const SizedBox(height: 12),
        _productDropdown(
          context,
          label: 'Produk promo',
          value: _promoProductId,
          products: products,
          onChanged: (v) => setState(() => _promoProductId = v),
        ),
        const SizedBox(height: 12),
        _field(context, _promoTitle, 'Judul promo'),
        const SizedBox(height: 12),
        _productDropdown(
          context,
          label: 'Produk promo kilat',
          value: _flashProductId,
          products: products,
          onChanged: (v) => setState(() => _flashProductId = v),
        ),
        const SizedBox(height: 12),
        _field(context, _flashPrice, 'Harga kilat',
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _field(context, _flashRule, 'Batas & pesan promo kilat',
            maxLines: 2),
        const SizedBox(height: 12),
        _field(context, _kabarStatus, 'Kabar status'),
        const SizedBox(height: 12),
        _field(context, _kabarMood, 'Kabar suasana', maxLines: 2),
        const SizedBox(height: 16),
        AppButton(
          label: 'Terapkan ke Beranda',
          onPressed: _menyimpan ? null : () => _simpan(context, products),
        ),
      ],
    );
  }

  Future<void> _simpan(BuildContext context, List products) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _menyimpan = true);
    try {
      String? promoCopy;
      if (_promoProductId != null && _promoProductId!.isNotEmpty) {
        String nama = '';
        for (final e in products) {
          if ((e.id as String) == _promoProductId) {
            nama = e.name as String;
            break;
          }
        }
        promoCopy =
            nama.isNotEmpty ? '$nama dipilih sebagai promo utama toko.' : '';
      }
      final patch = <String, dynamic>{
        'runningText': _info.text.trim(),
        'gatewayTitle1': _gwT1.text.trim(),
        'gatewayCopy1': _gwC1.text.trim(),
        'gatewayTitle2': _gwT2.text.trim(),
        'gatewayCopy2': _gwC2.text.trim(),
        'gatewayTitle3': _gwT3.text.trim(),
        'gatewayCopy3': _gwC3.text.trim(),
        'promoTitle': _promoTitle.text.trim(),
        'promoProductId':
            (_promoProductId ?? '').isEmpty ? null : _promoProductId,
        'promoCopy': promoCopy ?? '',
        'flashProductId':
            (_flashProductId ?? '').isEmpty ? null : _flashProductId,
        'flashPrice': int.tryParse(_flashPrice.text.trim()) ?? 0,
        'flashRule': _flashRule.text.trim(),
        'kabarStatus': _kabarStatus.text.trim(),
        'kabarMood': _kabarMood.text.trim(),
      };
      await ref.read(adminRepositoryProvider).saveStoreSettings(patch);
      messenger.showSnackBar(
        const SnackBar(content: Text('Beranda pelanggan disimpan')),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(Strings.butuhInternetAdmin)),
      );
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }
}

/// Blok "Bagian Beranda": toggle tampil/sembunyi + urutan per section.
/// Disimpan langsung (ala PWA).
class _SectionOrderSection extends ConsumerWidget {
  const _SectionOrderSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeInfoProvider).valueOrNull;
    final sections = store?.homeSections ?? const {};

    HomeSectionConfig cfg(String key, int defOrder) =>
        sections[key] ?? HomeSectionConfig(order: defOrder);

    Future<void> simpan(String key, bool show, int order) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        final next = <String, dynamic>{};
        sections.forEach((k, v) => next[k] = v.toMap());
        next[key] = {'show': show, 'order': order};
        await ref
            .read(adminRepositoryProvider)
            .saveStoreSettings({'homeSections': next});
      } catch (_) {
        messenger.showSnackBar(
          SnackBar(content: Text(Strings.butuhInternetAdmin)),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _blockTitle(context, 'Bagian Beranda'),
        const SizedBox(height: 8),
        _sectionRow(
          context,
          title: 'Stok Rumah Habis',
          subtitle: 'Otomatis dari riwayat belanja pelanggan',
          config: cfg('restock', 1),
          onChanged: (show, order) => simpan('restock', show, order),
        ),
        _sectionRow(
          context,
          title: 'Ide Masak Warga',
          subtitle: 'Kelola resep dan daftar bahan yang tampil',
          config: cfg('recipe', 2),
          onChanged: (show, order) => simpan('recipe', show, order),
        ),
        _sectionRow(
          context,
          title: 'Sedang Laris',
          subtitle: '8 teratas dari transaksi seluruh pelanggan',
          config: cfg('popular', 3),
          onChanged: (show, order) => simpan('popular', show, order),
        ),
      ],
    );
  }
}

/// Blok "Promo Carousel": tambah promo (judul + isi + badge) + daftar.
class _PromoCarouselSection extends ConsumerWidget {
  const _PromoCarouselSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(adminPromosProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _blockTitle(context, 'Promo Carousel'),
        const SizedBox(height: 8),
        promosAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (promos) {
            if (promos.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Belum ada promo carousel.',
                  style: TextStyle(color: context.teksRedup),
                ),
              );
            }
            return Column(
              children: [for (final p in promos) _PromoTile(promo: p)],
            );
          },
        ),
        const SizedBox(height: 8),
        AppButton(
          label: '+ Tambah promo',
          onPressed: () => _tambahPromoDialog(context, ref),
        ),
      ],
    );
  }

  Future<void> _tambahPromoDialog(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final judul = TextEditingController();
    final isi = TextEditingController();
    final badge = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text('Tambah promo', style: TextStyle(color: context.teksUtama)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: judul,
              autofocus: true,
              maxLength: 64,
              style: TextStyle(color: context.teksUtama),
              decoration: _dekorasi(context, 'Judul promo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: isi,
              maxLength: 110,
              maxLines: 2,
              style: TextStyle(color: context.teksUtama),
              decoration: _dekorasi(context, 'Isi promo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: badge,
              maxLength: 12,
              style: TextStyle(color: context.teksUtama),
              decoration: _dekorasi(context, 'Label badge (cth: PROMO)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(Strings.batal,
                style: TextStyle(color: context.teksRedup)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(Strings.simpan,
                style: TextStyle(color: AppColors.orange)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final t = judul.text.trim();
    if (t.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Isi judul promo dulu')),
      );
      return;
    }
    try {
      await ref.read(adminRepositoryProvider).savePromo({
        'title': t,
        'copy': isi.text.trim(),
        'badge': badge.text.trim().isEmpty ? 'PROMO' : badge.text.trim(),
        'isActive': true,
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Promo ditambahkan ke carousel')),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(Strings.butuhInternetAdmin)),
      );
    }
  }
}

/// Blok "Ide Masak": daftar resep + batas 5 + tambah/ubah/hapus.
class _IdeMasakSection extends ConsumerWidget {
  const _IdeMasakSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _blockTitle(context, 'Ide Masak'),
        const SizedBox(height: 8),
        recipesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (recipes) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (recipes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Belum ada resep warga.',
                      style: TextStyle(color: context.teksRedup),
                    ),
                  )
                else
                  for (final r in recipes) _RecipeTile(recipe: r),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${recipes.length} dari maksimal 5 resep',
                        style: TextStyle(
                            color: context.teksRedup, fontSize: 12),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: recipes.length >= 5
                          ? null
                          : () => _resepDialog(context, ref, null),
                      icon: const Icon(Icons.add,
                          size: 16, color: AppColors.orange),
                      label: const Text('+ Tambah resep',
                          style: TextStyle(color: AppColors.orange)),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _resepDialog(
      BuildContext context, WidgetRef ref, Recipe? existing) async {
    final messenger = ScaffoldMessenger.of(context);
    final nama = TextEditingController(text: existing?.nama ?? '');
    final desc = TextEditingController(text: existing?.desc ?? '');
    final products =
        ref.read(adminProductsProvider).valueOrNull ?? const [];
    final bahan = <Map<String, dynamic>>[
      for (final it in (existing?.items ?? const <RecipeItem>[]))
        {'productId': it.productId, 'qty': it.qty},
    ];
    if (bahan.isEmpty) bahan.add({'productId': '', 'qty': 1});

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(
            existing == null ? 'Tambah resep' : 'Ubah resep',
            style: TextStyle(color: context.teksUtama),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nama,
                    autofocus: true,
                    maxLength: 54,
                    style: TextStyle(color: context.teksUtama),
                    decoration: _dekorasi(context, 'Nama resep'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: desc,
                    maxLength: 500,
                    maxLines: 3,
                    style: TextStyle(color: context.teksUtama),
                    decoration: _dekorasi(context, 'Deskripsi'),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bahan',
                      style: TextStyle(
                        color: context.teksRedup,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < bahan.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              initialValue:
                                  (bahan[i]['productId'] as String)
                                          .isEmpty
                                      ? null
                                      : bahan[i]['productId'] as String,
                              dropdownColor: context.permukaanKartu,
                              style:
                                  TextStyle(color: context.teksUtama),
                              decoration:
                                  _dekorasi(context, 'Produk'),
                              items: [
                                for (final p in products)
                                  DropdownMenuItem(
                                    value: p.id,
                                    child: Text(
                                      p.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (v) => setState(
                                  () => bahan[i]['productId'] = v ?? ''),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 64,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              style:
                                  TextStyle(color: context.teksUtama),
                              decoration:
                                  _dekorasi(context, 'Qty'),
                              controller: TextEditingController(
                                  text: '${bahan[i]['qty']}'),
                              onChanged: (v) => bahan[i]['qty'] =
                                  int.tryParse(v) ?? 1,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppColors.danger),
                            onPressed: bahan.length > 1
                                ? () => setState(
                                    () => bahan.removeAt(i))
                                : null,
                          ),
                        ],
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => setState(
                        () => bahan.add({'productId': '', 'qty': 1})),
                    icon: const Icon(Icons.add,
                        size: 16, color: AppColors.orange),
                    label: const Text('Tambah bahan',
                        style: TextStyle(color: AppColors.orange)),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(Strings.batal,
                  style: TextStyle(color: context.teksRedup)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(Strings.simpan,
                  style: TextStyle(color: AppColors.orange)),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final n = nama.text.trim();
    final items = bahan
        .where((b) => (b['productId'] as String).isNotEmpty)
        .map((b) => {
              'productId': b['productId'],
              'qty': (b['qty'] as int).clamp(1, 999),
            })
        .toList();
    if (n.isEmpty || items.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Lengkapi nama, deskripsi, dan bahan')),
      );
      return;
    }
    try {
      await ref.read(adminRepositoryProvider).saveRecipe(
        {
          'nama': n,
          'desc': desc.text.trim(),
          'foto': existing?.foto ?? '',
          'items': items,
        },
        id: existing?.id,
      );
      messenger.showSnackBar(
        SnackBar(
            content: Text(existing == null
                ? 'Resep ditambahkan ke Beranda pelanggan'
                : 'Resep diperbarui di Beranda pelanggan')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
            content: Text(e is StateError
                ? e.message
                : Strings.butuhInternetAdmin)),
      );
    }
  }
}

/// Tile promo carousel: judul + toggle aktif + hapus.
class _PromoTile extends ConsumerWidget {
  final Promo promo;

  const _PromoTile({required this.promo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          promo.title,
          style: TextStyle(
            color: context.teksUtama,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: (promo.subtitle ?? '').isNotEmpty
            ? Text(
                promo.subtitle!,
                style: TextStyle(color: context.teksRedup),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: promo.isActive,
              activeThumbColor: AppColors.orange,
              onChanged: (v) async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ref
                      .read(adminRepositoryProvider)
                      .savePromo({'isActive': v}, id: promo.id);
                } catch (_) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(Strings.butuhInternetAdmin)),
                  );
                }
              },
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: AppColors.danger),
              tooltip: 'Hapus promo',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(Strings.hapus,
                        style: TextStyle(color: context.teksUtama)),
                    content: Text(
                      'Hapus "${promo.title}" dari carousel?',
                      style: TextStyle(color: context.teksRedup),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(Strings.batal,
                            style:
                                TextStyle(color: context.teksRedup)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(Strings.hapus,
                            style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                );
                if (ok != true) return;
                try {
                  await ref
                      .read(adminRepositoryProvider)
                      .deletePromo(promo.id);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Promo dihapus')),
                  );
                } catch (_) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(Strings.butuhInternetAdmin)),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile resep: nama + jumlah bahan + ubah/hapus.
class _RecipeTile extends ConsumerWidget {
  final Recipe recipe;

  const _RecipeTile({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.image_outlined, color: AppColors.adminLine),
        title: Text(
          recipe.nama,
          style: TextStyle(
            color: context.teksUtama,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${recipe.items.length} bahan',
          style: TextStyle(color: context.teksRedup, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.orange),
              tooltip: 'Ubah resep',
              onPressed: () => const _IdeMasakSection()
                  ._resepDialog(context, ref, recipe),
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: AppColors.danger),
              tooltip: 'Hapus resep',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(Strings.hapus,
                        style: TextStyle(color: context.teksUtama)),
                    content: Text(
                      'Hapus "${recipe.nama}" dari Beranda pelanggan?',
                      style: TextStyle(color: context.teksRedup),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(Strings.batal,
                            style:
                                TextStyle(color: context.teksRedup)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(Strings.hapus,
                            style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                );
                if (ok != true) return;
                try {
                  await ref
                      .read(adminRepositoryProvider)
                      .deleteRecipe(recipe.id);
                  messenger.showSnackBar(
                    const SnackBar(
                        content:
                            Text('Resep dihapus dari Beranda pelanggan')),
                  );
                } catch (_) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(Strings.butuhInternetAdmin)),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Paket Tanggal Muda — section Beranda pelanggan yang diatur warung.
/// Mati = section disembunyikan (bukan contoh).
class _PaketSection extends ConsumerStatefulWidget {
  const _PaketSection();

  @override
  ConsumerState<_PaketSection> createState() => _PaketSectionState();
}

class _PaketSectionState extends ConsumerState<_PaketSection> {
  final _judul = TextEditingController();
  final _subjudul = TextEditingController();
  bool _terisi = false;
  bool _aktif = false;
  bool _menyimpan = false;

  @override
  void dispose() {
    _judul.dispose();
    _subjudul.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(storeInfoProvider).valueOrNull;
    if (!_terisi && info != null) {
      _judul.text = info.paketTitle ?? '';
      _subjudul.text = info.paketSubtitle ?? '';
      _aktif = info.paketEnabled;
      _terisi = true;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _blockTitle(context, 'Paket Tanggal Muda'),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Text(
            'Tampilkan di Beranda pelanggan',
            style: TextStyle(color: context.teksUtama),
          ),
          value: _aktif,
          activeThumbColor: AppColors.orange,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _aktif = v),
        ),
        TextField(
          controller: _judul,
          style: TextStyle(color: context.teksUtama),
          decoration: _dekorasi(context, 'Judul paket'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _subjudul,
          maxLines: 2,
          style: TextStyle(color: context.teksUtama),
          decoration: _dekorasi(context, 'Subjudul paket (opsional)'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            label: Strings.simpan,
            fullWidth: false,
            onPressed: _menyimpan
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _menyimpan = true);
                    try {
                      await ref
                          .read(adminRepositoryProvider)
                          .saveStoreSettings({
                        'paketEnabled': _aktif,
                        'paketTitle': _judul.text.trim(),
                        'paketSubtitle': _subjudul.text.trim(),
                      });
                      messenger.showSnackBar(
                        const SnackBar(
                            content: Text(Strings.berhasilDisimpan)),
                      );
                    } catch (_) {
                      messenger.showSnackBar(
                        const SnackBar(
                            content:
                                Text(Strings.butuhInternetAdmin)),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _menyimpan = false);
                      }
                    }
                  },
          ),
        ),
      ],
    );
  }
}

// ============ Widget bantu ============

Widget _blockTitle(BuildContext context, String title) {
  return Text(
    title,
    style: TextStyle(
      color: context.teksUtama,
      fontSize: 15,
      fontWeight: FontWeight.w800,
    ),
  );
}

Widget _field(
  BuildContext context,
  TextEditingController controller,
  String label, {
  int maxLines = 1,
  TextInputType? keyboardType,
}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    style: TextStyle(color: context.teksUtama),
    decoration: _dekorasi(context, label),
  );
}

Widget _slideFields(
  BuildContext context,
  String title,
  TextEditingController headline,
  TextEditingController subheadline,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          color: context.teksRedup,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: headline,
        maxLength: 64,
        style: TextStyle(color: context.teksUtama),
        decoration: _dekorasi(context, 'Headline'),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: subheadline,
        maxLength: 110,
        maxLines: 2,
        style: TextStyle(color: context.teksUtama),
        decoration: _dekorasi(context, 'Subheadline'),
      ),
    ],
  );
}

Widget _productDropdown(
  BuildContext context, {
  required String label,
  required String? value,
  required List products,
  required ValueChanged<String?> onChanged,
}) {
  return DropdownButtonFormField<String>(
    initialValue: (value ?? '').isEmpty ? null : value,
    dropdownColor: context.permukaanKartu,
    style: TextStyle(color: context.teksUtama),
    decoration: _dekorasi(context, label),
    items: [
      const DropdownMenuItem<String>(
        value: null,
        child: Text('— Tidak ada —'),
      ),
      for (final p in products)
        DropdownMenuItem<String>(
          value: p.id as String,
          child: Text(
            p.name as String,
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ],
    onChanged: onChanged,
  );
}

Widget _sectionRow(
  BuildContext context, {
  required String title,
  required String subtitle,
  required HomeSectionConfig config,
  required void Function(bool show, int order) onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.teksUtama,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style:
                    TextStyle(color: context.teksRedup, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Toggle TAMPIL/SEMBUNYI ala PWA.
        TextButton(
          onPressed: () => onChanged(!config.show, config.order),
          style: TextButton.styleFrom(
            backgroundColor: config.show
                ? AppColors.orange.withValues(alpha: 0.15)
                : context.permukaanKartu,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: config.show ? AppColors.orange : context.garis,
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text(
            config.show ? 'TAMPIL' : 'SEMBUNYI',
            style: TextStyle(
              color:
                  config.show ? AppColors.orange : context.teksRedup,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Dropdown urutan ala PWA.
        DropdownButton<int>(
          value: config.order.clamp(1, 3),
          dropdownColor: context.permukaanKartu,
          style: TextStyle(color: context.teksUtama, fontSize: 13),
          underline: const SizedBox.shrink(),
          items: const [
            DropdownMenuItem(value: 1, child: Text('Urut 1')),
            DropdownMenuItem(value: 2, child: Text('Urut 2')),
            DropdownMenuItem(value: 3, child: Text('Urut 3')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(config.show, v);
          },
        ),
      ],
    ),
  );
}

InputDecoration _dekorasi(BuildContext context, String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: context.teksRedup),
    filled: true,
    // Aturan 3: input = L3.
    fillColor: context.permukaanKartu, // Aturan 1&3: adaptif.
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
