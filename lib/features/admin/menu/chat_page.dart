import 'package:flutter/material.dart';
import '../admin_nav.dart';
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

class _ThreadList extends ConsumerStatefulWidget {
  const _ThreadList();

  @override
  ConsumerState<_ThreadList> createState() => _ThreadListState();
}

class _ThreadListState extends ConsumerState<_ThreadList> {
  String _query = '';
  bool _hanyaBelumDibaca = false;

  @override
  Widget build(BuildContext context) {
    final threads = ref.watch(chatThreadsProvider);
    final pinned =
        ref.watch(storeInfoProvider).valueOrNull?.pinnedChatIds ??
            const <String>[];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Cari nama pelanggan…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Semua'),
                selected: !_hanyaBelumDibaca,
                onSelected: (_) => setState(() => _hanyaBelumDibaca = false),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Belum dibaca'),
                selected: _hanyaBelumDibaca,
                onSelected: (_) => setState(() => _hanyaBelumDibaca = true),
              ),
            ],
          ),
        ),
        Expanded(
          child: threads.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                Strings.butuhInternetAdmin,
                style: TextStyle(color: context.teksRedup),
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
              var tampil = list.where((t) {
                if (_hanyaBelumDibaca && t.unreadAdmin <= 0) return false;
                if (_query.isNotEmpty &&
                    !t.customerName.toLowerCase().contains(_query)) {
                  return false;
                }
                return true;
              }).toList();
              tampil.sort((a, b) {
                final ia = pinned.indexOf(a.id);
                final ib = pinned.indexOf(b.id);
                if (ia >= 0 && ib >= 0) return ia.compareTo(ib);
                if (ia >= 0) return -1;
                if (ib >= 0) return 1;
                return 0;
              });
              if (tampil.isEmpty) {
                return const EmptyState(
                  icon: Icons.search_off,
                  title: 'Tidak ada hasil',
                  hint: 'Coba kata kunci atau filter lain.',
                );
              }
              return ListView.separated(
                itemCount: tampil.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: AppColors.adminLine,
                ),
                itemBuilder: (context, i) {
                  final t = tampil[i];
                  return _ThreadTile(
                    thread: t,
                    terpin: pinned.contains(t.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ThreadTile extends ConsumerWidget {
  final ChatThread thread;
  final bool terpin;
  const _ThreadTile({required this.thread, required this.terpin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.teksUtama,
                fontWeight: hasUnread ? FontWeight.w800 : FontWeight.bold,
              ),
            ),
          ),
          if (terpin)
            const Icon(Icons.push_pin,
                size: 15, color: AppColors.orange),
        ],
      ),
      subtitle: Text(
        thread.lastMessage ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: context.teksRedup),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              terpin ? Icons.push_pin : Icons.push_pin_outlined,
              size: 20,
            ),
            color: terpin ? AppColors.orange : context.teksRedup,
            tooltip: terpin ? 'Lepas pin' : 'Pin percakapan',
            onPressed: () async {
              try {
                await ref
                    .read(adminRepositoryProvider)
                    .togglePinChat(thread.id);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(Strings.butuhInternetAdmin)),
                  );
                }
              }
            },
          ),
          if (hasUnread)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            ),
        ],
      ),
      onTap: () {
        openAdminPage(context, ChatThreadPage(thread: thread));
      },
    );
  }
}
