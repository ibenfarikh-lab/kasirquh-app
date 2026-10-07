import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../l10n/strings_id.dart';

class StoreProfileSheet extends ConsumerStatefulWidget {
  const StoreProfileSheet({super.key});

  @override
  ConsumerState<StoreProfileSheet> createState() => _StoreProfileSheetState();
}

class _StoreProfileSheetState extends ConsumerState<StoreProfileSheet> {
  final _nama = TextEditingController();
  final _alamat = TextEditingController();
  final _telepon = TextEditingController();
  final _jamBuka = TextEditingController();
  final _jamTutup = TextEditingController();
  final _info = TextEditingController();
  final _teksBerjalan = TextEditingController();
  bool _terisi = false;
  bool _menyimpan = false;

  @override
  void dispose() {
    _nama.dispose();
    _alamat.dispose();
    _telepon.dispose();
    _jamBuka.dispose();
    _jamTutup.dispose();
    _info.dispose();
    _teksBerjalan.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    setState(() => _menyimpan = true);
    try {
      await ref.read(adminRepositoryProvider).saveStoreSettings({
        'storeName': _nama.text.trim(),
        'address': _alamat.text.trim(),
        'phone': _telepon.text.trim(),
        'openHour': _jamBuka.text.trim(),
        'closeHour': _jamTutup.text.trim(),
        'infoText': _info.text.trim(),
        'runningText': _teksBerjalan.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.berhasilDisimpan)),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.butuhInternetAdmin)),
      );
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeAsync = ref.watch(storeInfoProvider);
    final store = storeAsync.valueOrNull;
    if (store != null && !_terisi) {
      _nama.text = store.storeName;
      _alamat.text = store.address ?? '';
      _telepon.text = store.phone ?? '';
      _jamBuka.text = store.openHour;
      _jamTutup.text = store.closeHour;
      _info.text = store.infoText ?? '';
      _teksBerjalan.text = store.runningText ?? '';
      _terisi = true;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            // Aturan 1&3: ikut bottomSheetTheme (adaptif).
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
              Text(
                Strings.modulProfilToko,
                style: TextStyle(
                  color: context.teksUtama,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (store == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.orange),
                  ),
                )
              else ...[
                _field(_nama, Strings.namaToko),
                _field(_alamat, Strings.alamat),
                _field(_telepon, Strings.telepon,
                    keyboard: TextInputType.phone),
                Row(
                  children: [
                    Expanded(child: _field(_jamBuka, Strings.jamBuka)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_jamTutup, Strings.jamTutup)),
                  ],
                ),
                _field(_info, Strings.infoTokoLabel, maxLines: 2),
                _field(_teksBerjalan, Strings.teksBerjalan, maxLines: 2),
                const SizedBox(height: 8),
                AppButton(
                  label: Strings.simpan,
                  onPressed: _menyimpan ? null : _simpan,
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: TextStyle(color: context.teksUtama),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.teksRedup),
          filled: true,
          fillColor: context.permukaanKartu, // Aturan 1&3: adaptif.
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.adminLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.orange),
          ),
        ),
      ),
    );
  }
}
