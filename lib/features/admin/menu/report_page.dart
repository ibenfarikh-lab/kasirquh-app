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

/// Omzet harian 7 hari terakhir: 7 nilai, index 0 = 6 hari lalu,
/// index 6 = hari ini. Hanya menjumlahkan amount positif (pemasukan)
/// dari entri yang createdAt-nya jatuh di hari kalender tersebut.
/// Fungsi pure — bisa di-unit-test tanpa Flutter.
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

/// CSV jurnal: header + satu baris per entri.
/// Label dikutip karena bisa mengandung koma (kutip ganda di-escape).
/// Fungsi pure — bisa di-unit-test tanpa Flutter.
String buildCsv(List<JournalEntry> entries) {
  final buf = StringBuffer('tanggal,jenis,keterangan,nominal');
  for (final e in entries) {
    final c = e.createdAt;
    final date = '${c.year}-'
        '${c.month.toString().padLeft(2, '0')}-'
        '${c.day.toString().padLeft(2, '0')}';
    final label = '"${e.label.replaceAll('"', '""')}"';
    buf.write('\n$date,${e.kind},$label,${e.amount}');
  }
  return buf.toString();
}

/// Halaman Laporan (Mode Admin): ringkasan 7 hari terakhir + grafik
/// omzet + salin CSV. Tanpa data contoh — kosong berarti belum ada
/// transaksi pada periode ini.
class ReportPage extends ConsumerWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(adminJournalProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.modulLaporan)),
      body: journalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (entries) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final start = today.subtract(const Duration(days: 6));
          final end = today.add(const Duration(days: 1));
          final last7 = entries
              .where((e) =>
                  !e.createdAt.isBefore(start) && e.createdAt.isBefore(end))
              .toList();
          if (last7.isEmpty) {
            return const EmptyState(
              icon: Icons.bar_chart_outlined,
              title: Strings.laporanKosong,
            );
          }
          final omzet7 = omzetPerHari(entries, now);
          var masuk = 0;
          var keluar = 0;
          for (final e in last7) {
            if (e.amount >= 0) {
              masuk += e.amount;
            } else {
              keluar += -e.amount;
            }
          }
          final totalOmzet = omzet7.fold<int>(0, (a, b) => a + b);
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
                    const Text(
                      Strings.tujuhHariTerakhir,
                      style:
                          TextStyle(color: AppColors.warmMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _BarChartPainter(
                          values: omzet7,
                          warna: AppColors.orange,
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
                      label: Strings.omzet,
                      value: formatRp(totalOmzet),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: Strings.laba,
                      value: formatRp(masuk - keluar),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: Strings.transaksi,
                      value: '${last7.length}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppButton(
                kind: AppButtonKind.secondary,
                label: Strings.salinCsv,
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: buildCsv(last7)),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(Strings.csvDisalin)),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Kartu metrik kecil (omzet / laba / transaksi).
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
            style: const TextStyle(color: AppColors.warmMuted, fontSize: 12),
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

/// Grafik batang 7 hari dengan label hari singkat (S S R K J S M).
class _BarChartPainter extends CustomPainter {
  final List<int> values;
  final Color warna;

  const _BarChartPainter({required this.values, required this.warna});

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
    // Baseline selalu digambar (juga saat semua nilai 0).
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
      // Label hari: index i = (n-1-i) hari yang lalu.
      final day = today.subtract(Duration(days: n - 1 - i));
      final tp = TextPainter(
        text: TextSpan(
          text: _hariSingkat[day.weekday] ?? '',
          style: const TextStyle(color: AppColors.warmMuted, fontSize: 11),
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
