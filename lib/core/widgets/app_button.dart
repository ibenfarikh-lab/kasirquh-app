import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tombol primer gradien oranye / Setujui (hijau) / Tolak (merah).
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final bool fullWidth;

  /// Saat true: tombol nonaktif + tampil spinner.
  /// (Temuan uji HP 2026-10-06: tanpa indikator loading, user mengira
  /// tap-nya tidak masuk lalu men-tap berkali-kali.)
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = AppButtonKind.primary,
    this.fullWidth = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
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
          onPressed: effectiveOnPressed,
          style: style,
          isLoading: isLoading,
        ),
      AppButtonKind.approve => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: style.copyWith(
            backgroundColor: const WidgetStatePropertyAll(AppColors.ok),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
          ),
          child: _labelChild(),
        ),
      AppButtonKind.danger => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: style.copyWith(
            backgroundColor:
                const WidgetStatePropertyAll(AppColors.danger),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
          ),
          child: _labelChild(),
        ),
      AppButtonKind.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(44, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _labelChild(),
        ),
    };
    if (!fullWidth) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  /// Label tombol — jadi spinner saat loading agar user tahu
  /// tap-nya sudah masuk dan aplikasi sedang bekerja.
  Widget _labelChild() {
    if (!isLoading) return Text(label);
    return const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}

enum AppButtonKind { primary, approve, danger, secondary }

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonStyle style;
  final bool isLoading;

  const _GradientButton({
    required this.label,
    this.onPressed,
    required this.style,
    this.isLoading = false,
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
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(label),
      ),
    );
  }
}
