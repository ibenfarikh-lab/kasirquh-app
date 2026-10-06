import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/repositories/social_repository.dart';
import '../../../l10n/strings_id.dart';
import 'chat_widgets.dart';

/// Mode Pelanggan > Chat > Komunitas — grup chat warga satu warung.
/// Memakai thread grup tunggal `rumpi` (butuh rules tambahan, lihat laporan).
class GroupChatPage extends ConsumerStatefulWidget {
  final String uid;
  final String nama;
  const GroupChatPage({super.key, required this.uid, required this.nama});

  @override
  ConsumerState<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends ConsumerState<GroupChatPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    final teks = _controller.text.trim();
    if (teks.isEmpty) return;
    try {
      await ref.read(socialRepositoryProvider).sendGroupMessage(
            uid: widget.uid,
            senderName: widget.nama,
            text: teks,
          );
      _controller.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.butuhInternetUmum)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final msgsAsync = ref.watch(groupMessagesProvider);
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.orange.withValues(alpha: 0.12),
          child: const Row(
            children: [
              Icon(Icons.groups_outlined,
                  size: 18, color: AppColors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  Strings.grupJudul,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: msgsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) => const EmptyState(
              icon: Icons.groups_outlined,
              title: Strings.grupKosong,
              hint: Strings.butuhInternetUmum,
            ),
            data: (msgs) {
              if (msgs.isEmpty) {
                return const EmptyState(
                  icon: Icons.groups_outlined,
                  title: Strings.grupKosong,
                  hint: Strings.grupKosongHint,
                );
              }
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: msgs.length,
                itemBuilder: (context, i) {
                  final m = msgs[msgs.length - 1 - i];
                  final milikSaya = m.senderId == widget.uid;
                  return ChatBubble(
                    message: m,
                    milikSaya: milikSaya,
                    // Nama pengirim grup tidak disimpan di pesan;
                    // tampilkan peran saja agar tidak mengarang nama.
                    namaPengirim: milikSaya
                        ? null
                        : (m.senderRole == 'admin'
                            ? Strings.appName
                            : Strings.warga),
                  );
                },
              );
            },
          ),
        ),
        ChatInputBar(
          controller: _controller,
          onSend: _kirim,
          hint: Strings.ketikPesan,
        ),
      ],
    );
  }
}
