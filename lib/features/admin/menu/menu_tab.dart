import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_nav.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/remote/auth_service.dart';
import '../../../l10n/strings_id.dart';
import '../../auth/biometric_credential_service.dart';
import '../../customer/customer_shell.dart';
import '../pos/scanner_sheet.dart';
import 'ai_admin_sheet.dart';
import 'calculator_sheet.dart';
import 'chat_page.dart';
import 'coins_sheet.dart';
import 'customer_home_sheet.dart';
import 'customers_page.dart';
import 'ledger_page.dart';
import 'online_orders_page.dart';
import 'products_page.dart';
import 'receipt_page.dart';
import 'settings_sheet.dart';
import 'stock_shopping_sheet.dart';
import 'store_notes_sheet.dart';
import 'store_profile_sheet.dart';
import 'transfer_orders_page.dart';

/// Tab Menu: "Semua alat & pengaturan" — struktur mengikuti PWA persis:
/// KELOLA WARUNG / LACI ALAT / PENGATURAN, tiap modul berdeskripsi.
/// Halaman penuh = ruang kerja; bottom sheet = panel tugas cepat.
class MenuTab extends ConsumerWidget {
  const MenuTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Kepala: kicker + judul (ikut PWA).
        Text(
          Strings.menuSemuaAlat,
          style: TextStyle(
              color: context.teksRedup, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          Strings.tabMenu,
          style: TextStyle(
            color: context.teksUtama,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: Strings.menuKelolaWarung),
        _ModuleGrid(modules: _kelolaWarung(context)),
        const SizedBox(height: 8),
        _SectionHeader(title: Strings.menuLaciAlat),
        _ModuleGrid(modules: _laciAlat(context)),
        const SizedBox(height: 8),
        _SectionHeader(title: Strings.menuPengaturanJudul),
        _ModuleGrid(
            modules: _pengaturan(context, ref)),
        const SizedBox(height: 24),
      ],
    );
  }

  /// KELOLA WARUNG — 7 modul (urutan PWA).
  List<_Module> _kelolaWarung(BuildContext context) => [
        _Module(
          Strings.menuProduk,
          Strings.descProduk,
          Icons.inventory_2_outlined,
          () => _openPage(context, const ProductsPage()),
        ),
        _Module(
          Strings.modulProfilToko,
          Strings.descProfilToko,
          Icons.store_outlined,
          () => _openSheet(context, const StoreProfileSheet()),
        ),
        _Module(
          Strings.modulBerandaPelanggan,
          Strings.descBerandaPelanggan,
          Icons.home_outlined,
          () => _openSheet(context, const CustomerHomeSheet()),
        ),
        _Module(
          Strings.modulKoin,
          Strings.descKoinWarga,
          Icons.toll_outlined,
          () => _openSheet(context, const CoinsSheet()),
        ),
        _Module(
          Strings.modulKasirOnline,
          Strings.descKasirOnline,
          Icons.shopping_bag_outlined,
          () => _openPage(context, const OnlineOrdersPage()),
        ),
        _Module(
          Strings.modulData,
          Strings.descData,
          Icons.people_outline,
          () => _openPage(context, const CustomersPage()),
        ),
        _Module(
          Strings.modulChat,
          Strings.descChat,
          Icons.chat_bubble_outline,
          () => _openPage(context, const ChatPage()),
        ),
      ];

  /// LACI ALAT — 9 modul (urutan PWA).
  List<_Module> _laciAlat(BuildContext context) => [
        _Module(
          Strings.modulKalkulator,
          Strings.descKalkulator,
          Icons.calculate_outlined,
          () => _openSheet(context, const CalculatorSheet()),
        ),
        _Module(
          Strings.menuPemindaiBarcode,
          Strings.descPemindaiBarcode,
          Icons.qr_code_scanner,
          () => _openSheet(context, const ScannerSheet()),
        ),
        _Module(
          Strings.modulCatatanToko,
          Strings.descCatatanToko,
          Icons.note_alt_outlined,
          () => _openSheet(context, const StoreNotesSheet()),
        ),
        _Module(
          Strings.modulBelanjaStok,
          Strings.descBelanjaStok,
          Icons.shopping_cart_outlined,
          () => _openSheet(context, const StockShoppingSheet()),
        ),
        _Module(
          Strings.modulAiAdmin,
          Strings.descAiAdmin,
          Icons.psychology_outlined,
          () => _openSheet(context, const AiAdminSheet()),
        ),
        _Module(
          Strings.modulPembukuan,
          Strings.descPembukuan,
          Icons.book_outlined,
          () => _openPage(context, const LedgerPage()),
        ),
        _Module(
          Strings.menuKonfirmasiTransfer,
          Strings.descKonfirmasiTransfer,
          Icons.receipt_long_outlined,
          () => _openPage(context, const TransferOrdersPage()),
        ),
        _Module(
          Strings.menuPatunganWarga,
          Strings.descPatunganWarga,
          Icons.groups_outlined,
          () => _openSheet(
              context, const _SegeraHadirSheet()),
        ),
        _Module(
          Strings.modulStruk,
          Strings.descStruk58mm,
          Icons.print_outlined,
          () => _openPage(context, const ReceiptPage()),
        ),
      ];

  /// PENGATURAN — 2 modul (urutan PWA).
  List<_Module> _pengaturan(
      BuildContext context, WidgetRef ref) => [
        _Module(
          Strings.gantiKeModePelanggan,
          Strings.descGantiModePelanggan,
          Icons.swap_horiz,
          () => _gantiKeModePelanggan(context, ref),
        ),
        _Module(
          Strings.menuPengaturanGlobal,
          Strings.descPengaturanGlobal,
          Icons.settings_outlined,
          () => _openSheet(context, const SettingsSheet()),
        ),
      ];

  void _openPage(BuildContext context, Widget page) {
    openAdminPage(context, page);
  }

  void _openSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Opsi A: hapus backgroundColor transparent — ikut bottomSheetTheme (solid, adaptif).
      builder: (_) => sheet,
    );
  }

  /// Ganti ke Mode Pelanggan via sidik jari.
  /// Alur: biometric → baca kredensial pelanggan → signOut → signIn → CustomerShell.
  Future<void> _gantiKeModePelanggan(
      BuildContext context, WidgetRef ref) async {
    final svc = ref.read(biometricCredentialServiceProvider);
    // 1. Verifikasi biometric.
    final ok = await svc.verifyBiometric(Strings.alasanVerifikasiSidikJari);
    if (!ok || !context.mounted) return;
    // 2. Baca kredensial pelanggan tersimpan.
    final cred = await svc.read('customer');
    if (cred == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Belum ada akun pelanggan tersimpan. '
                'Masuk sebagai pelanggan dulu lalu aktifkan login cepat.'),
          ),
        );
      }
      return;
    }
    // 3. Sign out admin, sign in sebagai pelanggan.
    final auth = ref.read(authServiceProvider);
    if (auth == null) return;
    try {
      await auth.signOut();
      await auth.signIn(email: cred.email, password: cred.password);
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CustomerShell()),
          (_) => false,
        );
      }
    } catch (_) {
      // Kredensial basi → hapus, minta login manual.
      await svc.delete('customer');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.masukGagal)),
        );
      }
    }
  }
}

