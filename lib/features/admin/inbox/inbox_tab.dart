import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../l10n/strings_id.dart';
import '../menu/chat_page.dart';
import '../menu/chat_thread_page.dart';
import '../menu/customers_page.dart';
import '../menu/online_orders_page.dart';
import '../menu/products_page.dart';

/// Tab Inbox: pusat notifikasi + shortcut.
/// Tiap item bisa di-tap → deep link ke layar terkait.
class InboxTab extends ConsumerWidget {
  const InboxTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvals =
        ref.watch(pendingApprovalsProvider).valueOrNull ?? const [];
    final orders = ref.watch(adminOrdersProvider).valueOrNull ?? const [];
    final waiting =
        orders.where((o) => o.status == OrderStatus.menunggu).toList();
    final threads = ref.watch(chatThreadsProvider).valueOrNull ?? const [];
    final unread = threads.where((t) => t.unreadAdmin > 0).toList();
    final low = ref.watch(lowStockProductsProvider);
    final titipan = (ref.watch(titipRequestsProvider).valueOrNull ??
            const [])
        .where((t) => t.status == 'baru')
        .toList();

    final empty = approvals.isEmpty &&
        waiting.isEmpty &&
        unread.isEmpty &&
        low.isEmpty &&
        titipan.isEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          Strings.tabInbox,
          style: TextStyle(
            color: AppColors.warmText,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (empty)
          const EmptyState(
            icon: Icons.inbox_outlined,
            title: Strings.inboxKosong,
            hint: Strings.inboxKosongHint,
          )
        else ...[
          if (approvals.isNotEmpty)
            _Section(
              icon: Icons.person_add_outlined,
              title:
                  '${Strings.persetujuanPendaftar} (${approvals.length})',
              onMore: approvals.length > 3
                  ? () => _open(context, const CustomersPage())
                  : null,
              children: approvals
                  .take(3)
                  .map((c) => _ApprovalTile(customer: c))
                  .toList(),
            ),
          if (waiting.isNotEmpty)
            _Section(
              icon: Icons.shopping_bag_outlined,
              title: '${Strings.pesananBaru} (${waiting.length})',
              onMore: waiting.length > 3
                  ? () => _open(context, const OnlineOrdersPage())
                  : null,
              children: waiting
                  .take(3)
                  .map((o) => _OrderTile(order: o))
                  .toList(),
            ),
          if (unread.isNotEmpty)
            _Section(
              icon: Icons.chat_bubble_outline,
              title: '${Strings.chatBelumDibaca} (${unread.length})',
              onMore: unread.length > 3
                  ? () => _open(context, const ChatPage())
                  : null,
              children: unread
                  .take(3)
                  .map((t) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.customerName,
                            style: const TextStyle(
                                color: AppColors.warmText,
                                fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          t.lastMessage ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.warmMuted),
                        ),
                        trailing: _CountBadge(count: t.unreadAdmin),
                        onTap: () => _open(
                            context, ChatThreadPage(thread: t)),
                      ))
                  .toList(),
            ),
          if (low.isNotEmpty)
            _Section(
              icon: Icons.inventory_2_outlined,
              title: '${Strings.stokMenipisJudul} (${low.length})',
              onMore: low.length > 3
                  ? () => _open(context, const ProductsPage())
                  : null,
              children: low
                  .take(3)
                  .map((p) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(p.name,
                            style: const TextStyle(
                                color: AppColors.warmText,
                                fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          'Stok ${formatStok(p.stock)} · ${formatRp(p.price)}',
                          style: const TextStyle(
                              color: AppColors.warmMuted),
                        ),
                        trailing: _CountBadge(count: p.stock.round()),
                        onTap: () =>
                            _open(context, const ProductsPage()),
                      ))
                  .toList(),
            ),
          if (titipan.isNotEmpty)
            _Section(
              icon: Icons.shopping_bag_outlined,
              title: '${Strings.titipan} (${titipan.length})',
              children: titipan
                  .take(5)
                  .map((t) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                            Icons.shopping_bag_outlined,
                            color: AppColors.orange),
                        title: Text(t.item,
                            style: const TextStyle(
                                color: AppColors.warmText,
                                fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          '${t.customerName} · ${t.method}'
                          '${t.note.isEmpty ? '' : ' · ${t.note}'}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.warmMuted),
                        ),
                      ))
                  .toList(),
            ),
        ],
      ],
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => page));
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onMore;
  final List<Widget> children;

  const _Section({
    required this.icon,
    required this.title,
    this.onMore,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.warmText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (onMore != null)
                  TextButton(
                    onPressed: onMore,
                    child: const Text(Strings.lihatSemua),
                  ),
              ],
            ),
            const Divider(color: AppColors.adminLine),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ApprovalTile extends ConsumerWidget {
  final Customer customer;

  const _ApprovalTile({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      // Deep link: tap tile → Data Pelanggan (kelola persetujuan di sana).
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CustomersPage()),
      ),
      title: Text(customer.name,
          style: const TextStyle(
              color: AppColors.warmText, fontWeight: FontWeight.w700)),
      subtitle: Text(customer.email,
          style: const TextStyle(color: AppColors.warmMuted)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _decide(ref, context, true),
            icon: const Icon(Icons.check_circle, color: AppColors.ok),
            tooltip: Strings.setujui,
          ),
          IconButton(
            onPressed: () => _decide(ref, context, false),
            icon: const Icon(Icons.cancel, color: AppColors.danger),
            tooltip: Strings.tolak,
          ),
        ],
      ),
    );
  }

  Future<void> _decide(
      WidgetRef ref, BuildContext context, bool approved) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .setApproval(customer.uid, approved);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(approved
                  ? Strings.pendaftarDisetujui
                  : Strings.pendaftarDitolak)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.butuhInternetAdmin)),
        );
      }
    }
  }
}

class _OrderTile extends StatelessWidget {
  final Order order;

  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(order.customerName,
          style: const TextStyle(
              color: AppColors.warmText, fontWeight: FontWeight.w700)),
      subtitle: Text(
        '${order.items.fold(0, (s, e) => s + e.qty)} barang · ${formatRp(order.total)}',
        style: const TextStyle(color: AppColors.warmMuted),
      ),
      trailing: const Icon(Icons.chevron_right,
          color: AppColors.warmMuted),
      // Deep link: buka Kasir Online.
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OnlineOrdersPage())),
    );
  }
}
