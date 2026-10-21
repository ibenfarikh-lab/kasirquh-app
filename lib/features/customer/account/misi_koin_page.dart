import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/social_repository.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../l10n/strings_id.dart';
import '../game/game_webview_page.dart';
import 'tebak_harga_page.dart';
import '../session.dart';

class Misi {
  final String id;
  final String judul;
  final String deskripsi;
  final int target;
  final int hadiahKoin;

  const Misi({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.target,
    required this.hadiahKoin,
  });
}

const kMisiList = [
  Misi(
    id: 'belanja_3x_minggu',
    judul: 'Belanja 3x seminggu',
    deskripsi: 'Selesaikan 3 pesanan dalam seminggu.',
    target: 3,
    hadiahKoin: 15,
  ),
  Misi(
    id: 'coba_produk_baru',
    judul: 'Coba produk baru',
    deskripsi: 'Beli produk yang belum pernah dibeli.',
    target: 1,
    hadiahKoin: 10,
  ),
];

DateTime _todayJakarta() =>
    DateTime.now().toUtc().add(const Duration(hours: 7));

String weekKeyOf(DateTime date) {
  var t = DateTime.utc(date.year, date.month, date.day);
  final dow = t.weekday - 1;
  t = t.add(Duration(days: -dow + 3));
  final first = DateTime.utc(t.year, 1, 4);
  final week = ((t.difference(first).inDays + 1) / 7).ceil();
  return '${t.year}-W${week.toString().padLeft(2, '0')}';
}

String claimKeyMisi(String misiId, DateTime now) {
  if (misiId == 'belanja_3x_minggu') {
    return 'misi_belanja3_${weekKeyOf(now)}';
  }
  return 'misi_coba_produk_baru';
}

String detailMisi(String misiId, DateTime now) {
  if (misiId == 'belanja_3x_minggu') {
    return 'Misi Belanja 3 kali · ${weekKeyOf(now)}';
  }
  return 'Misi Coba produk baru';
}

