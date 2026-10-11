import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/social_repository.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../l10n/strings_id.dart';
import '../session.dart';

/// Definisi misi — id stabil untuk penanda klaim lokal.
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
    hadiahKoin: 15, // Ikut coinRewards.mission (default)
  ),
  Misi(
    id: 'coba_produk_baru',
    judul: 'Coba produk baru',
    deskripsi: 'Beli produk yang belum pernah dibeli.',
    target: 1,
    hadiahKoin: 10,
  ),
];

/// Progress misi dari data milik sendiri — fungsi pure (bisa di-test).
/// [selesaiCount] = pesanan berstatus selesai; [kabarCount] = kabar Rumpi.
Map<String, int> misiProgress({
  required int selesaiCount,
  required int kabarCount,
}) {
  return {
    'belanja_pertama': selesaiCount,
    'pelanggan_setia': selesaiCount,
    'kabar_pertama': kabarCount,
    'tukang_cerita': kabarCount,
  };
}

/// Mode Pelanggan > Akun > Misi koin — tantangan sederhana berhadiah koin.
/// Klaim otomatis via grantCoins (ikut PWA): koin langsung masuk dompet.
/// Penanda klaim di Firestore (missionClaims).
class MisiKoinPage extends ConsumerStatefulWidget {
  const MisiKoinPage({super.key});

  @override
  ConsumerState<MisiKoinPage> createState() => _MisiKoinPageState();
}

class _MisiKoinPageState extends ConsumerState<MisiKoinPage> {
  Set<String> _diminta = {};
  bool _memuat = true;

  @override
  void initState() {
    super.initState();
    // Penanda klaim dibaca dari Firestore (bukan lokal).
    // Untuk simplicity, mulai dengan kosong — status real dibaca saat klaim.
    setState(() {
      _diminta = {};
      _memuat = false;
    });
  }

  Future<void> _mintaHadiah(
      BuildContext context, WidgetRef ref, Misi misi, String uid) async {
    // Klaim otomatis via grantCoins (ikut PWA) — tidak perlu via chat.
    // Penanda klaim di Firestore (missionClaims), bukan SharedPreferences.
    try {
      final settings = ref.read(coinSettingsProvider).valueOrNull ??
          const CoinSettings();
      final reward = settings.rewards['mission'] ?? misi.hadiahKoin;

      await ref.read(adminRepositoryProvider).grantCoins(
            uid,
            reward,
            reason: 'misi',
            label: 'Hadiah misi: ${misi.judul}',
            detail: misi.id,
            claimKey: misi.id,
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
    final postsAsync = ref.watch(rumpiPostsProvider);

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
          final selesaiCount = orders
              .where((o) => o.status == OrderStatus.selesai)
              .length;
          final kabarCount = postsAsync.valueOrNull
                  ?.where((p) => p.authorId == uid)
                  .length ??
              0;
          final progress = misiProgress(
            selesaiCount: selesaiCount,
            kabarCount: kabarCount,
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Selesaikan misi, kumpulkan koin. Koin yang diambil '
                'langsung masuk ke dompet Koin Warga.',
                style:
                    TextStyle(color: context.teksRedup, fontSize: 13),
              ),
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

  Widget _misiCard(BuildContext context, WidgetRef ref, Misi misi,
      int capaian, String uid) {
    final tuntas = capaian >= misi.target;
    final diminta = _diminta.contains(misi.id);
    final pct = (capaian / misi.target).clamp(0.0, 1.0);
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
                    '+${misi.hadiahKoin} koin',
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
                    ? 'Sudah diminta — tunggu admin ya'
                    : 'Minta hadiah ke toko',
                fullWidth: true,
                onPressed: diminta
                    ? null
                    : () =>
                        _mintaHadiah(context, ref, misi, uid),
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
