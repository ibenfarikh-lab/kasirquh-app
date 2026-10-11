import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/product_photo.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../l10n/strings_id.dart';
import '../session.dart';

/// Tebak Harga — ikut PWA (renderGuessGame, answerGuess).
/// Soal acak dari katalog (1x sehari), 3 pilihan jawaban.
/// Benar → koin otomatis via grantCoins (reason: tebak_harga).
class TebakHargaPage extends ConsumerStatefulWidget {
  const TebakHargaPage({super.key});

  @override
  ConsumerState<TebakHargaPage> createState() => _TebakHargaPageState();
}

/// Buat 2 opsi pengecoh yang wajar (kelipatan Rp500) untuk Tebak Harga.
/// Diambil acak dari kelipatan 500 dalam ±40% harga asli; bila kandidat
/// kurang (mis. harga kecil), fallback ke kelipatan 500 terdekat.
/// Dijamin: kelipatan 500, positif, tidak sama dengan harga asli.
/// Fungsi pure (bisa di-test).
List<int> buatPengecoh(int hargaAsli, Random rand) {
  final kandidat = <int>{};
  final bawah = (hargaAsli * 0.6 / 500).floor() * 500;
  final atas = (hargaAsli * 1.4 / 500).ceil() * 500;
  for (var p = bawah; p <= atas; p += 500) {
    if (p > 0 && p != hargaAsli) kandidat.add(p);
  }
  final acak = kandidat.toList()..shuffle(rand);
  final hasil = acak.take(2).toList();
  var delta = 500;
  while (hasil.length < 2 && delta <= 20000) {
    for (final p in [hargaAsli + delta, hargaAsli - delta]) {
      final pr = (p / 500).round() * 500;
      if (pr > 0 && pr != hargaAsli && !hasil.contains(pr)) {
        hasil.add(pr);
      }
      if (hasil.length >= 2) break;
    }
    delta += 500;
  }
  return hasil;
}

class _TebakHargaPageState extends ConsumerState<TebakHargaPage> {
  Product? _soal;
  List<int> _pilihan = [];
  int? _jawabanDipilih;
  bool _sudahJawab = false;
  bool _busy = false;

  /// Pilih soal acak + buat 2 pengecoh (kelipatan Rp500, wajar).
  void _acakSoal(List<Product> produk) {
    if (produk.isEmpty) return;
    final rand = Random();
    final soal = produk[rand.nextInt(produk.length)];
    final hargaAsli = soal.price;

    final pengecoh = buatPengecoh(hargaAsli, rand);
    final semua = [hargaAsli, ...pengecoh]..shuffle(rand);
    setState(() {
      _soal = soal;
      _pilihan = semua;
      _jawabanDipilih = null;
      _sudahJawab = false;
    });
  }

  Future<void> _jawab(int hargaDipilih) async {
    if (_sudahJawab || _busy || _soal == null) return;

    final session = ref.read(sessionProvider).valueOrNull;
    final uid = session == null || session.isGuest ? null : session.user?.uid;
    if (uid == null) return;

    setState(() {
      _jawabanDipilih = hargaDipilih;
      _sudahJawab = true;
    });

    final benar = hargaDipilih == _soal!.price;
    if (!benar) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Kurang tepat. Harga aslinya ${formatRp(_soal!.price)}.'),
          ),
        );
      }
      return;
    }

    // Benar → beri koin otomatis.
    setState(() => _busy = true);
    try {
      final settings = ref.read(coinSettingsProvider).valueOrNull ??
          const CoinSettings();
      final reward = settings.rewards['guess'] ?? 10;

      await ref.read(adminRepositoryProvider).grantCoins(
            uid,
            reward,
            reason: 'tebak_harga',
            label: 'Tebak harga benar',
            detail: _soal!.name,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Benar! +$reward koin untukmu!')),
        );
        ref.invalidate(sessionProvider);
      }
    } on StateError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal, coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).valueOrNull;
    final uid = session == null || session.isGuest ? null : session.user?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tebak Harga')),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: Strings.guestLockTitle,
          hint: Strings.guestLockBody,
        ),
      );
    }

    final settings =
        ref.watch(coinSettingsProvider).valueOrNull ?? const CoinSettings();
    if (!settings.enabled || !(settings.events['guess'] ?? false)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tebak Harga')),
        body: const EmptyState(
          icon: Icons.games_outlined,
          title: 'Permainan nonaktif',
          hint: 'Tebak harga sedang dimatikan admin.',
        ),
      );
    }

    final produkAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tebak Harga')),
      body: produkAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyState(
          icon: Icons.cloud_off_outlined,
          title: Strings.gagalMuatProduk,
          hint: Strings.periksaKoneksi,
        ),
        data: (produk) {
          final aktif =
              produk.where((p) => p.active).toList();
          if (aktif.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Belum ada produk',
              hint: 'Tunggu warung menambah produk.',
            );
          }

          // Pilih soal saat pertama kali.
          if (_soal == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _soal == null) _acakSoal(aktif);
            });
            return const Center(
                child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Tebak harga produk ini:',
                style: TextStyle(
                  color: context.teksRedup,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  children: [
                    ProductPhoto(
                      photoPath: _soal!.photoPath,
                      size: 120,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _soal!.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _soal!.unit,
                      style: TextStyle(
                          color: context.teksRedup, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final harga in _pilihan)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    onTap: _sudahJawab
                        ? null
                        : () => _jawab(harga),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatRp(harga),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_sudahJawab &&
                            harga == _soal!.price)
                          const Icon(Icons.check_circle,
                              color: Colors.green),
                        if (_sudahJawab &&
                            harga == _jawabanDipilih &&
                            harga != _soal!.price)
                          const Icon(Icons.cancel,
                              color: Colors.red),
                      ],
                    ),
                  ),
                ),
              if (_sudahJawab) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _acakSoal(aktif),
                    child: const Text('Soal baru'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