Map<String, int> misiProgress(List<Order> orders) {
  final now = DateTime.now();
  final mingguIni = orders
      .where((o) =>
          !o.createdAt.isAfter(now) &&
          now.difference(o.createdAt).inDays < 7)
      .length;
  int produkBaru = 0;
  if (orders.isNotEmpty) {
    final sorted = [...orders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final priorIds = <String>{
      for (final o in sorted.skip(1))
        for (final it in o.items) it.productId,
    };
    final latestIds =
        sorted.first.items.map((e) => e.productId).toSet();
    if (latestIds.any((id) => !priorIds.contains(id))) produkBaru = 1;
  }
  return {
    'belanja_3x_minggu': mingguIni,
    'coba_produk_baru': produkBaru,
  };
}

class MisiKoinPage extends ConsumerStatefulWidget {
  const MisiKoinPage({super.key});

  @override
  ConsumerState<MisiKoinPage> createState() => _MisiKoinPageState();
}

class _MisiKoinPageState extends ConsumerState<MisiKoinPage> {
  Set<String> _diminta = {};
  bool _memuat = true;
  bool _klaimBusy = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      _diminta = {};
      _memuat = false;
    });
  }

  Future<void> _mintaHadiah(
      BuildContext context, WidgetRef ref, Misi misi, String uid) async {
    if (_klaimBusy) return;
    setState(() => _klaimBusy = true);
    try {
      final settings = ref.read(coinSettingsProvider).valueOrNull ??
          const CoinSettings();
      final reward = settings.rewards['mission'] ?? misi.hadiahKoin;
      final now = _todayJakarta();

      await ref.read(adminRepositoryProvider).grantCoins(
            uid,
            reward,
            reason: 'misi',
            label: 'Hadiah misi',
            detail: detailMisi(misi.id, now),
            claimKey: claimKeyMisi(misi.id, now),
          );

      if (mounted) {
        setState(() {
          _diminta = {..._diminta, misi.id};
        });
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '+$reward koin dari misi "${misi.judul}"!')),
        );
      }
    } on StateError catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.butuhInternetUmum)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _klaimBusy = false);
      } else {
        _klaimBusy = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).valueOrNull;
    final uid = memberUid(session ?? const Session.guest());
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Misi koin')),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: Strings.guestLockTitle,
          hint: Strings.guestLockBody,
        ),
      );
    }
    final ordersAsync = ref.watch(_misiOrdersProvider(uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Misi koin')),
      body: ordersAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyState(
          icon: Icons.cloud_off_outlined,
          title: Strings.gagalMuatPesanan,
          hint: Strings.periksaKoneksi,
        ),
        data: (orders) {
          final progress = misiProgress(orders);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Koinnya bisa dicari sambil main, belanjanya jadi makin murah!',
                style: TextStyle(
                    color: context.teksRedup,
                    fontSize: 13,
                    fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              Text(
                'Selesaikan misi, kumpulkan koin. Koin yang diambil '
                'langsung masuk ke dompet Koin Warga.',
                style:
                    TextStyle(color: context.teksRedup, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _gameSection(context, uid),
              const SizedBox(height: 12),
              if (_memuat)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ))
              else
                for (final misi in kMisiList)
                  _misiCard(
                    context,
                    ref,
                    misi,
                    progress[misi.id] ?? 0,
                    uid,
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _gameSection(BuildContext context, String uid) {
    final settings = ref.watch(coinSettingsProvider).valueOrNull;
    final programOn = settings?.enabled ?? true;
    final tangkapOn = settings?.events['tangkapDiskon'] ?? true;
    final buruOn = settings?.events['buruDiskon'] ?? true;
    final guessOn = settings?.events['guess'] ?? true;

    if (!programOn || (!tangkapOn && !buruOn && !guessOn)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Game Berhadiah',
          style: TextStyle(
            color: context.teksUtama,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (tangkapOn) ...[
          const SizedBox(height: 8),
          _gameTile(
            context,
            uid,
            gameTangkapDiskon,
            Icons.touch_app_outlined,
            'Tangkap barang berlabel diskon. 1000 poin = 1 koin.',
          ),
        ],
        if (buruOn) ...[
          const SizedBox(height: 8),
          _gameTile(
            context,
            uid,
            gameBuruDiskon,
            Icons.shopping_basket_outlined,
            'Tangkap barang jatuh dengan keranjang. 1000 poin = 1 koin.',
          ),
        ],
        if (guessOn) ...[
          const SizedBox(height: 8),
          AppCard(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TebakHargaPage(),
                ),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                      Icons.help_outline, color: AppColors.orange, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tebak Harga',
                        style: TextStyle(
                          color: context.teksUtama,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Tebak harga produk, dapat koin.',
                        style: TextStyle(
                          color: context.teksRedup,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.orange),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _gameTile(
    BuildContext context,
    String uid,
    GameConfig config,
    IconData icon,
    String desc,
  ) {
    return FutureBuilder<int>(
      future: ref
          .read(socialRepositoryProvider)
          .gameCoinsToday(uid, config.dateField, config.todayField),
      builder: (context, snap) {
        final got = snap.data ?? 0;
        return AppCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GameWebViewPage(config: config),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.orange, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.title,
                      style: TextStyle(
                        color: context.teksUtama,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      desc,
                      style: TextStyle(
                        color: context.teksRedup,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hari ini: $got/500 koin',
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.orange),
            ],
          ),
        );
      },
    );
  }

  Widget _misiCard(BuildContext context, WidgetRef ref, Misi misi,
      int capaian, String uid) {
    final tuntas = capaian >= misi.target;
    final diminta = _diminta.contains(misi.id);
    final pct = (capaian / misi.target).clamp(0.0, 1.0);
    final reward = ref.watch(coinSettingsProvider).valueOrNull?.rewards['mission'] ??
        misi.hadiahKoin;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    misi.judul,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+$reward koin',
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              misi.deskripsi,
              style: TextStyle(
                  color: context.teksRedup, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor:
                    AppColors.orange.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation(
                    AppColors.orange),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$capaian/${misi.target}',
              style: TextStyle(
                  color: context.teksRedup, fontSize: 12),
            ),
            if (tuntas) ...[
              const SizedBox(height: 8),
              AppButton(
                label: diminta
                    ? 'Sudah diambil'
                    : (_klaimBusy ? 'Memproses...' : 'Ambil hadiah'),
                fullWidth: true,
                onPressed: (diminta || _klaimBusy)
                    ? null
                    : () =>
                        _mintaHadiah(context, ref, misi, uid),
              ),
            ] else ...[
              const SizedBox(height: 8),
              const AppButton(
                label: 'Belum tersedia',
                fullWidth: true,
                onPressed: null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final _misiOrdersProvider =
    StreamProvider.family<List<Order>, String>((ref, uid) {
  return ref.watch(orderRepositoryProvider).watchMyOrders(uid);
});
