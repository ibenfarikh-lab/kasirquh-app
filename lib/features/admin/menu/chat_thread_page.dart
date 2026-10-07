import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/chat.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../l10n/strings_id.dart';
import '../../admin/admin_session.dart';

/// Mode Admin > Chat — isi percakapan satu thread + kirim pesan.
class ChatThreadPage extends ConsumerStatefulWidget {
  final ChatThread thread;
  const ChatThreadPage({super.key, required this.thread});

  @override
  ConsumerState<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends ConsumerState<ChatThreadPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Tandai thread sudah dibaca admin (abaikan bila offline).
    ref.read(adminRepositoryProvider).markThreadRead(widget.thread.id).catchError(
          (_) {},
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final adminId = ref.read(adminSessionProvider).valueOrNull?.user.uid;
    if (adminId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.butuhInternetAdmin)),
        );
      }
      return;
    }
    try {
      await ref.read(adminRepositoryProvider).sendMessage(
            threadId: widget.thread.id,
            customerId: widget.thread.customerId,
            text: text,
            adminId: adminId,
          );
      _controller.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.butuhInternetAdmin)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.thread.customerName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: ref.watch(adminRepositoryProvider).watchMessages(
                    widget.thread.id,
                  ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final msgs = snap.data ?? [];
                if (msgs.isEmpty) {
                  return Center(
                    child: Text(
                      'Belum ada pesan.',
                      style: TextStyle(color: context.teksRedup),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[msgs.length - 1 - i];
                    final mine = m.senderRole == 'admin';
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          // Aturan 3: bubble ≈ kartu = L2.
                          color: mine ? AppColors.orange : AppColors.panel,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          m.text,
                          style: TextStyle(
                            color: mine
                                ? AppColors.adminBg
                                : context.teksUtama,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: context.permukaanKartu, // Aturan 1&3: adaptif.
            padding: const EdgeInsets.all(12),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: Strings.ketikPesan,
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: AppColors.orange,
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
