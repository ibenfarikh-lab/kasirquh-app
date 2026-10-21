import 'dart:async';

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

class DompetKoinPage extends ConsumerStatefulWidget {
  const DompetKoinPage({super.key});

  @override
  ConsumerState<DompetKoinPage> createState() => _DompetKoinPageState();
}

class _DompetKoinPageState extends ConsumerState<DompetKoinPage> {
  Timer? _bannerTimer;
  int _bannerIdx = 0;
  List<String> _bannerMsgs = [];

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _updateBanner(CoinSettings settings) {
    final msgs = <String>[];
    if (settings.enabled) {
      if (settings.events['tangkapDiskon'] ?? true) {
        msgs.add('Sudah main Tangkap Diskon hari ini? 500 koin menanti!');
      }
      if (settings.events['buruDiskon'] ?? true) {
        msgs.add('Sudah main Buru Diskon hari ini? 500 koin menanti!');
      }
      if (settings.events['guess'] ?? true) {
        final reward = settings.rewards['guess'] ?? 100;
        final fmt = NumberFormat('#,###', 'id_ID');
        msgs.add(
            'Sudah tebak harga hari ini? +${fmt.format(reward)} koin menanti!');
      }
    }
    _bannerTimer?.cancel();
    _bannerTimer = null;
    if (msgs.join('|') != _bannerMsgs.join('|')) {
      _bannerMsgs = msgs;
      _bannerIdx = 0;
    }
    if (_bannerMsgs.length > 1 && mounted) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        setState(() {
          _bannerIdx = (_bannerIdx + 1) % _bannerMsgs.length;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateBanner(settings);
    });
    final saldo = session?.coins ?? 0;
    final fmt = NumberFormat('#,###', 'id_ID');

    return Scaffold(
      appBar: AppBar(title: const Text('Dompet Koin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Belanja dapat koin, main game dapat koin — semua jadi diskon!',
            style: TextStyle(
                color: context.teksRedup,
                fontSize: 13,
                fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
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
          if (_bannerMsgs.isNotEmpty) ...[
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(_bannerIdx),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.orange.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _bannerMsgs[_bannerIdx],
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Jalan pintas',
              style: TextStyle(
                  color: context.teksRedup,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
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
                    'Bonus harian: +${settings.rewards['checkin'] ?? 25} koin (1x sehari)'),
                _aturan(context,
                    'Belanja: +${settings.spendReward} koin tiap Rp${fmt.format(settings.spendRule)} (otomatis)'),
                _aturan(context,
                    'Misi koin: +${settings.rewards['mission'] ?? 250} koin per misi'),
                _aturan(context,
                    'Tebak harga: +${settings.rewards['guess'] ?? 100} koin (1x sehari)'),
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
