import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/strings_id.dart';
import '../session.dart';
import 'rumpi_feed.dart';
import 'toko_chat_page.dart';

/// Mode Pelanggan > Tab Chat — 2 ruang: Rumpi (feed komunitas),
/// Toko (chat privat dengan Warunge Mimi).
/// Tab ini bergembok untuk tamu (diatur di CustomerShell).
class ChatTab extends ConsumerWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).valueOrNull;
    final uid = memberUid(session ?? const Session.guest());
    if (uid == null) {
      // Seharusnya tak terlihat (gembok di navbar), tapi aman bila terjadi.
      return const Center(child: Text(Strings.guestLockTitle));
    }
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppColors.card,
            child: const TabBar(
              labelColor: AppColors.orange,
              unselectedLabelColor: AppColors.muted,
              indicatorColor: AppColors.orange,
              tabs: [
                Tab(text: Strings.tabRumpi),
                Tab(text: Strings.tabToko),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                RumpiFeed(uid: uid, nama: displayName(session!)),
                TokoChatPage(uid: uid),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
