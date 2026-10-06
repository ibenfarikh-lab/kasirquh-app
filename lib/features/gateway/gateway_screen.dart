import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/remote/auth_service.dart';
import '../../l10n/strings_id.dart';
import '../auth/pin_screen.dart';

/// Gateway: 3 slide promo full-bleed @4000ms, dots, swipe/tap/Lewati.
/// Otomatis masuk Mode Pelanggan (tamu) setelah slide ke-3.
/// Yang sudah login → langsung skip. Hotspot admin tersembunyi (tak terlihat).
class GatewayScreen extends ConsumerStatefulWidget {
  const GatewayScreen({super.key});

  @override
  ConsumerState<GatewayScreen> createState() => _GatewayScreenState();
}

class _GatewayScreenState extends ConsumerState<GatewayScreen> {
  static const slideDuration = Duration(milliseconds: 4000);
  final _page = PageController();
  int _index = 0;
  Timer? _timer;

  static const _slides = [
    _Slide(
      image: 'assets/images/gateway/slide1.webp',
      title: Strings.slide1Title,
      subtitle: Strings.slide1Sub,
    ),
    _Slide(
      image: 'assets/images/gateway/slide2.webp',
      title: Strings.slide2Title,
      subtitle: Strings.slide2Sub,
    ),
    _Slide(
      image: 'assets/images/gateway/slide3.webp',
      title: Strings.slide3Title,
      subtitle: Strings.slide3Sub,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(slideDuration, (_) => _next());
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _page.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _enterAsGuest();
    }
  }

  void _enterAsGuest() {
    _timer?.cancel();
    // TODO(fase-2): navigasi ke Mode Pelanggan (tamu).
    // Sementara: tampilkan penanda — diganti router saat fitur pelanggan jadi.
    debugPrint('Gateway → Mode Pelanggan (tamu)');
  }

  /// Hotspot admin tersembunyi: area tak terlihat di pojok kanan atas.
  void _openAdminGate() {
    _timer?.cancel();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PinScreen()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ref.read(authServiceProvider).authState(),
      builder: (context, snap) {
        if (snap.data != null) {
          // Sudah login → skip gateway.
          WidgetsBinding.instance.addPostFrameCallback((_) => _enterAsGuest());
        }
        return Scaffold(
          backgroundColor: AppColors.adminBg,
          body: Stack(
            children: [
              PageView.builder(
                controller: _page,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
              // Dots + Lewati
              Positioned(
                left: 0,
                right: 0,
                bottom: 48,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _index == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _index == i
                                ? AppColors.orange
                                : Colors.white38,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _enterAsGuest,
                      child: const Text(
                        Strings.lewati,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              // Hotspot admin tersembunyi (tak terlihat, 64x64 di kanan atas).
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _openAdminGate,
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(width: 64, height: 64),
                ),
              ),
              // Powered by KasirQuh (brand developer — bukan header).
              const Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Text(
                  Strings.poweredBy,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Slide {
  final String image;
  final String title;
  final String subtitle;
  const _Slide(
      {required this.image, required this.title, required this.subtitle});
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(slide.image, fit: BoxFit.cover),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slide.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                slide.subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
