import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/chat.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../l10n/strings_id.dart';
import '../../customer/chat/rumpi_feed.dart';
import '../admin_session.dart';
import 'chat_thread_page.dart';

/// Mode Admin > Chat — 2 tab: Rumpi (feed + posting + moderasi)
/// dan Chat Toko (daftar thread pelanggan).
class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(adminSessionProvider).valueOrNull;
    final namaToko =
        ref.watch(storeInfoProvider).valueOrNull?.storeName ?? 'Warunge Mimi';
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(Strings.modulChat),
          bottom: const TabBar(
            tabs: [
              Tab(text: Strings.tabRumpi),
              Tab(text: Strings.tabAdminChatToko),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            if (admin == null)
              const Center(child: CircularProgressIndicator())
            else
              RumpiFeed(
                uid: admin.user.uid,
                nama: namaToko,
                modeAdmin: true,
              ),
            const _ThreadList(),
          ],
        ),
      ),
    );
  }
}

/// Tab Chat Toko: daftar percakapan (thread) dengan pelanggan.
class _ThreadList extends ConsumerWidget {
  const _ThreadList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(chatThreadsProvider);
    return threads.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            Strings.butuhInternetAdmin,
            style: const TextStyle(color: AppColors.warmMuted),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: Strings.belumAdaPercakapan,
              hint: Strings.chatKosongHint,
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: AppColors.adminLine,
            ),
            itemBuilder: (context, i) {
              final t = list[i];
              return _ThreadTile(thread: t);
            },
          );
        },
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final ChatThread thread;
  const _ThreadTile({required this.thread});

  @override
  Widget build(BuildContext context) {
    final name = thread.customerName.isEmpty ? '?' : thread.customerName;
    final hasUnread = thread.unreadAdmin > 0;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.orange,
        child: Text(
          name[0].toUpperCase(),
          style: const TextStyle(
            color: AppColors.adminBg,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(
          color: context.teksUtama,
          fontWeight: hasUnread ? FontWeight.w800 : FontWeight.bold,
        ),
      ),
      subtitle: Text(
        thread.lastMessage ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: context.teksRedup),
      ),
      trailing: hasUnread
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${thread.unreadAdmin}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatThreadPage(thread: thread),
          ),
        );
      },
    );
  }
}