/// Judul seksi menu (KELOLA WARUNG / LACI ALAT / PENGATURAN).
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: context.teksRedup,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Grid 3 kolom ala PWA untuk satu seksi.
class _ModuleGrid extends StatelessWidget {
  final List<_Module> modules;

  const _ModuleGrid({required this.modules});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.92,
      children:
          modules.map((m) => _ModuleTile(module: m)).toList(),
    );
  }
}

class _Module {
  final String title;
  final String desc;
  final IconData icon;
  final VoidCallback open;

  _Module(this.title, this.desc, this.icon, this.open);
}

class _ModuleTile extends StatelessWidget {
  final _Module module;

  const _ModuleTile({required this.module});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.permukaanKartu, // Aturan 1&3: adaptif.
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: module.open,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(module.icon,
                  color: AppColors.orange, size: 24),
              const SizedBox(height: 8),
              Text(
                module.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.teksUtama,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Text(
                  module.desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.teksRedup,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder jujur: Patungan Warga native belum dibangun.
/// Tap → info, tanpa ubah data apa pun.
class _SegeraHadirSheet extends StatelessWidget {
  const _SegeraHadirSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.groups_outlined,
                    color: AppColors.orange, size: 28),
                const SizedBox(width: 12),
                Text(
                  Strings.menuPatunganWarga,
                  style: TextStyle(
                    color: context.teksUtama,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              Strings.patunganSegeraHadir,
              style: TextStyle(
                  color: context.teksRedup, fontSize: 14),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
