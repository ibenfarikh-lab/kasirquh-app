import 'package:flutter/material.dart';

/// Kartu standar: radius 14px — dari DESIGN_SYSTEM.md.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Border khusus (mis. kartu kasir PWA: 1px #d4d4d4 di dark mode).
  /// Null = ikut cardTheme.
  final BorderSide? borderSide;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: padding, child: child),
    );
    // Border khusus: bungkus dengan Container ber-border.
    if (borderSide != null) {
      card = Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: borderSide!.color, width: borderSide!.width),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: card,
        ),
      );
    }
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: card,
    );
  }
}
