import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/admin_repository.dart';
import '../../l10n/strings_id.dart';
import 'admin_push_bootstrap.dart';
import 'dashboard/dashboard_tab.dart';
import 'inbox/inbox_tab.dart';
import 'menu/menu_tab.dart';
import 'notes/notes_tab.dart';
import 'pos/pos_tab.dart';

final adminTabProvider = StateProvider<int>((ref) => 0);

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(adminTabProvider);
    final inboxBadge = ref.watch(inboxBadgeProvider);

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF9B3E), Color(0xFFF49A24)],
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(22)),
          ),
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront, color: Colors.white),
              SizedBox(width: 8),
              Text(
                Strings.appName,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Colors.white),
              ),
            ],
          ),
          centerTitle: false,
          automaticallyImplyLeading: false,
        ),
        body: Stack(
          children: [
            IndexedStack(
              index: index,
              children: const [
                DashboardTab(),
                PosTab(),
                InboxTab(),
                NotesTab(),
                MenuTab(),
              ],
            ),
            const AdminPushBootstrap(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: index,
          type: BottomNavigationBarType.fixed,
          onTap: (i) =>
              ref.read(adminTabProvider.notifier).state = i,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: Strings.tabBeranda,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale_outlined),
              activeIcon: Icon(Icons.point_of_sale),
              label: Strings.tabKasir,
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: inboxBadge > 0,
                label: Text('$inboxBadge'),
                backgroundColor: AppColors.danger,
                child: const Icon(Icons.inbox_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: inboxBadge > 0,
                label: Text('$inboxBadge'),
                backgroundColor: AppColors.danger,
                child: const Icon(Icons.inbox),
              ),
              label: Strings.tabInbox,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.note_alt_outlined),
              activeIcon: Icon(Icons.note_alt),
              label: Strings.tabCatatan,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: Strings.tabMenu,
            ),
          ],
        ),
    );
  }
}
