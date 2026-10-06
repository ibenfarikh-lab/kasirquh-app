import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/strings_id.dart';
import 'admin_login_screen.dart';
import 'pin_service.dart';

/// PIN Admin 6 digit: buat + konfirmasi (pertama kali), verifikasi,
/// lupa PIN → reset → buat baru. Hash disimpan di secure storage.
class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  String? _firstPin; // untuk konfirmasi
  bool _isNew = false;
  bool _checking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final has = await ref.read(pinServiceProvider).hasPin;
    setState(() {
      _isNew = !has;
      _checking = false;
    });
  }

  Future<void> _onDigit(String d) async {
    if (_pin.length >= 6) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == 6) {
      await Future.delayed(const Duration(milliseconds: 200));
      await _submit();
    }
  }

  Future<void> _submit() async {
    final service = ref.read(pinServiceProvider);
    if (_isNew) {
      if (_firstPin == null) {
        setState(() {
          _firstPin = _pin;
          _pin = '';
        });
      } else if (_pin == _firstPin) {
        await service.setPin(_pin);
        if (mounted) _granted();
      } else {
        setState(() {
          _error = Strings.pinTidakSama;
          _pin = '';
          _firstPin = null;
        });
      }
    } else {
      if (await service.verify(_pin)) {
        if (mounted) _granted();
      } else {
        setState(() {
          _error = Strings.pinSalah;
          _pin = '';
        });
      }
    }
  }

  void _granted() {
    // PIN benar → lanjut ke login admin (email + kata sandi + claim).
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );
  }

  Future<void> _forgot() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text(Strings.lupaPin),
        content: const Text(
            'PIN lama akan dihapus. Kamu akan membuat PIN baru.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text(Strings.batal),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Atur ulang',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(pinServiceProvider).reset();
      setState(() {
        _isNew = true;
        _firstPin = null;
        _pin = '';
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isNew
        ? (_firstPin == null ? Strings.buatPin : Strings.konfirmasiPin)
        : Strings.masukkanPin;
    return Scaffold(
      backgroundColor: AppColors.adminBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.warmText,
        title: const Text(Strings.appName),
      ),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(title,
                      style: const TextStyle(
                        color: AppColors.warmText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      )),
                  if (_isNew)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        Strings.buatPinHint,
                        style: TextStyle(color: AppColors.warmMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      6,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _pin.length
                              ? AppColors.orange
                              : AppColors.panel2,
                        ),
                      ),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_error!,
                          style:
                              const TextStyle(color: AppColors.danger)),
                    ),
                  const SizedBox(height: 24),
                  Expanded(child: _PinPad(onDigit: _onDigit, onBack: () {
                    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
                  })),
                  if (!_isNew)
                    TextButton(
                      onPressed: _forgot,
                      child: const Text(
                        Strings.lupaPin,
                        style: TextStyle(color: AppColors.warmMuted),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _PinPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBack;

  const _PinPad({required this.onDigit, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: [
        for (var i = 1; i <= 9; i++) _key('$i', () => onDigit('$i')),
        const SizedBox.shrink(),
        _key('0', () => onDigit('0')),
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.backspace_outlined,
              color: AppColors.warmMuted),
        ),
      ],
    );
  }

  Widget _key(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.adminLine),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.warmText,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
