import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../core/theme/theme_settings.dart';
import '../../core/widgets/guest_lock_sheet.dart';
import '../../data/repositories/social_repository.dart';
import '../../data/repositories/store_repository.dart';
import '../../l10n/strings_id.dart';
import '../gateway/hidden_hotspot.dart';
import 'account/account_tab.dart';
import 'cart/cart_provider.dart';
import 'cart/cart_tab.dart';
import 'catalog/catalog_tab.dart';
import 'chat/chat_tab.dart';
import 'home/home_tab.dart';
import 'push_bootstrap.dart';
import 'session.dart';
import 'teman_belanja/teman_belanja_sheet.dart';

/// Tab aktif Mode Pelanggan — bisa diubah dari tab lain (mis. Beranda → Produk).
final customerTabProvider = StateProvider<int>((ref) => 0);

/// Mode Pelanggan: 5 Tab (Beranda · Produk · Keranjang · Chat · Akun).
/// Chat & Akun bergembok untuk tamu — ketuk → prompt login,
/// lalu otomatis diteruskan ke tab yang dituju.
class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key});

  static const _lockedTabs = {3, 4}; // Chat, Akun

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(customerTabProvider);
    final cartCount =
        ref.watch(cartProvider.select((c) => c.fold(0, (s, e) => s + e.qty)));
    final session = ref.watch(sessionProvider).valueOrNull;
    final uid = memberUid(session ?? const Session.guest());
    final unreadChat = uid == null
        ? 0
        : ref.watch(myTokoThreadProvider(uid)).valueOrNull?.unreadCustomer ??
            0;
    final tema = ref.watch(temaPelangganProvider);
    final sistem =
        MediaQuery.platformBrightnessOf(context);
    // Header harmonisasi PWA (keputusan user 2026-10-09): background PUTIH,
    // sapaan waktu + status BUKA/TUTUP + badge keranjang.
    final store = ref.watch(storeInfoProvider).valueOrNull;
    final isGuest = session == null || session.isGuest;
    final jam = DateTime.now().hour;
    final sapaan = isGuest
        ? 'Mode tamu'
        : jam < 11
            ? 'Selamat pagi'
            : jam < 15
                ? 'Selamat siang'
                : jam < 19
                    ? 'Selamat sore'
                    : 'Selamat malam';
    final buka = store?.isOpenNow;

    return Theme(
      data: temaPelangganAktif(tema, sistem),
      child: Scaffold(
        appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: LogoTapGate(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront, color: AppColors.orange),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sapaan,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      (store?.storeName.isNotEmpty ?? false)
                          ? store!.storeName
                          : Strings.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        centerTitle: false,
        actions: [
          if (buka != null)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: buka
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: buka ? Colors.green[700] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    buka ? 'BUKA' : 'TUTUP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: buka ? Colors.green[800] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            tooltip: Strings.tabKeranjang,
            onPressed: () =>
                ref.read(customerTabProvider.notifier).state = 2,
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              backgroundColor: AppColors.danger,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: index,
            children: const [
              HomeTab(),
              CatalogTab(),
              CartTab(),
              ChatTab(),
              AccountTab(),
            ],
          ),
          // Tak kasat mata: izin notifikasi + pantau pesanan/chat.
          if (uid != null) ...[
            PushBootstrap(uid: uid),
            OrderStatusWatcher(uid: uid),
            TokoUnreadWatcher(uid: uid),
          ],
        ],
      ),
      // Teman Belanja ala PWA: FAB kotak hitam + ikon sparkle,
      // hanya di tab Beranda.
      floatingActionButton: index == 0
          ? FloatingActionButton(
              tooltip: 'Buka Teman Belanja',
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onPressed: () => showTemanBelanjaSheet(context, ref),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
              ),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: context.teksRedup,
        onTap: (i) => _onTap(context, ref, i),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: Strings.tabBeranda,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: Strings.tabProduk,
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              backgroundColor: AppColors.orange,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              backgroundColor: AppColors.orange,
              child: const Icon(Icons.shopping_cart),
            ),
            label: Strings.tabKeranjang,
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: unreadChat > 0,
              label: Text('$unreadChat'),
              backgroundColor: AppColors.danger,
              child: const Icon(Icons.chat_bubble_outline),
            ),
            activeIcon: Badge(
              isLabelVisible: unreadChat > 0,
              label: Text('$unreadChat'),
              backgroundColor: AppColors.danger,
              child: const Icon(Icons.chat_bubble),
            ),
            label: Strings.tabChat,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: Strings.tabAkun,
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref, int i) async {
    if (_lockedTabs.contains(i)) {
      final session = ref.read(sessionProvider).valueOrNull;
      if (session == null || session.isGuest) {
        // Tamu → kunci, lalu teruskan otomatis bila berhasil masuk.
        await requireLogin(context, ref, () async {
          ref.read(customerTabProvider.notifier).state = i;
        });
        return;
      }
    }
    ref.read(customerTabProvider.notifier).state = i;
  }
}
