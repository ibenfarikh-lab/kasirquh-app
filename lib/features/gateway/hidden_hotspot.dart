import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/pin_screen.dart';

/// Tap logo 1x → verifikasi PIN admin.
/// Bungkus logo/header dengan widget ini.
/// (Keputusan user 2026-10-06: 5x lalu 3x tetap merepotkan — 1x tap saja.
/// Keamanan tetap dipegang PIN 6 digit, bukan jumlah tap.)
class LogoTapGate extends ConsumerWidget {
  final Widget child;

  const LogoTapGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PinScreen()),
      ),
      child: child,
    );
  }
}
