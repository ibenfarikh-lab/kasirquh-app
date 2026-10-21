import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/journal_entry.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../l10n/strings_id.dart';

List<int> omzetPerHari(List<JournalEntry> entries, DateTime today) {
  final base = DateTime(today.year, today.month, today.day);
  return List<int>.generate(7, (i) {
    final day = base.subtract(Duration(days: 6 - i));
    var sum = 0;
    for (final e in entries) {
      final c = e.createdAt;
      if (e.amount > 0 &&
          c.year == day.year &&
          c.month == day.month &&
          c.day == day.day) {
        sum += e.amount;
      }
    }
    return sum;
  });
}

({int omset, int laba, int transaksi, num item}) ringkasanLaporan(
    List<JournalEntry> entries) {
  var omset = 0;
  var laba = 0;
  var transaksi = 0;
  num item = 0;
  for (final e in entries) {
    if (e.kind != 'penjualan') continue;
    omset += e.amount;
    laba += e.profit;
    transaksi += 1;
    item += e.itemCount;
  }
  return (omset: omset, laba: laba, transaksi: transaksi, item: item);
}

List<JournalEntry> penjualanTerbaru(List<JournalEntry> entries) {
  final sales = entries.where((e) => e.kind == 'penjualan').toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return sales;
}

class ReportPage extends ConsumerWidget {
  const ReportPage({super.key});

  String _waktu(DateTime t) {
    String dua(int n) => n.toString().padLeft(2, '0');
    return '${dua(t.day)}/${dua(t.month)} ${dua(t.hour)}:${dua(t.minute)}';
  }

  String _qty(num n) =>
      n == n.roundToDouble() ? '${n.toInt()}' : formatStok(n.toDouble());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(adminJournalProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.modulLaporan)),
      body: journalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const EmptyState(
              icon: Icons.bar_chart_outlined,
              title: Strings.laporanKosong,
            );
          }
          final now = DateTime.now();
          final omzet7 = omzetPerHari(entries, now);
          final r = ringkasanLaporan(entries);
          final sales = penjualanTerbaru(entries);
          final adaSales = sales.isNotEmpty;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Strings.grafikOmzet,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      Strings.tujuhHariTerakhir,
                      style:
                          TextStyle(color: context.teksRedup, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _BarChartPainter(
                          values: omzet7,
                          warna: AppColors.orange,
                          warnaTeks: context.teksRedup,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'TOTAL OMSET',
                      value: adaSales ? formatRp(r.omset) : 'Belum ada data',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'LABA',
                      value: adaSales ? formatRp(r.laba) : 'Belum ada data',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'TRANSAKSI SUKSES',
                      value: adaSales ? '${r.transaksi}' : 'Belum ada data',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'TOTAL ITEM BARANG',
                      value: adaSales ? _qty(r.item) : 'Belum ada data',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Transaksi',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (!adaSales)
                Text(
                  'Belum ada transaksi',
                  style: TextStyle(color: context.teksRedup),
                )
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _barisTabel(
                        context,
                        waktu: 'Waktu',
                        metode: 'Metode',
                        qty: 'Qty',
                        omset: 'Omset',
                        laba: 'Laba',
                        tajuk: true,
                      ),
                      const Divider(height: 1),
                      for (final e in sales) ...[
                        _barisTabel(
                          context,
                          waktu: _waktu(e.createdAt),
                          metode: e.method.isEmpty ? '—' : e.method,
                          qty: _qty(e.itemCount),
                          omset: formatRp(e.amount),
                          laba: formatRp(e.profit),
                        ),
                        if (e != sales.last) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _barisTabel(
    BuildContext context, {
    required String waktu,
    required String metode,
    required String qty,
    required String omset,
    required String laba,
    bool tajuk = false,
  }) {
    final gaya = TextStyle(
      fontSize: 12,
      fontWeight: tajuk ? FontWeight.w700 : FontWeight.w400,
      color: tajuk ? context.teksRedup : context.teksUtama,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(waktu, style: gaya)),
          Expanded(flex: 2, child: Text(metode, style: gaya)),
          Expanded(child: Text(qty, style: gaya, textAlign: TextAlign.right)),
          Expanded(
              flex: 2,
              child: Text(omset, style: gaya, textAlign: TextAlign.right)),
          Expanded(
              flex: 2,
              child: Text(laba, style: gaya, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: context.teksRedup, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<int> values;
  final Color warna;
  final Color warnaTeks;

  const _BarChartPainter(
      {required this.values, required this.warna, required this.warnaTeks});

  static const _hariSingkat = {
    DateTime.monday: 'S',
    DateTime.tuesday: 'S',
    DateTime.wednesday: 'R',
    DateTime.thursday: 'K',
    DateTime.friday: 'J',
    DateTime.saturday: 'S',
    DateTime.sunday: 'M',
  };

  @override
  void paint(Canvas canvas, Size size) {
    const labelH = 22.0;
    final baseY = size.height - labelH;
    final n = values.length;
    canvas.drawLine(
      Offset(0, baseY),
      Offset(size.width, baseY),
      Paint()
        ..color = AppColors.adminLine
        ..strokeWidth = 1,
    );
    if (n == 0) return;

    final maxV = values.fold<int>(0, (m, v) => v > m ? v : m);
    final slot = size.width / n;
    final barW = slot * 0.52;
    final today = DateTime.now();
    final barPaint = Paint()..color = warna;

    for (var i = 0; i < n; i++) {
      final v = values[i];
      final h = maxV > 0 ? (v / maxV) * (baseY - 12) : 0.0;
      final x = slot * i + (slot - barW) / 2;
      if (h > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, baseY - h, barW, h),
            const Radius.circular(6),
          ),
          barPaint,
        );
      }
      final day = today.subtract(Duration(days: n - 1 - i));
      final tp = TextPainter(
        text: TextSpan(
          text: _hariSingkat[day.weekday] ?? '',
          style: TextStyle(color: warnaTeks, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, baseY + 5));
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    if (identical(values, oldDelegate.values)) return false;
    if (values.length != oldDelegate.values.length) return true;
    for (var i = 0; i < values.length; i++) {
      if (values[i] != oldDelegate.values[i]) return true;
    }
    return false;
  }
}
