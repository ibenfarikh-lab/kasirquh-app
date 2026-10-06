import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/admin_repository.dart';
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
