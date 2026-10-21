import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../l10n/strings_id.dart';

class CoinSettingsPage extends ConsumerStatefulWidget {
  const CoinSettingsPage({super.key});

  @override
  ConsumerState<CoinSettingsPage> createState() => _CoinSettingsPageState();
}

class _CoinEventDef {
  final String key;
  final String title;
  final String subtitle;
  final bool hasInput;

  const _CoinEventDef({
    required this.key,
    required this.title,
    required this.subtitle,
    this.hasInput = true,
  });
}

const _events = [
  _CoinEventDef(
    key: 'checkin',
    title: 'Check-in harian',
    subtitle: 'Koin saat pelanggan membuka aplikasi',
  ),
  _CoinEventDef(
    key: 'mission',
    title: 'Misi koin',
    subtitle: 'Hadiah saat misi selesai',
  ),
  _CoinEventDef(
    key: 'guess',
    title: 'Tebak harga',
    subtitle: 'Hadiah jawaban benar',
  ),
  _CoinEventDef(
    key: 'spend',
    title: 'Belanja',
    subtitle: 'Dapat sejumlah koin tiap nominal',
  ),
  _CoinEventDef(
    key: 'tangkapDiskon',
    title: 'Tangkap Diskon',
    subtitle: 'Game 60 detik · 1000 poin = 1 koin',
    hasInput: false,
  ),
  _CoinEventDef(
    key: 'buruDiskon',
    title: 'Buru Diskon',
    subtitle: 'Game keranjang 60 detik · 1000 poin = 1 koin',
    hasInput: false,
  ),
];

class _CoinSettingsPageState extends ConsumerState<CoinSettingsPage> {
  bool _loaded = false;
  bool _busy = false;

  bool _enabled = true;
  int _redeemLimit = 50;
  final Map<String, bool> _eventsOn = {};
  final Map<String, TextEditingController> _rewardCtrls = {};
  final _spendRuleCtrl = TextEditingController();
  final _ruleCtrl = TextEditingController();

  @override
  void dispose() {
    for (final c in _rewardCtrls.values) {
      c.dispose();
    }
    _spendRuleCtrl.dispose();
    _ruleCtrl.dispose();
    super.dispose();
  }

  void _loadFrom(CoinSettings s) {
    if (_loaded) return;
    _loaded = true;
    _enabled = s.enabled;
    _redeemLimit = s.redeemLimit;
    for (final e in _events) {
      _eventsOn[e.key] = s.events[e.key] ?? true;
      if (e.hasInput) {
        final rewardKey = e.key == 'spend' ? 'spendReward' : e.key;
        _rewardCtrls[e.key] =
            TextEditingController(text: '${s.rewards[rewardKey] ?? 0}');
      }
    }
    _spendRuleCtrl.text = '${s.spendRule}';
    _ruleCtrl.text =
        'Kumpulkan ${s.spendReward} koin untuk setiap Rp${s.spendRule} belanja.';
  }

  Future<void> _simpan() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final rewards = <String, int>{};
      for (final e in _events) {
        if (e.hasInput) {
          final v =
              int.tryParse(_rewardCtrls[e.key]?.text.trim() ?? '') ?? 0;
          final rewardKey = e.key == 'spend' ? 'spendReward' : e.key;
          rewards[rewardKey] = v.clamp(0, 100000);
        }
      }
      final spendRule =
          int.tryParse(_spendRuleCtrl.text.trim()) ?? 100;

      await ref.read(adminRepositoryProvider).updateCoinSettings(
            enabled: _enabled,
            redeemLimit: _redeemLimit.clamp(0, 100),
            events: Map.from(_eventsOn),
            rewards: rewards,
            spendRule: spendRule.clamp(1, 1000000),
            rule: _ruleCtrl.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan koin tersimpan.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.butuhInternetAdmin)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
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
                  fontSize: 15,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: context.teksRedup,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: AppColors.orange,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    bool locked = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      enabled: !locked,
      style: TextStyle(color: context.teksUtama),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.teksRedup),
        filled: true,
        fillColor: context.permukaanKartu,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(coinSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Koin Warga')),
      body: settingsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            Strings.gagalMuatPesanan,
            style: TextStyle(color: context.teksRedup),
          ),
        ),
        data: (settings) {
          _loadFrom(settings);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _toggleRow(
                title: 'Program Koin Warga',
                subtitle: 'Dompet, perolehan, dan penukaran',
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      controller: TextEditingController(text: '1'),
                      label: 'Nilai 1 koin (Rp)',
                      locked: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _numberField(
                      controller: TextEditingController(
                          text: '$_redeemLimit'),
                      label: 'Maks. penukaran (%)',
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Terkunci: 1 koin = Rp1',
                  style: TextStyle(
                    color: context.teksRedup,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Event perolehan koin',
                style: TextStyle(
                  color: context.teksUtama,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              for (final e in _events) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.permukaanKartu,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _toggleRow(
                        title: e.title,
                        subtitle: e.subtitle,
                        value: _eventsOn[e.key] ?? true,
                        onChanged: (v) =>
                            setState(() => _eventsOn[e.key] = v),
                      ),
                      if (e.hasInput) ...[
                        const SizedBox(height: 8),
                        _numberField(
                          controller: _rewardCtrls[e.key]!,
                          label: 'Koin hadiah',
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Batas 500 koin/hari',
                            style: TextStyle(
                              color: context.teksRedup,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              _numberField(
                controller: _spendRuleCtrl,
                label: 'Nominal belanja per hadiah (Rp)',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ruleCtrl,
                maxLines: 3,
                style: TextStyle(color: context.teksUtama),
                decoration: InputDecoration(
                  labelText: 'Aturan program',
                  labelStyle: TextStyle(color: context.teksRedup),
                  filled: true,
                  fillColor: context.permukaanKartu,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: _busy ? 'Menyimpan...' : 'Simpan Pengaturan Koin',
                onPressed: _busy ? null : _simpan,
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
