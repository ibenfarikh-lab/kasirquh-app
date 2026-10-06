import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tombol primer gradien oranye / Setujui (hijau) / Tolak (merah).
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = AppButtonKind.primary,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      minimumSize: const Size(44, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    );
    final button = switch (kind) {
      AppButtonKind.primary => _GradientButton(
          label: label,
          onPressed: onPressed,
          style: style,
        ),
      AppButtonKind.approve => ElevatedButton(
          onPressed: onPressed,
          style: style.copyWith(
            backgroundColor: const WidgetStatePropertyAll(AppColors.ok),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
          ),
          child: Text(label),
        ),
      AppButtonKind.danger => ElevatedButton(
          onPressed: onPressed,
          style: style.copyWith(
            backgroundColor:
                const WidgetStatePropertyAll(AppColors.danger),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
          ),
          child: Text(label),
        ),
      AppButtonKind.secondary => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(44, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(label),
        ),
    };
    if (!fullWidth) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

enum AppButtonKind { primary, approve, danger, secondary }

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonStyle style;

  const _GradientButton({
    required this.label,
    this.onPressed,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : AppColors.ctaGradient,
        color: onPressed == null ? Colors.grey.shade400 : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: style.copyWith(
          backgroundColor:
              const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor:
              const WidgetStatePropertyAll(Colors.white),
        ),
        child: Text(label),
      ),
    );
  }
}
