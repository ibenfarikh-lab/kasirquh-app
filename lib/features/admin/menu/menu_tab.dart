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

/// Tab Menu: laci alat 16 modul admin.
/// Halaman penuh = ruang kerja; bottom sheet = panel tugas cepat.
/// Laporan tidak lagi modul sendiri — ada di dalam Data.
class MenuTab extends ConsumerWidget {
  const MenuTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          Strings.tabMenu,
          style: TextStyle(
            color: context.teksUtama,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children:
              _modules(context, ref).map((m) => _ModuleTile(module: m)).toList(),
        ),
      ],
    );
  }

  List<_Module> _modules(BuildContext context, WidgetRef ref) => [
        _Module(Strings.modulProduk, Icons.inventory_2_outlined,
            () => _openPage(context, const ProductsPage())),
        _Module(Strings.modulKasirOnline, Icons.shopping_bag_outlined,
            () => _openPage(context, const OnlineOrdersPage())),
        _Module(Strings.modulData, Icons.people_outline,
            () => _openPage(context, const CustomersPage())),
        _Module(Strings.modulChat, Icons.chat_bubble_outline,
            () => _openPage(context, const ChatPage())),
        _Module(Strings.modulPembukuan, Icons.book_outlined,
            () => _openPage(context, const LedgerPage())),
        _Module(Strings.modulKalkulator, Icons.calculate_outlined,
            () => _openSheet(context, const CalculatorSheet())),
        _Module(Strings.modulBelanjaStok, Icons.shopping_cart_outlined,
            () => _openSheet(context, const StockShoppingSheet())),
        _Module(Strings.modulCatatanToko, Icons.note_alt_outlined,
            () => _openSheet(context, const StoreNotesSheet())),
        _Module(Strings.modulKoin, Icons.toll_outlined,
            () => _openSheet(context, const CoinsSheet())),
        _Module(Strings.modulAiAdmin, Icons.psychology_outlined,
            () => _openSheet(context, const AiAdminSheet())),
        _Module(Strings.modulBuktiTransfer,
            Icons.receipt_long_outlined,
            () => _openPage(context, const TransferOrdersPage())),
        _Module(Strings.modulStruk, Icons.print_outlined,
            () => _openPage(context, const ReceiptPage())),
        _Module(Strings.modulScanner, Icons.qr_code_scanner,
            () => _openSheet(context, const ScannerSheet())),
        _Module(Strings.modulProfilToko, Icons.store_outlined,
            () => _openSheet(context, const StoreProfileSheet())),
        _Module(Strings.modulBerandaPelanggan, Icons.home_outlined,
            () => _openSheet(context, const CustomerHomeSheet())),
        _Module(Strings.modulPengaturan, Icons.settings_outlined,
            () => _openSheet(context, const SettingsSheet())),
        _Module(Strings.gantiKeModePelanggan, Icons.swap_horiz,
            () => _gantiKeModePelanggan(context, ref)),
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

class _Module {
  final String title;
  final IconData icon;
  final VoidCallback open;

  _Module(this.title, this.icon, this.open);
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
              const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(module.icon, color: AppColors.orange, size: 26),
              const SizedBox(height: 6),
              Text(
                module.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.teksUtama,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
