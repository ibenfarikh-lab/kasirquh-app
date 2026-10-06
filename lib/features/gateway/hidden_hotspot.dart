import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/pin_screen.dart';

/// Tap logo 5x di dalam aplikasi → verifikasi PIN admin.
/// Bungkus logo/header dengan widget ini.
class LogoTapGate extends ConsumerStatefulWidget {
  final Widget child;

  const LogoTapGate({super.key, required this.child});

  @override
  ConsumerState<LogoTapGate> createState() => _LogoTapGateState();
}

class _LogoTapGateState extends ConsumerState<LogoTapGate> {
  int _taps = 0;
  DateTime? _firstTap;

  void _onTap() {
    final now = DateTime.now();
    if (_firstTap == null ||
        now.difference(_firstTap!) > const Duration(seconds: 3)) {
      _taps = 1;
      _firstTap = now;
      return;
    }
    _taps++;
    if (_taps >= 5) {
      _taps = 0;
      _firstTap = null;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PinScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _onTap, child: widget.child);
  }
}
