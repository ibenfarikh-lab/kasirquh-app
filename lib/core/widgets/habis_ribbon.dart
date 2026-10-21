import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Penanda HABIS gaya Web (keputusan user 2026-10-20, P2-6):
/// pita diagonal merah (#d63a2f) di pojok kiri-atas + foto greyout
/// ringan. Menggantikan pill abu-abu lama. Pasang di dalam Stack
/// yang di-clip (ClipRRect/ClipRect) agar pita terpotong rapi
/// di tepi kartu — persis `.out-ribbon` Web.
class HabisRibbon extends StatelessWidget {
  /// Varian kecil untuk kartu mini (quick/popular Web).
  final bool kecil;

  const HabisRibbon({super.key, this.kecil = false});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: kecil ? 11 : 15,
      left: kecil ? -32 : -40,
      child: Transform.rotate(
        angle: -38 * math.pi / 180,
        child: Container(
          width: kecil ? 104 : 132,
          padding: EdgeInsets.symmetric(vertical: kecil ? 3 : 4),
          decoration: const BoxDecoration(
            color: Color(0xFFD63A2F),
            boxShadow: [
              BoxShadow(
                color: Color(0x47000000),
                blurRadius: 7,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'HABIS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: kecil ? 8 : 10,
              fontWeight: FontWeight.w900,
              letterSpacing: kecil ? 1.5 : 2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Greyout ringan foto produk habis (Web: grayscale(.7) opacity(.8))
/// — foto tetap terlihat, hanya dibuat pucat.
Widget fotoHabisGreyout(Widget child) {
  const s = 0.3; // sisa saturasi (grayscale 0.7)
  return Opacity(
    opacity: 0.8,
    child: ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126 + 0.7874 * s, 0.7152 - 0.7152 * s, 0.0722 - 0.0722 * s, 0, 0,
        0.2126 - 0.2126 * s, 0.7152 + 0.2848 * s, 0.0722 - 0.0722 * s, 0, 0,
        0.2126 - 0.2126 * s, 0.7152 - 0.7152 * s, 0.0722 + 0.9278 * s, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: child,
    ),
  );
}
