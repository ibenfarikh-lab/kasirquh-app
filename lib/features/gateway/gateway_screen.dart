import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/startup_report.dart';
import '../../data/remote/auth_service.dart';
import '../../data/repositories/store_repository.dart';
import '../../l10n/strings_id.dart';
import '../auth/pin_screen.dart';
import '../customer/customer_shell.dart';
import 'hidden_hotspot.dart';

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
  bool _navigated = false;

  /// Slide gateway — teks dari Pusat Kendali Beranda (store_settings/main),
  /// selaras PWA. Kicker (label slide) tetap statis seperti PWA.
  List<_Slide> _buildSlides(StoreInfo? store) {
    return [
      _Slide(
        image: 'assets/images/gateway/slide1.webp',
        kicker: Strings.slide1Kicker,
        title: store?.gatewayTitle1 ?? Strings.slide1Title,
        subtitle: store?.gatewayCopy1 ?? Strings.slide1Sub,
      ),
      _Slide(
        image: 'assets/images/gateway/slide2.webp',
        kicker: Strings.slide2Kicker,
        title: store?.gatewayTitle2 ?? Strings.slide2Title,
        subtitle: store?.gatewayCopy2 ?? Strings.slide2Sub,
      ),
      _Slide(
        image: 'assets/images/gateway/slide3.webp',
        kicker: Strings.slide3Kicker,
        title: store?.gatewayTitle3 ?? Strings.slide3Title,
        subtitle: store?.gatewayCopy3 ?? Strings.slide3Sub,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(slideDuration, (_) => _next());
  }

  void _next() {
    if (_index < 2) {
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
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CustomerShell()),
    );
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
    // Auth bisa null (mode lokal) → anggap belum login.
    final auth = ref.read(authServiceProvider);
    // Teks slide dari Pusat Kendali Beranda (live).
    final store = ref.watch(storeInfoProvider).valueOrNull;
    final slides = _buildSlides(store);
    return StreamBuilder(
      stream: auth?.authState() ?? Stream<User?>.value(null),
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
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlideView(slide: slides[i]),
              ),
              // Header: logo toko + nama warung + tagline (kiri atas,
              // ala prototipe). Hotspot admin tetap di kanan atas.
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 20,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.storefront,
                          color: AppColors.orange,
                          size: 30,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Warunge Mimi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Padding(
                      padding: EdgeInsets.only(left: 40),
                      child: Text(
                        Strings.taglineToko,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
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
                        slides.length,
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
              // Powered by KasirQuh (brand developer — bukan header)
              // + stempel versi build. Tap logo 1x → pintu admin (LogoTapGate).
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: LogoTapGate(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/kasirquh-logo.png',
                        width: 22,
                        height: 22,
                      ),
                      const SizedBox(width: 6),
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Strings.poweredBy,
                            style: TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                          Text(
                            Strings.versiApp,
                            style: TextStyle(
                                color: Colors.white24, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Peringatan bila ada init yang gagal (diagnosis, bukan error user).
              if (StartupReport.hasErrors)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 88, // hindari hotspot kanan atas
                  child: GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Info aplikasi'),
                        content: SingleChildScrollView(
                          child: Text(
                            StartupReport.errors.join('\n\n'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Tutup'),
                          ),
                        ],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Mode lokal: sebagian layanan gagal dimuat. Ketuk untuk detail.',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
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
  final String kicker;
  final String title;
  final String subtitle;
  const _Slide(
      {required this.image,
      required this.kicker,
      required this.title,
      required this.subtitle});
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
          bottom: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kicker ala prototipe: aksen + garis.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    slide.kicker,
                    style: const TextStyle(
                      // Aturan 2: oranye tunggal.
                      color: AppColors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white54,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    Strings.gatewayHint,
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
