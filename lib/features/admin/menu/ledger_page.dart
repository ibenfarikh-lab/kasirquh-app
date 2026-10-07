import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/journal_entry.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../l10n/strings_id.dart';

/// Batas periode [from, to) — fungsi murni (di-test).
/// 0 = hari ini, 1 = minggu ini (Senin–Minggu), 2 = bulan ini.
(DateTime, DateTime) batasPeriode(int periode, DateTime now) {
  final hari = DateTime(now.year, now.month, now.day);
  return switch (periode) {
    1 => (
        hari.subtract(Duration(days: hari.weekday - 1)),
        hari
            .subtract(Duration(days: hari.weekday - 1))
            .add(const Duration(days: 7)),
      ),
    2 => (
        DateTime(now.year, now.month),
        DateTime(now.year, now.month + 1),
      ),
    _ => (hari, hari.add(const Duration(days: 1))),
  };
}

/// Filter entri ke dalam [from, to) — fungsi murni (di-test).
List<JournalEntry> filterJurnalPeriode(
        List<JournalEntry> semua, DateTime from, DateTime to) =>
    semua
        .where(
            (e) => !e.createdAt.isBefore(from) && e.createdAt.isBefore(to))
        .toList();

/// Saldo awal sudah pernah diisi — fungsi murni (di-test).
/// Label 'Saldo awal kas' sama persis dengan yang ditulis PWA.
bool saldoAwalSudahAda(List<JournalEntry> semua) =>
    semua.any((e) => e.label == Strings.saldoAwalKas);

/// Halaman Pembukuan (Mode Admin) — selaras bentuk ideal PWA:
/// tab Hari|Minggu|Bulan, tombol Isi saldo awal & Catat,
/// kartu UANG MASUK / UANG KELUAR (per periode) + SALDO KAS (semua waktu),
/// jurnal berikon + waktu + nominal bertanda.
class LedgerPage extends ConsumerStatefulWidget {
  const LedgerPage({super.key});

