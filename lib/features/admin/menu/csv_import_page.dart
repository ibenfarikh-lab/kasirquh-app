import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/csv_products.dart';
import '../../../core/utils/currency.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../l10n/strings_id.dart';

/// Halaman Impor Produk dari CSV (P1-7, mengikuti Web): pilih file →
/// pratinjau (baru/diperbarui/dilewati) → impor (upsert per barcode).
class CsvImportPage extends ConsumerStatefulWidget {
  const CsvImportPage({super.key});

  @override
  ConsumerState<CsvImportPage> createState() => _CsvImportPageState();
}

class _CsvImportPageState extends ConsumerState<CsvImportPage> {
  CsvParseResult? _hasil;
  String? _namaFile;
  String? _galat;
  bool _mengimpor = false;
  String? _selesai;

  Future<void> _pilihFile() async {
    setState(() {
      _galat = null;
      _selesai = null;
    });
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _galat = 'File tidak bisa dibaca.');
        return;
      }
      final teks = utf8.decode(bytes, allowMalformed: true);
      final hasil = mapCsvRows(parseCsvText(teks));
      setState(() {
        _hasil = hasil;
        _namaFile = file.name;
        if (hasil.items.isEmpty && hasil.skipped.isEmpty) {
          _galat = 'File kosong atau format tidak dikenal.';
        }
      });
    } catch (_) {
      setState(() => _galat = 'File tidak bisa dibaca.');
    }
  }

  Future<void> _impor() async {
    final hasil = _hasil;
    if (hasil == null || hasil.items.isEmpty) return;
    setState(() => _mengimpor = true);
    try {
      final existing =
          ref.read(adminProductsProvider).valueOrNull ?? const [];
      final r = await ref
          .read(adminRepositoryProvider)
          .importProductsCsv(hasil.items, existing);
      if (!mounted) return;
      setState(() {
        _mengimpor = false;
        _selesai =
            'Impor selesai · ${r.created} baru, ${r.updated} diperbarui';
        _hasil = null;
        _namaFile = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_selesai!)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _mengimpor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Strings.butuhInternetAdmin)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing =
        ref.watch(adminProductsProvider).valueOrNull ?? const [];
    final barcodeAda = <String>{
      for (final p in existing)
        if ((p.barcode ?? '').trim().isNotEmpty) p.barcode!.trim(),
    };
    final hasil = _hasil;
    var baru = 0;
    var perbarui = 0;
    if (hasil != null) {
      for (final it in hasil.items) {
        if (it.barcode.isNotEmpty && barcodeAda.contains(it.barcode)) {
          perbarui++;
        } else {
          baru++;
        }
      }
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Impor CSV')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Impor produk dari file CSV. Kode barcode yang sudah ada di '
            'database akan diperbarui dengan data dari file; sisanya '
            'dibuat baru. Kolom yang dikenal: Nama, Kategori, Satuan, '
            'Stok, Modal, Harga, Kode/Barcode, Foto.',
            style: TextStyle(color: context.teksRedup),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _mengimpor ? null : _pilihFile,
            icon: const Icon(Icons.upload_file),
            label: Text(_namaFile ?? 'Pilih file CSV'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          if (_galat != null) ...[
            const SizedBox(height: 12),
            Text(_galat!,
                style: const TextStyle(color: AppColors.danger)),
          ],
          if (_selesai != null && hasil == null) ...[
            const SizedBox(height: 12),
            Text(_selesai!,
                style: const TextStyle(
                    color: AppColors.ok, fontWeight: FontWeight.w700)),
          ],
          if (hasil != null) ...[
            const SizedBox(height: 16),
            Text(
              '$baru baru · $perbarui akan diperbarui'
              '${hasil.skipped.isEmpty ? '' : ' · ${hasil.skipped.length} dilewati'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final it in hasil.items)
              ListTile(
                dense: true,
                title: Text(it.name),
                subtitle: Text(
                  '${it.cat} · ${it.unit} · stok ${formatStok(it.stock)} · '
                  '${formatRp(it.price.round())}'
                  '${it.barcode.isNotEmpty ? ' · ${it.barcode}' : ''}',
                ),
                trailing: Text(
                  it.barcode.isNotEmpty &&
                          barcodeAda.contains(it.barcode)
                      ? '(perbarui)'
                      : '(baru)',
                  style: TextStyle(color: context.teksRedup, fontSize: 12),
                ),
              ),
            if (hasil.skipped.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Dilewati:',
                style: TextStyle(
                    color: context.teksRedup, fontWeight: FontWeight.w700),
              ),
              for (final s in hasil.skipped)
                Text(
                  'Baris ${s.row}: ${s.reason}',
                  style:
                      TextStyle(color: context.teksRedup, fontSize: 12),
                ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed:
                  _mengimpor || hasil.items.isEmpty ? null : _impor,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
              ),
              child: _mengimpor
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Impor sekarang'),
            ),
          ],
        ],
      ),
    );
  }
}
