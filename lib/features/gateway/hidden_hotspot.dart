import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/pin_screen.dart';

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