  @override
  ConsumerState<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends ConsumerState<LedgerPage> {
  int _periode = 0;
  bool _tampilForm = false;
  bool _modeSaldoAwal = false;

  bool _masuk = true;
  final _ket = TextEditingController();
  final _nominal = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ket.dispose();
    _nominal.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _bukaCatat() {
    setState(() {
      _modeSaldoAwal = false;
      _ket.clear();
      _tampilForm = !_tampilForm;
    });
  }

  void _bukaSaldoAwal() {
    setState(() {
      _modeSaldoAwal = true;
      _masuk = true;
      _ket.text = Strings.saldoAwalKas;
      _tampilForm = true;
    });
  }

  Future<void> _simpan() async {
    final nominal =
        int.tryParse(_nominal.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final ket = _ket.text.trim();
    if (nominal <= 0 || ket.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (_modeSaldoAwal) {
        // Saldo awal: pemasukan kind 'modal' → Firestore
        // {type: 'pemasukan', category: 'lainnya', note: 'Saldo awal kas'}
        // persis seperti yang ditulis PWA.
        await repo.addJournal(
          kind: 'modal',
          label: Strings.saldoAwalKas,
          amount: nominal,
        );
      } else {
        await repo.addJournal(
          kind: _masuk ? 'penjualan' : 'beban',
          label: ket,
          amount: _masuk ? nominal : -nominal,
        );
      }
      _ket.clear();
      _nominal.clear();
      if (_modeSaldoAwal) {
        setState(() {
          _tampilForm = false;
          _modeSaldoAwal = false;
        });
      }
      _snack(Strings.berhasilDisimpan);
    } catch (_) {
      _snack(Strings.butuhInternetAdmin);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (from, to) = batasPeriode(_periode, DateTime.now());
    final journalAsync = ref.watch(adminJournalProvider);
    final semua = journalAsync.valueOrNull ?? const <JournalEntry>[];
    final adaSaldoAwal = saldoAwalSudahAda(semua);
    final periodeEntries = filterJurnalPeriode(semua, from, to);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Kepala: kembali + kicker/judul + aksi.
            Row(
              children: [
                IconButton(
                  tooltip: Strings.kembali,
                  icon: const Icon(Icons.arrow_back,
                      color: AppColors.warmText),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Strings.satuKas,
                        style: TextStyle(
                            color: AppColors.warmMuted, fontSize: 12),
                      ),
                      Text(
                        Strings.modulPembukuan,
                        style: TextStyle(
                          color: AppColors.orange,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!adaSaldoAwal)
                  AppButton(
                    label: Strings.isiSaldoAwal,
                    fullWidth: false,
                    kind: AppButtonKind.secondary,
                    onPressed: _bukaSaldoAwal,
                  ),
                if (!adaSaldoAwal) const SizedBox(width: 8),
                AppButton(
                  label: Strings.catat,
                  fullWidth: false,
                  onPressed: _bukaCatat,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tab periode: Hari | Minggu | Bulan.
            _PeriodTabs(
              index: _periode,
              onChanged: (i) => setState(() => _periode = i),
            ),
            const SizedBox(height: 12),
            _SummarySection(from: from, to: to),
            if (_tampilForm) ...[
              const SizedBox(height: 12),
              _FormCatat(
                modeSaldoAwal: _modeSaldoAwal,
                masuk: _masuk,
                onJenisChanged: (v) => setState(() => _masuk = v),
                ket: _ket,
                nominal: _nominal,
                saving: _saving,
                onSimpan: _simpan,
                onTutup: () => setState(() {
                  _tampilForm = false;
                  _modeSaldoAwal = false;
                }),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  Strings.jurnalTransaksi,
                  style: TextStyle(
                    color: AppColors.warmText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  Strings.labelPergerakan(periodeEntries.length),
                  style: const TextStyle(
                      color: AppColors.warmMuted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (journalAsync.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                      color: AppColors.orange),
                ),
              )
            else if (periodeEntries.isEmpty)
              const EmptyState(
                icon: Icons.book_outlined,
                title: Strings.belumAdaTransaksi,
                hint: Strings.belumAdaTransaksiPeriode,
              )
            else
              ...periodeEntries.map((e) => _JournalTile(entry: e)),
          ],
        ),
      ),
    );
  }
}

/// Tab periode Hari | Minggu | Bulan.
class _PeriodTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _PeriodTabs({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = [
      Strings.labelHari,
      Strings.labelMinggu,
      Strings.labelBulan
    ];
    return Row(
      children: List.generate(3, (i) {
        final aktif = i == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                left: i == 0 ? 0 : 4, right: i == 2 ? 0 : 4),
            child: AppButton(
              label: labels[i],
              fullWidth: true,
              kind: aktif
                  ? AppButtonKind.primary
                  : AppButtonKind.secondary,
              onPressed: () => onChanged(i),
            ),
          ),
        );
      }),
    );
  }
}

/// Kartu ringkasan: UANG MASUK / UANG KELUAR (per periode aktif)
/// + SALDO KAS (semua waktu).
class _SummarySection extends ConsumerWidget {
  final DateTime from;
  final DateTime to;

  const _SummarySection({required this.from, required this.to});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(adminRepositoryProvider);
    return FutureBuilder<List<JournalSummary>>(
      future: Future.wait([
        repo.journalSummary(from: from, to: to),
        repo.journalSummary(),
      ]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                  color: AppColors.orange),
            ),
          );
        }
        final periode = snap.data![0];
        final semua = snap.data![1];
        // Prinsip: mending "belum ada transaksi" daripada angka
        // dari ketiadaan data.
        if (semua.transaksi == 0) {
          return const EmptyState(
            icon: Icons.book_outlined,
            title: Strings.belumAdaTransaksi,
            hint: Strings.jurnalKosongHint,
          );
        }
        final saldo = semua.masuk - semua.keluar;
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _CashCard(
                    label: Strings.uangMasuk,
                    value: periode.masuk,
                    color: AppColors.ok,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CashCard(
                    label: Strings.uangKeluar,
                    value: periode.keluar,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    Strings.saldoKas,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    formatRp(saldo),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CashCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _CashCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.warmMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatRp(value),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Form "Catat transaksi manual" inline (toggle dari tombol Catat).
/// Mode saldo awal: jenis & keterangan dikunci.
class _FormCatat extends StatelessWidget {
  final bool modeSaldoAwal;
  final bool masuk;
  final ValueChanged<bool> onJenisChanged;
  final TextEditingController ket;
  final TextEditingController nominal;
  final bool saving;
  final VoidCallback onSimpan;
  final VoidCallback onTutup;

  const _FormCatat({
    required this.modeSaldoAwal,
    required this.masuk,
    required this.onJenisChanged,
    required this.ket,
    required this.nominal,
    required this.saving,
    required this.onSimpan,
    required this.onTutup,
  });

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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  modeSaldoAwal
                      ? Strings.isiSaldoAwal
                      : Strings.catatTransaksiManual,
                  style: const TextStyle(
                    color: AppColors.warmText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: Strings.tutup,
                icon: const Icon(Icons.close,
                    color: AppColors.warmMuted, size: 20),
                onPressed: onTutup,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!modeSaldoAwal) ...[
            DropdownButtonFormField<bool>(
              initialValue: masuk,
              decoration: _deco(Strings.jenisTransaksi),
              dropdownColor: AppColors.panel2,
              style: const TextStyle(color: AppColors.warmText),
              items: const [
                DropdownMenuItem(
                  value: true,
                  child: Text(Strings.uangMasukOpt),
                ),
                DropdownMenuItem(
                  value: false,
                  child: Text(Strings.uangKeluarOpt),
                ),
              ],
              onChanged: (v) => onJenisChanged(v ?? true),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: ket,
            enabled: !modeSaldoAwal,
            maxLength: 80,
            style: const TextStyle(color: AppColors.warmText),
            decoration: _deco(Strings.keterangan),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nominal,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: AppColors.warmText),
            decoration: _deco(Strings.nominal),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: saving
                ? '...'
                : (modeSaldoAwal
                    ? Strings.isiSaldoAwal
                    : Strings.simpan),
            onPressed: saving ? null : onSimpan,
          ),
        ],
      ),
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

/// Satu baris entri jurnal: ikon jenis + keterangan + waktu
/// + nominal bertanda.
class _JournalTile extends StatelessWidget {
  final JournalEntry entry;

  const _JournalTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final positive = entry.amount >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.panel2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _kindIcon(entry.kind),
                color: _kindColor(entry.kind),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    style: const TextStyle(
                      color: AppColors.warmText,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(entry.createdAt),
                    style: const TextStyle(
                        color: AppColors.warmMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${positive ? '+' : '−'}${formatRp(entry.amount.abs())}',
              style: TextStyle(
                color:
                    positive ? AppColors.ok : AppColors.danger,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
