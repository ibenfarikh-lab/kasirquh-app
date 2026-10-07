import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../l10n/strings_id.dart';
import 'customer_notes_sheet.dart';
import 'report_page.dart';

/// Query pencarian pelanggan — StateProvider agar [CustomersPage] tetap
/// ConsumerWidget tanpa state lokal.
final _customerSearchProvider = StateProvider<String>((ref) => '');

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

/// Tab Mode Admin > Modul Data: persetujuan pendaftar + daftar pelanggan +
/// penyesuaian koin + Laporan (pindah ke dalam Data, selaras prototipe).
class CustomersPage extends ConsumerWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.modulData)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ApprovalCard(ref: ref),
          const SizedBox(height: 16),
          _CustomerListCard(ref: ref),
          const SizedBox(height: 16),
          _LaporanCard(),
        ],
      ),
    );
  }
}

/// Seksi Laporan — di dalam Data (bukan modul sendiri).
class _LaporanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      // Aturan 1&3: ikut cardTheme (adaptif).
      child: ListTile(
        leading: const Icon(Icons.bar_chart_outlined,
            color: AppColors.orange),
        title: Text(
          Strings.modulLaporan,
          style:
              TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Omzet 7 hari, grafik, dan salin CSV.',
          style: TextStyle(color: context.teksRedup),
        ),
        trailing: Icon(Icons.chevron_right,
            color: context.teksRedup),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReportPage()),
        ),
      ),
    );
  }
}

/// Seksi A — kartu persetujuan pendaftar baru.
class _ApprovalCard extends ConsumerWidget {
  final WidgetRef ref;

  const _ApprovalCard({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingApprovalsProvider);
    return Card(
      // Aturan 1&3: ikut cardTheme (adaptif).
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person_add, color: AppColors.orange),
                SizedBox(width: 8),
                Text(
                  Strings.persetujuanPendaftar,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            pendingAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                e.toString(),
                style: const TextStyle(color: AppColors.danger),
              ),
              data: (pendaftars) {
                if (pendaftars.isEmpty) {
                  return Text(
                    Strings.belumAdaPendaftar,
                    style: TextStyle(
                      color: context.teksRedup,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final p in pendaftars)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(p.name),
                        subtitle: Text(p.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle),
                              color: AppColors.ok,
                              tooltip: Strings.setujui,
                              onPressed: () =>
                                  _setApproval(context, p.uid, true),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel),
                              color: AppColors.danger,
                              tooltip: Strings.tolak,
                              onPressed: () =>
                                  _setApproval(context, p.uid, false),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setApproval(
      BuildContext context, String uid, bool approved) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .setApproval(uid, approved);
      if (context.mounted) {
        _snack(context,
            approved ? Strings.pendaftarDisetujui : Strings.pendaftarDitolak);
      }
    } catch (_) {
      if (context.mounted) {
        _snack(context, Strings.butuhInternetAdmin);
      }
    }
  }
}

/// Seksi B — kartu daftar pelanggan dengan pencarian + tombol koin.
class _CustomerListCard extends ConsumerWidget {
  final WidgetRef ref;

  const _CustomerListCard({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(_customerSearchProvider).toLowerCase();
    final customersAsync = ref.watch(adminCustomersProvider);
    return Card(
      // Aturan 1&3: ikut cardTheme (adaptif).
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              Strings.daftarPelanggan,
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: Strings.cariNama,
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) =>
                  ref.read(_customerSearchProvider.notifier).state = v,
            ),
            const SizedBox(height: 8),
            customersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                e.toString(),
                style: const TextStyle(color: AppColors.danger),
              ),
              data: (customers) {
                final shown = query.isEmpty
                    ? customers
                    : customers
                        .where((c) =>
                            c.name.toLowerCase().contains(query) ||
                            c.email.toLowerCase().contains(query))
                        .toList();
                if (shown.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      Strings.belumAdaPelanggan,
                      style: TextStyle(
                        color: context.teksRedup,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final c in shown)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(c.name),
                        subtitle:
                            Text('${c.email} · ${c.coins} ${Strings.koin}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.note_outlined),
                              color: AppColors.orange,
                              tooltip: Strings.modulCatatanToko,
                              onPressed: () =>
                                  _openNotesSheet(context, c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.toll_outlined),
                              color: AppColors.orange,
                              tooltip: Strings.sesuaikanKoin,
                              onPressed: () =>
                                  _openCoinSheet(context, c),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openCoinSheet(BuildContext context, Customer customer) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: _CoinSheet(customer: customer),
      ),
    );
  }

  void _openNotesSheet(BuildContext context, Customer customer) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomerNotesSheet(customer: customer),
    );
  }
}

/// Bottom sheet penyesuaian koin pelanggan.
class _CoinSheet extends ConsumerStatefulWidget {
  final Customer customer;

  const _CoinSheet({required this.customer});

  @override
  ConsumerState<_CoinSheet> createState() => _CoinSheetState();
}

class _CoinSheetState extends ConsumerState<_CoinSheet> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _reasonCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _reasonCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply(BuildContext context, bool add) async {
    final amount = int.tryParse(_amountCtrl.text.trim());
    final reason = _reasonCtrl.text.trim();
    if (amount == null || amount == 0 || reason.isEmpty) {
      _snack(context, 'Isi jumlah koin dan alasan dulu.');
      return;
    }
    final delta = add ? amount.abs() : -amount.abs();
    try {
      await ref
          .read(adminRepositoryProvider)
          .adjustCoins(widget.customer.uid, delta, reason);
      if (context.mounted) {
        _snack(context, Strings.koinTersimpan);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (context.mounted) {
        _snack(context, Strings.butuhInternetAdmin);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        // Aturan 1&3: ikut bottomSheetTheme (adaptif).
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Strings.sesuaikanKoin,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(widget.customer.name),
          Text(
            '${widget.customer.coins} ${Strings.koin}',
            style: TextStyle(color: context.teksRedup),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(signed: true),
            decoration:
                const InputDecoration(labelText: Strings.jumlahKoin),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonCtrl,
            decoration: const InputDecoration(labelText: Strings.alasan),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: Strings.tambahKoin,
            kind: AppButtonKind.approve,
            onPressed: () => _apply(context, true),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: Strings.kurangKoin,
            kind: AppButtonKind.secondary,
            onPressed: () => _apply(context, false),
          ),
        ],
      ),
    );
  }
}
