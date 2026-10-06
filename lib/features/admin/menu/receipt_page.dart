import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../pos/pay_sheet.dart';

/// Modul Struk 58mm (Mode Admin): buka ulang struk terakhir.
/// Struk disimpan setiap selesai pembayaran di Kasir.
/// Belum pernah ada transaksi → empty state jujur.
class ReceiptPage extends ConsumerWidget {
  const ReceiptPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Struk 58mm')),
      body: FutureBuilder<String?>(
        future: bacaStrukTerakhir(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }
          final struk = snap.data;
          if (struk == null || struk.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Belum ada struk',
              hint: 'Struk terakhir muncul di sini setelah '
                  'ada penjualan di Kasir.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Struk terakhir',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  struk,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                kind: AppButtonKind.secondary,
                label: 'Salin struk',
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: struk));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Struk disalin.')),
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
