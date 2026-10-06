import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/guest_lock_sheet.dart';
import '../../l10n/strings_id.dart';
import '../gateway/hidden_hotspot.dart';
import 'account/account_tab.dart';
import 'cart/cart_provider.dart';
import 'cart/cart_tab.dart';
import 'catalog/catalog_tab.dart';
import 'chat/chat_tab.dart';
import 'home/home_tab.dart';
import 'session.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: LogoTapGate(
          child: const Text(
            Strings.appName,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
        ),
        centerTitle: false,
      ),
      body: IndexedStack(
        index: index,
        children: const [
          HomeTab(),
          CatalogTab(),
          CartTab(),
          ChatTab(),
          AccountTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.muted,
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
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: Strings.tabChat,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: Strings.tabAkun,
          ),
        ],
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
