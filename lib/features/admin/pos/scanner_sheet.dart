import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/strings_id.dart';

/// Sheet Scanner: pindai barcode pakai kamera, atau ketik manual.
/// Mengembalikan String barcode (atau null bila batal).
/// Izin kamera diminta oleh sistem saat pertama dipakai.
class ScannerSheet extends StatefulWidget {
  const ScannerSheet({super.key});

  @override
  State<ScannerSheet> createState() => _ScannerSheetState();
}

class _ScannerSheetState extends State<ScannerSheet> {
  final _manual = TextEditingController();
  final _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;

  @override
  void dispose() {
    _manual.dispose();
    _scanner.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture cap) {
    if (_done) return;
    final raw = cap.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _done = true;
    Navigator.of(context).pop(raw);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
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
            const Text(
              Strings.pindaiBarcode,
              style: TextStyle(
                color: AppColors.warmText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 280,
                child: MobileScanner(
                  controller: _scanner,
                  onDetect: _onDetect,
                  errorBuilder: (_, __, ___) => const _CameraError(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              Strings.ketikBarcode,
              style: TextStyle(color: AppColors.warmMuted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manual,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.warmText),
                    decoration: const InputDecoration(
                      hintText: 'cth: 899123456',
                      hintStyle: TextStyle(color: AppColors.warmMuted),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.adminLine),
                      ),
                    ),
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) {
                        Navigator.of(context).pop(v.trim());
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 110,
                  child: AppButton(
                    label: Strings.cari,
                    fullWidth: false,
                    onPressed: () {
                      final v = _manual.text.trim();
                      if (v.isNotEmpty) Navigator.of(context).pop(v);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.panel2,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: const Text(
        'Kamera tidak tersedia. Ketik barcode manual di bawah.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.warmMuted),
      ),
    );
  }
}
