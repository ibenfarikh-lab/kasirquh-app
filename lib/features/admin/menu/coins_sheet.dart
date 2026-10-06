import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../l10n/strings_id.dart';

/// Sheet Koin Warga: panel cepat ubah saldo koin pelanggan (butuh internet).
class CoinsSheet extends ConsumerStatefulWidget {
  const CoinsSheet({super.key});

  @override
  ConsumerState<CoinsSheet> createState() => _CoinsSheetState();
}

class _CoinsSheetState extends ConsumerState<CoinsSheet> {
  final _search = TextEditingController();
  final _jumlah = TextEditingController();
  final _alasan = TextEditingController();
  String _query = '';
  Customer? _selected;
  bool _busy = false;

  @override
  void dispose() {
    _search.dispose();
    _jumlah.dispose();
    _alasan.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _reset() {
    setState(() {
      _selected = null;
      _search.clear();
      _jumlah.clear();
      _alasan.clear();
      _query = '';
    });
  }

  Future<void> _apply(int delta) async {
    final selected = _selected;
    if (selected == null) return;
    final jumlah = int.tryParse(_jumlah.text.trim());
    if (jumlah == null || jumlah == 0 || _alasan.text.trim().isEmpty) {
      _snack('Isi jumlah dan alasan dulu.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .adjustCoins(selected.uid, delta, _alasan.text.trim());
      _reset();
      _snack(Strings.koinTersimpan);
    } catch (_) {
      _snack(Strings.butuhInternetAdmin);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.warmMuted),
        filled: true,
        fillColor: AppColors.panel2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  /// Nilai koin + batas penukaran + event bonus — selaras prototipe.
  Widget _pengaturanKoin() {
    final info = ref.watch(storeInfoProvider).valueOrNull;
    final rate = info?.coinRate ?? 0;
    final batas = info?.coinRedeemLimit ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text(
              'Nilai koin',
              style: TextStyle(color: AppColors.warmText),
            ),
            subtitle: Text(
              rate <= 0
                  ? Strings.belumDiatur
                  : '${formatRp(rate)} per koin',
              style: const TextStyle(color: AppColors.warmMuted),
            ),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.warmMuted),
            onTap: () => _ubahAngka(
              judul: 'Nilai koin (Rp)',
              awal: rate,
              kunci: 'coinRate',
            ),
          ),
          const Divider(height: 1, color: AppColors.adminLine),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text(
              'Batas penukaran',
              style: TextStyle(color: AppColors.warmText),
            ),
            subtitle: Text(
              batas <= 0
                  ? Strings.belumDiatur
                  : 'Maks. $batas% dari total belanja',
              style: const TextStyle(color: AppColors.warmMuted),
            ),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.warmMuted),
            onTap: () => _ubahAngka(
              judul: 'Batas penukaran (%)',
              awal: batas,
              kunci: 'coinRedeemLimit',
            ),
          ),
          const Divider(height: 1, color: AppColors.adminLine),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text(
              'Event bonus',
              style: TextStyle(color: AppColors.warmText),
            ),
            subtitle: const Text(
              'Bagi koin ke semua pelanggan sekaligus.',
              style: TextStyle(color: AppColors.warmMuted),
            ),
            trailing: const Icon(Icons.celebration_outlined,
                color: AppColors.orange),
            onTap: _eventBonusDialog,
          ),
        ],
      ),
    );
  }

  Future<void> _ubahAngka({
    required String judul,
    required int awal,
    required String kunci,
  }) async {
    final ctrl = TextEditingController(text: awal > 0 ? '$awal' : '');
    var busy = false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.panel2,
          title: Text(judul,
              style:
                  const TextStyle(color: AppColors.warmText)),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly
            ],
            style:
                const TextStyle(color: AppColors.warmText),
            decoration: const InputDecoration(
              labelText: 'Nilai',
              labelStyle:
                  TextStyle(color: AppColors.warmMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(Strings.batal),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      setState(() => busy = true);
                      try {
                        final nilai = int.tryParse(
                                ctrl.text.trim()) ??
                            0;
                        await ref
                            .read(adminRepositoryProvider)
                            .saveStoreSettings({kunci: nilai});
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                        _snack(Strings.berhasilDisimpan);
                      } catch (_) {
                        _snack(Strings.butuhInternetAdmin);
                        if (ctx.mounted) {
                          setState(() => busy = false);
                        }
                      }
                    },
              child: const Text(Strings.simpan),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }

  Future<void> _eventBonusDialog() async {
    final jumlahCtrl = TextEditingController();
    final alasanCtrl = TextEditingController();
    var busy = false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.panel2,
          title: const Text('Event bonus koin',
              style:
                  TextStyle(color: AppColors.warmText)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Koin dibagikan ke SEMUA pelanggan yang disetujui.',
                style: TextStyle(
                    color: AppColors.warmMuted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: jumlahCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                style: const TextStyle(
                    color: AppColors.warmText),
                decoration: const InputDecoration(
                  labelText: 'Jumlah koin per pelanggan',
                  labelStyle: TextStyle(
                      color: AppColors.warmMuted),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: alasanCtrl,
                style: const TextStyle(
                    color: AppColors.warmText),
                decoration: const InputDecoration(
                  labelText: Strings.alasan,
                  hintText: 'Mis. "Bonus akhir tahun"',
                  labelStyle: TextStyle(
                      color: AppColors.warmMuted),
                  hintStyle: TextStyle(
                      color: AppColors.warmMuted),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(Strings.batal),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      final jumlah = int.tryParse(
                              jumlahCtrl.text.trim()) ??
                          0;
                      final alasan =
                          alasanCtrl.text.trim();
                      if (jumlah <= 0 ||
                          alasan.isEmpty) {
                        _snack(
                            'Isi jumlah dan alasan dulu.');
                        return;
                      }
                      setState(() => busy = true);
                      try {
                        final count = await ref
                            .read(adminRepositoryProvider)
                            .grantBonusToAll(
                              amount: jumlah,
                              reason: alasan,
                            );
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                        _snack(
                            'Bonus dibagikan ke $count pelanggan.');
                      } catch (_) {
                        _snack(
                            Strings.butuhInternetAdmin);
                        if (ctx.mounted) {
                          setState(() => busy = false);
                        }
                      }
                    },
              child: const Text('Bagikan'),
            ),
          ],
        ),
      ),
    );
    jumlahCtrl.dispose();
    alasanCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(adminCustomersProvider);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Row(
              children: [
                const Expanded(
                  child: Text(
                    Strings.modulKoin,
                    style: TextStyle(
                      color: AppColors.warmText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: Strings.tutup,
                  icon:
                      const Icon(Icons.close, color: AppColors.warmMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Text(
              Strings.koinWargaHint,
              style: TextStyle(color: AppColors.warmMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            // Nilai & batas — selaras prototipe (Nilai, event & batas).
            _pengaturanKoin(),
            const SizedBox(height: 16),
            const Text(
              Strings.pilihPelanggan,
              style: TextStyle(
                color: AppColors.warmText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _search,
              style: const TextStyle(color: AppColors.warmText),
              decoration: _deco(Strings.cariNama).copyWith(
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.warmMuted),
              ),
              onChanged: (v) =>
                  setState(() => _query = v.trim().toLowerCase()),
            ),
            const SizedBox(height: 8),
            customersAsync.when(
              data: (List<Customer> customers) {
                final filtered = customers
                    .where((c) =>
                        _query.isEmpty ||
                        c.name.toLowerCase().contains(_query) ||
                        c.email.toLowerCase().contains(_query))
                    .take(8)
                    .toList();
                if (filtered.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Tidak ketemu.',
                      style: TextStyle(color: AppColors.warmMuted),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    final isSel = _selected?.uid == c.uid;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        c.name.isEmpty ? c.email : c.name,
                        style: const TextStyle(
                          color: AppColors.warmText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${c.coins} ${Strings.koin}',
                        style: const TextStyle(
                            color: AppColors.warmMuted),
                      ),
                      trailing: isSel
                          ? const Icon(Icons.check_circle,
                              color: AppColors.orange)
                          : const Icon(Icons.radio_button_unchecked,
                              color: AppColors.warmMuted),
                      onTap: () => setState(() {
                        _selected = isSel ? null : c;
                      }),
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.orange),
                ),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Tidak ketemu.',
                  style: TextStyle(color: AppColors.warmMuted),
                ),
              ),
            ),
            if (_selected != null) ...[
              const SizedBox(height: 16),
              Text(
                '${_selected!.name.isEmpty ? _selected!.email : _selected!.name} · ${_selected!.coins} ${Strings.koin}',
                style: const TextStyle(
                  color: AppColors.warmText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _jumlah,
                style: const TextStyle(color: AppColors.warmText),
                keyboardType: const TextInputType.numberWithOptions(
                    signed: true),
                decoration: _deco(Strings.jumlahKoin),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _alasan,
                style: const TextStyle(color: AppColors.warmText),
                decoration: _deco(Strings.alasan),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: Strings.tambahKoin,
                      kind: AppButtonKind.approve,
                      fullWidth: false,
                      onPressed: _busy
                          ? null
                          : () {
                              final j =
                                  int.tryParse(_jumlah.text.trim()) ??
                                      0;
                              _apply(j.abs());
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: Strings.kurangKoin,
                      kind: AppButtonKind.secondary,
                      fullWidth: false,
                      onPressed: _busy
                          ? null
                          : () {
                              final j =
                                  int.tryParse(_jumlah.text.trim()) ??
                                      0;
                              _apply(-j.abs());
                            },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
