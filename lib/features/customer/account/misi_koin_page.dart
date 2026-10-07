import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/social_repository.dart';
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
    id: 'belanja_pertama',
    judul: 'Belanja pertama',
    deskripsi: 'Selesaikan 1 pesanan.',
    target: 1,
    hadiahKoin: 10,
  ),
  Misi(
    id: 'pelanggan_setia',
    judul: 'Pelanggan setia',
    deskripsi: 'Selesaikan 5 pesanan.',
    target: 5,
    hadiahKoin: 25,
  ),
  Misi(
    id: 'kabar_pertama',
    judul: 'Kabar pertama',
    deskripsi: 'Kirim 1 kabar di Rumpi.',
    target: 1,
    hadiahKoin: 5,
  ),
  Misi(
    id: 'tukang_cerita',
    judul: 'Tukang cerita',
    deskripsi: 'Kirim 10 kabar di Rumpi.',
    target: 10,
    hadiahKoin: 20,
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
/// Hadiah diberikan admin (hanya admin yang bisa menulis coin_ledger):
/// pelanggan mengetuk "Minta hadiah" → pesan terkirim ke Chat Toko,
/// admin memberi koin lewat penyesuaian koin. Penanda klaim disimpan
/// lokal agar tidak diminta dua kali.
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
    _muatPenanda();
  }

  Future<void> _muatPenanda() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('misiKoinDiminta') ?? const [];
      if (mounted) {
        setState(() {
          _diminta = list.toSet();
          _memuat = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _memuat = false);
    }
  }

  Future<void> _mintaHadiah(
      BuildContext context, WidgetRef ref, Misi misi, String uid) async {
    final thread =
        ref.read(myTokoThreadProvider(uid)).valueOrNull;
    if (thread == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Chat toko belum siap. Tunggu persetujuan admin dulu ya.')),
        );
      }
      return;
    }
    try {
      await ref.read(socialRepositoryProvider).sendTokoMessage(
            threadId: thread.id,
            uid: uid,
            text: 'Halo! Saya menyelesaikan misi "${misi.judul}" '
                '(${misi.hadiahKoin} koin). Mohon hadiahnya ya, terima kasih!',
          );
      final prefs = await SharedPreferences.getInstance();
      final baru = {..._diminta, misi.id};
      await prefs.setStringList('misiKoinDiminta', baru.toList());
      if (mounted) setState(() => _diminta = baru);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Permintaan dikirim ke toko. Tunggu admin memberi koin ya.')),
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
                'Selesaikan misi, kumpulkan koin. Hadiah diberikan '
                'admin lewat Chat Toko.',
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
