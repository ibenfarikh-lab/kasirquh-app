import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/journal_entry.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../l10n/strings_id.dart';

/// Halaman Pembukuan (Mode Admin): ringkasan jurnal kas + riwayat entri.
/// Tanpa data contoh — kosong berarti belum ada transaksi.
class LedgerPage extends ConsumerWidget {
  const LedgerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.modulPembukuan)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SummaryCard(),
          const SizedBox(height: 16),
          Text(
            'Riwayat',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const _JournalList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.orange,
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  static void _openForm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: const _JournalFormSheet(),
      ),
    );
  }
}

/// Kartu ringkasan: pemasukan, pengeluaran, laba bersih (semua waktu).
class _SummaryCard extends ConsumerWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(adminRepositoryProvider);
    return FutureBuilder<JournalSummary>(
      future: repo.journalSummary(),
      builder: (context, snap) {
        final s = snap.data ?? const JournalSummary();
        return AppCard(
          child: Column(
            children: [
              _summaryRow(Strings.pemasukan, s.masuk, AppColors.ok),
              const SizedBox(height: 8),
              _summaryRow(Strings.pengeluaran, s.keluar, AppColors.danger),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: AppColors.adminLine),
              ),
              _summaryRow(
                Strings.labaBersih,
                s.masuk - s.keluar,
                AppColors.orange,
                bold: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, int value, Color color, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.warmMuted)),
        Text(
          formatRp(value),
          style: TextStyle(
            color: color,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            fontSize: bold ? 17 : 15,
          ),
        ),
      ],
    );
  }
}

/// Daftar riwayat entri jurnal dari stream.
class _JournalList extends ConsumerWidget {
  const _JournalList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(adminJournalProvider);
    return journalAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(child: Text('$e')),
      data: (entries) {
        if (entries.isEmpty) {
          return const EmptyState(
            icon: Icons.book_outlined,
            title: Strings.belumAdaTransaksi,
            hint: Strings.jurnalKosongHint,
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppColors.adminLine),
          itemBuilder: (context, i) => _JournalTile(entry: entries[i]),
        );
      },
    );
  }
}

IconData _kindIcon(String kind) => switch (kind) {
      'penjualan' => Icons.point_of_sale,
      'kulakan' => Icons.shopping_cart_outlined,
      'beban' => Icons.receipt_long_outlined,
      _ => Icons.account_balance_wallet_outlined,
    };

Color _kindColor(String kind) => switch (kind) {
      'penjualan' => AppColors.ok,
      'kulakan' => AppColors.orange,
      'beban' => AppColors.danger,
      _ => AppColors.warmMuted,
    };

/// Satu baris entri jurnal.
class _JournalTile extends StatelessWidget {
  final JournalEntry entry;

  const _JournalTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final positive = entry.amount >= 0;
    final c = entry.createdAt;
    final date =
        '${c.day}/${c.month}/${c.year} ${c.hour.toString().padLeft(2, '0')}:${c.minute.toString().padLeft(2, '0')}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(_kindIcon(entry.kind), color: _kindColor(entry.kind)),
      title: Text(entry.label),
      subtitle: Text(
        date,
        style: const TextStyle(color: AppColors.warmMuted, fontSize: 12),
      ),
      trailing: Text(
        '${positive ? '+' : ''}${formatRp(entry.amount)}',
        style: TextStyle(
          color: positive ? AppColors.ok : AppColors.danger,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Form tambah catatan keuangan (bottom sheet).
class _JournalFormSheet extends ConsumerStatefulWidget {
  const _JournalFormSheet();

  @override
  ConsumerState<_JournalFormSheet> createState() => _JournalFormSheetState();
}

class _JournalFormSheetState extends ConsumerState<_JournalFormSheet> {
  static const _kindLabels = {
    'penjualan': Strings.penjualan,
    'kulakan': Strings.kulakan,
    'beban': Strings.beban,
    'modal': Strings.modal,
  };

  String _kind = 'penjualan';
  bool _isKeluar = false;
  bool _saving = false;
  final _labelCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _labelCtrl.addListener(_refresh);
    _amountCtrl.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _labelCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  bool get _valid =>
      _labelCtrl.text.trim().isNotEmpty &&
      (int.tryParse(_amountCtrl.text) ?? 0) > 0;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final nominal = int.parse(_amountCtrl.text);
      await ref.read(adminRepositoryProvider).addJournal(
            kind: _kind,
            label: _labelCtrl.text.trim(),
            amount: _isKeluar ? -nominal : nominal,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Strings.berhasilDisimpan)),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Strings.butuhInternetAdmin)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Strings.tambahCatatanKeuangan,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _kind,
            decoration:
                const InputDecoration(labelText: Strings.jenisTransaksi),
            items: _kindLabels.entries
                .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _kind = v ?? 'penjualan'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _labelCtrl,
            decoration: const InputDecoration(labelText: Strings.keterangan),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            decoration: const InputDecoration(labelText: Strings.nominal),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          SwitchListTile(
            title: const Text('Pengeluaran'),
            value: _isKeluar,
            activeThumbColor: AppColors.orange,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _isKeluar = v),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(Strings.batal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: Strings.simpan,
                  fullWidth: false,
                  onPressed: _valid && !_saving ? _save : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
