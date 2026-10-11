import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../l10n/strings_id.dart';
import '../session.dart';
import 'coin_history_page.dart';
import 'misi_koin_page.dart';
import 'tebak_harga_page.dart';

/// Dompet Koin Warga — satu pintu masuk koin ala PWA (coinModal).
/// Tampil: saldo + nilai Rp, aturan program, shortcut Misi Koin
/// & Tebak Harga, tautan Riwayat Koin.
class DompetKoinPage extends ConsumerWidget {
  const DompetKoinPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).valueOrNull;
    final uid = memberUid(session ?? const Session.guest());
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dompet Koin')),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: Strings.guestLockTitle,
          hint: Strings.guestLockBody,
        ),
      );
    }
    final settings =
        ref.watch(coinSettingsProvider).valueOrNull ?? const CoinSettings();
    final saldo = session?.coins ?? 0;
    final fmt = NumberFormat('#,###', 'id_ID');

    return Scaffold(
      appBar: AppBar(title: const Text('Dompet Koin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Kartu saldo.
          AppCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on,
                        color: AppColors.orange, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      '${fmt.format(saldo)} koin',
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Nilai koin dikunci Rp1 (tetap).
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '= Rp${fmt.format(saldo)}',
                      style: TextStyle(
                          color: context.teksRedup, fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.lock_outline,
                        size: 14, color: context.teksRedup),
                    Text(
                      ' Rp1/koin tetap',
                      style: TextStyle(
                          color: context.teksRedup, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Jalan pintas',
              style: TextStyle(
                  color: context.teksRedup,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          // Shortcut: Misi Koin & Tebak Harga (ala PWA).
          Row(
            children: [
              Expanded(
                child: _shortcut(
                  context,
                  icon: Icons.emoji_events_outlined,
                  label: 'Misi Koin',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const MisiKoinPage()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _shortcut(
                  context,
                  icon: Icons.help_outline,
                  label: 'Tebak Harga',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const TebakHargaPage()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Aturan program',
              style: TextStyle(
                  color: context.teksRedup,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _aturan(context,
                    'Bonus harian: +${settings.rewards['checkin'] ?? 5} koin (1x sehari)'),
                _aturan(context,
                    'Belanja: +${settings.spendReward} koin tiap Rp${fmt.format(settings.spendRule)} (otomatis)'),
                _aturan(context,
                    'Misi koin: +${settings.rewards['mission'] ?? 15} koin per misi'),
                _aturan(context,
                    'Tebak harga: +${settings.rewards['guess'] ?? 10} koin (1x sehari)'),
                _aturan(
                    context,
                    'Tukar: maks ${settings.redeemLimit}% dari total belanja',
                    terakhir: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => CoinHistoryPage(uid: uid)),
            ),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Riwayat Koin'),
          ),
        ],
      ),
    );
  }

  Widget _shortcut(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return AppCard(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppColors.orange, size: 28),
          const SizedBox(height: 6),
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _aturan(BuildContext context, String teks,
      {bool terakhir = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: terakhir ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(teks, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
