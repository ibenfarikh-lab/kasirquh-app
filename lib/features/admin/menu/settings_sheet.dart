import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_settings.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/theme_picker.dart';
import '../../../data/remote/auth_service.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../l10n/strings_id.dart';
import '../../admin/admin_session.dart';
import '../../auth/biometric_messages.dart';

/// Pengaturan — 5 grup global (Tampilan, Notifikasi, Developer, Tentang, Akun).
class SettingsSheet extends ConsumerStatefulWidget {
  const SettingsSheet({super.key});

  @override
  ConsumerState<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<SettingsSheet> {
  bool _notifPesanan = true;
  bool _notifChat = true;
  bool _notifStok = true;
  bool _sidikJariAktif = true;
  bool _sidikJariDidukung = false;

  @override
  void initState() {
    super.initState();
    _muatNotifikasi();
    _muatSidikJari();
  }

  /// Muat saklar sidik jari + kemampuan perangkat.
  Future<void> _muatSidikJari() async {
    final prefs = await SharedPreferences.getInstance();
    final didukung = await sidikJariTersedia();
    if (!mounted) return;
    setState(() {
      _sidikJariAktif = prefs.getBool(kunciSidikJariAktif) ?? true;
      _sidikJariDidukung = didukung;
    });
  }

  /// Saklar sidik jari: menyalakan = "daftar" (buktikan sidik jari
  /// terdaftar & berfungsi); mematikan = langsung mati.
  Future<void> _toggleSidikJari(bool v) async {
    if (v) {
      try {
        final ok = await LocalAuthentication().authenticate(
          localizedReason: Strings.alasanAktifkanSidikJari,
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
        if (!mounted) return;
        if (ok) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(kunciSidikJariAktif, true);
          setState(() => _sidikJariAktif = true);
        }
        // Dibatalkan → biarkan mati, tanpa pesan seram.
      } on PlatformException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pesanGalatSidikJari(e.code))),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.sidikJariTidakTersedia)),
        );
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kunciSidikJariAktif, false);
    if (mounted) setState(() => _sidikJariAktif = false);
  }

  Future<void> _muatNotifikasi() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifPesanan = prefs.getBool('notif_pesanan_baru') ?? true;
      _notifChat = prefs.getBool('notif_chat') ?? true;
      _notifStok = prefs.getBool('notif_stok_menipis') ?? true;
    });
  }

  Future<void> _simpanNotifikasi(String kunci, bool nilai) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kunci, nilai);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.adminLine,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _judulGrup(Strings.grupTampilan),
              _kartu([
                ListTile(
                  title: const Text(
                    'Tema',
                    style: TextStyle(color: AppColors.warmText),
                  ),
                  subtitle: Text(
                    ref.watch(temaAdminProvider).label,
                    style:
                        const TextStyle(color: AppColors.warmMuted),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.warmMuted,
                  ),
                  onTap: () =>
                      showThemePicker(context, temaAdminProvider),
                ),
              ]),
              _judulGrup(Strings.grupNotifikasi),
              _kartu([
                _saklar(
                  Strings.notifPesananBaru,
                  _notifPesanan,
                  (v) => setState(() {
                    _notifPesanan = v;
                    _simpanNotifikasi('notif_pesanan_baru', v);
                  }),
                ),
                _saklar(
                  Strings.notifChat,
                  _notifChat,
                  (v) => setState(() {
                    _notifChat = v;
                    _simpanNotifikasi('notif_chat', v);
                  }),
                ),
                _saklar(
                  Strings.notifStokMenipis,
                  _notifStok,
                  (v) => setState(() {
                    _notifStok = v;
                    _simpanNotifikasi('notif_stok_menipis', v);
                  }),
                ),
              ]),
              _judulGrup(Strings.grupDeveloper),
              _kartu([
                ListTile(
                  title: Text(
                    Strings.infoSesi,
                    style: const TextStyle(color: AppColors.warmText),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.warmMuted,
                  ),
                  onTap: () => _dialogInfoSesi(context, ref),
                ),
                ListTile(
                  title: const Text(
                    'Batas stok menipis',
                    style: TextStyle(color: AppColors.warmText),
                  ),
                  subtitle: Text(
                    '${ref.watch(storeInfoProvider).valueOrNull?.lowStockDefault ?? 5} pcs',
                    style: const TextStyle(color: AppColors.warmMuted),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.warmMuted,
                  ),
                  onTap: () => _dialogAngka(
                    context,
                    ref,
                    judul: 'Batas stok menipis',
                    nilaiAwal: ref
                            .read(storeInfoProvider)
                            .valueOrNull
                            ?.lowStockDefault ??
                        5,
                    kunci: 'lowStockDefault',
                  ),
                ),
                ListTile(
                  title: const Text(
                    'Nilai koin',
                    style: TextStyle(color: AppColors.warmText),
                  ),
                  subtitle: Text(
                    () {
                      final rate =
                          ref.watch(storeInfoProvider).valueOrNull?.coinRate ??
                              0;
                      // Jujur: belum diatur (0) ≠ Rp0 per koin.
                      if (rate <= 0) return Strings.belumDiatur;
                      return '${formatRp(rate)} per koin';
                    }(),
                    style: const TextStyle(color: AppColors.warmMuted),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.warmMuted,
                  ),
                  onTap: () => _dialogAngka(
                    context,
                    ref,
                    judul: 'Nilai koin',
                    nilaiAwal: ref.read(storeInfoProvider).valueOrNull?.coinRate ?? 0,
                    kunci: 'coinRate',
                  ),
                ),
              ]),
              _judulGrup(Strings.grupTentang),
              _kartu([
                ListTile(
                  leading: Image.asset(
                    'assets/brand/kasirquh-logo.png',
                    width: 40,
                    height: 40,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.storefront,
                      size: 40,
                      color: AppColors.orange,
                    ),
                  ),
                  title: const Text(
                    'KasirQuh',
                    style: TextStyle(
                      color: AppColors.warmText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: const Text(
                    '${Strings.versiApp}\nWarunge Mimi · Powered by KasirQuh',
                    style: TextStyle(color: AppColors.warmMuted),
                  ),
                  isThreeLine: true,
                ),
                ListTile(
                  title: const Text(
                    'Aturan & privasi',
                    style: TextStyle(color: AppColors.warmText),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.warmMuted,
                  ),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (ctx) => const AlertDialog(
                      backgroundColor: AppColors.panel2,
                      title: Text(
                        'Aturan & privasi',
                        style: TextStyle(color: AppColors.warmText),
                      ),
                      content: Text(
                        'Data tersimpan di HP ini dan disinkron ke server toko.',
                        style: TextStyle(color: AppColors.warmMuted),
                      ),
                    ),
                  ),
                ),
              ]),
              _judulGrup(Strings.grupAkun),
              _kartu([
                SwitchListTile(
                  value: _sidikJariAktif && _sidikJariDidukung,
                  activeThumbColor: AppColors.orange,
                  secondary: const Icon(
                    Icons.fingerprint,
                    color: AppColors.orange,
                  ),
                  title: const Text(
                    Strings.bukaDenganSidikJari,
                    style: TextStyle(color: AppColors.warmText),
                  ),
                  subtitle: Text(
                    _sidikJariDidukung
                        ? Strings.bukaDenganSidikJariHint
                        : Strings.sidikJariTakDidukung,
                    style: const TextStyle(color: AppColors.warmMuted),
                  ),
                  onChanged:
                      _sidikJariDidukung ? _toggleSidikJari : null,
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.danger),
                  title: Text(
                    Strings.keluarAdmin,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                  onTap: () => _konfirmasiKeluar(context, ref),
                ),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _judulGrup(String judul) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        judul,
        style: const TextStyle(
          color: AppColors.warmMuted,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _kartu(List<Widget> children) {
    return Card(
      // Aturan 3: kartu = L2.
      color: AppColors.panel,
      margin: const EdgeInsets.only(bottom: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(children: children),
    );
  }

  Widget _saklar(String judul, bool nilai, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: nilai,
      activeThumbColor: AppColors.orange,
      title: Text(judul, style: const TextStyle(color: AppColors.warmText)),
      onChanged: onChanged,
    );
  }

  void _dialogInfoSesi(BuildContext context, WidgetRef ref) {
    final email = ref.read(adminSessionProvider).valueOrNull?.email ?? '-';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel2,
        title: Text(
          Strings.infoSesi,
          style: const TextStyle(color: AppColors.warmText),
        ),
        content: Text(
          email,
          style: const TextStyle(color: AppColors.warmMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              Strings.tutup,
              style: const TextStyle(color: AppColors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _dialogAngka(
    BuildContext context,
    WidgetRef ref, {
    required String judul,
    required int nilaiAwal,
    required String kunci,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final c = TextEditingController(text: nilaiAwal.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel2,
        title: Text(
          judul,
          style: const TextStyle(color: AppColors.warmText),
        ),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: AppColors.warmText),
          decoration: InputDecoration(
            filled: true,
            // Aturan 3: input = L3.
            fillColor: AppColors.panel2,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.adminLine),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.orange),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              Strings.batal,
              style: const TextStyle(color: AppColors.warmMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              Strings.simpan,
              style: TextStyle(color: AppColors.orange),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final nilai = int.tryParse(c.text);
    if (nilai == null) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .saveStoreSettings({kunci: nilai});
      messenger.showSnackBar(
        SnackBar(content: Text(Strings.berhasilDisimpan)),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(Strings.butuhInternetAdmin)),
      );
    }
  }

  Future<void> _konfirmasiKeluar(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel2,
        title: Text(
          Strings.yakinKeluar,
          style: const TextStyle(color: AppColors.warmText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              Strings.batal,
              style: const TextStyle(color: AppColors.warmMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              Strings.keluar,
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final auth = ref.read(authServiceProvider);
    await auth?.signOut();
    navigator.popUntil((r) => r.isFirst);
  }
}
