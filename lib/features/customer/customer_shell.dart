import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../core/widgets/guest_lock_sheet.dart';
import '../../data/repositories/social_repository.dart';
import '../../data/repositories/store_repository.dart';
import '../../l10n/strings_id.dart';
import '../gateway/hidden_hotspot.dart';
import 'account/account_tab.dart';
import 'account/dompet_koin_page.dart';
import 'cart/cart_provider.dart';
import 'cart/cart_tab.dart';
import 'catalog/catalog_tab.dart';
import 'chat/chat_tab.dart';
import 'home/home_tab.dart';
import 'push_bootstrap.dart';
import 'session.dart';
import 'teman_belanja/teman_belanja_sheet.dart';

final customerTabProvider = StateProvider<int>((ref) => 0);

class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key});

  static const _lockedTabs = {3, 4};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(customerTabProvider);
    final cartCount = ref.watch(cartProvider
        .select((c) => c.fold(0.0, (s, e) => s + e.qty).round()));
    final session = ref.watch(sessionProvider).valueOrNull;
    final uid = memberUid(session ?? const Session.guest());
    final isGuest = session == null || session.isGuest;
    final bool tabTerkunciAktif = isGuest && _lockedTabs.contains(index);
    final int tampilIndex = tabTerkunciAktif ? 0 : index;
    final unreadChat = uid == null
        ? 0
        : ref.watch(myTokoThreadProvider(uid)).valueOrNull?.unreadCustomer ??
            0;

    return Scaffold(
        appBar: tampilIndex == 0
            ? _berandaHeader(context, ref, session)
            : tampilIndex >= 1 && tampilIndex <= 4
                ? null
                : AppBar(
                title: LogoTapGate(
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storefront, color: AppColors.orange),
                      SizedBox(width: 8),
                      Text(
                        Strings.appName,
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                centerTitle: false,
              ),
      body: tampilIndex == 0
          ? Stack(
              children: [
                IndexedStack(
                  index: tampilIndex,
                  children: const [
                    HomeTab(),
                    CatalogTab(),
                    CartTab(),
                    ChatTab(),
                    AccountTab(),
                  ],
                ),
                if (tabTerkunciAktif) const _GerbangTabTerkunci(),
                if (uid != null) ...[
                  PushBootstrap(uid: uid),
                  OrderStatusWatcher(uid: uid),
                  TokoUnreadWatcher(uid: uid),
                ],
              ],
            )
          : SafeArea(
              top: true,
              bottom: false,
              child: Stack(
                children: [
                  IndexedStack(
                    index: tampilIndex,
                    children: const [
                      HomeTab(),
                      CatalogTab(),
                      CartTab(),
                      ChatTab(),
                      AccountTab(),
                    ],
                  ),
                  if (tabTerkunciAktif) const _GerbangTabTerkunci(),
                  if (uid != null) ...[
                    PushBootstrap(uid: uid),
                    OrderStatusWatcher(uid: uid),
                    TokoUnreadWatcher(uid: uid),
                  ],
                ],
              ),
            ),
      floatingActionButton: tampilIndex == 0
          ? FloatingActionButton(
              tooltip: 'Buka Teman Belanja',
              backgroundColor: AppColors.orange,
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
              child: _denganGembok(
                  const Icon(Icons.chat_bubble_outline), isGuest),
            ),
            activeIcon: Badge(
              isLabelVisible: unreadChat > 0,
              label: Text('$unreadChat'),
              backgroundColor: AppColors.danger,
              child:
                  _denganGembok(const Icon(Icons.chat_bubble), isGuest),
            ),
            label: Strings.tabChat,
          ),
          BottomNavigationBarItem(
            icon: _denganGembok(const Icon(Icons.person_outline), isGuest),
            activeIcon: _denganGembok(const Icon(Icons.person), isGuest),
            label: Strings.tabAkun,
          ),
        ],
      ),
    );
  }

  Widget _denganGembok(Widget ikon, bool tampil) {
    if (!tampil) return ikon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ikon,
        Positioned(
          top: -4,
          right: -6,
          child: Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              color: Color(0xFF33261A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock,
              size: 9,
              color: AppColors.orange,
            ),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _berandaHeader(
      BuildContext context, WidgetRef ref, Session? session) {
    final store = ref.watch(storeInfoProvider).valueOrNull;
    final isGuest = session == null || session.isGuest;
    final jam = DateTime.now().hour;
    final sapaan = isGuest
        ? 'Mode tamu · harga & stok terbuka'
        : jam < 11
            ? 'Selamat pagi'
            : jam < 15
                ? 'Selamat siang'
                : jam < 19
                    ? 'Selamat sore'
                    : 'Selamat malam';
    final buka = store?.isOpenNow;
    final koin = (session != null && !session.isGuest) ? session.coins : 0;

    void bukaKoin() {
      if (session == null || session.isGuest) {
        requireLogin(context, ref, () async {});
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DompetKoinPage()),
      );
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF9B3E), Color(0xFFF49A24)],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      title: LogoTapGate(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront, color: Colors.white, size: 30),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sapaan,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    (store != null && store.storeName.isNotEmpty)
                        ? store.storeName
                        : 'Warunge Mimi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: Colors.white,
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
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              buka ? '● BUKA' : '● TUTUP',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: bukaKoin,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$koin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref, int i) async {
    if (_lockedTabs.contains(i)) {
      final session = ref.read(sessionProvider).valueOrNull;
      if (session == null || session.isGuest) {
        await requireLogin(context, ref, () async {
          ref.read(customerTabProvider.notifier).state = i;
        });
        return;
      }
    }
    ref.read(customerTabProvider.notifier).state = i;
  }
}

class _GerbangTabTerkunci extends ConsumerStatefulWidget {
  const _GerbangTabTerkunci();

  @override
  ConsumerState<_GerbangTabTerkunci> createState() =>
      _GerbangTabTerkunciState();
}

class _GerbangTabTerkunciState extends ConsumerState<_GerbangTabTerkunci> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await requireLogin(context, ref, () async {});
      if (!mounted) return;
      final s = ref.read(sessionProvider).valueOrNull;
      if (s == null || s.isGuest) {
        ref.read(customerTabProvider.notifier).state = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
