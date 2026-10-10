import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/chat.dart';
import '../../../data/repositories/social_repository.dart';
import '../../../l10n/strings_id.dart';
import 'chat_widgets.dart';

/// Mode Pelanggan > Chat > Toko — percakapan dengan Warunge Mimi.
/// Thread dibuat admin saat menyetujui pendaftaran (1 thread per pelanggan).
class TokoChatPage extends ConsumerStatefulWidget {
  final String uid;

  /// true bila di dalam sheet modal ala PWA.
  final bool modeSheet;

  /// ScrollController dari DraggableScrollableSheet (opsional).
  final ScrollController? scrollController;

  const TokoChatPage({
    super.key,
    required this.uid,
    this.modeSheet = false,
    this.scrollController,
  });

  @override
  ConsumerState<TokoChatPage> createState() => _TokoChatPageState();
}

class _TokoChatPageState extends ConsumerState<TokoChatPage> {
  @override
  Widget build(BuildContext context) {
    final threadAsync = ref.watch(myTokoThreadProvider(widget.uid));
    return threadAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const EmptyState(
        icon: Icons.storefront_outlined,
        title: Strings.chatTokoKosong,
        hint: Strings.butuhInternetUmum,
      ),
      data: (thread) {
        if (thread == null) {
          // Thread dibuat admin saat persetujuan; belum ada = belum dibuat.
          return const EmptyState(
            icon: Icons.storefront_outlined,
            title: Strings.chatTokoKosong,
            hint: Strings.chatTokoKosongHint,
          );
        }
        // Tandai dibaca ditangani _IsiThread (initState + pesan baru),
        // bukan di build() — tulis Firestore di build() memicu loop.
        return _IsiThread(thread: thread, uid: widget.uid);
      },
    );
  }
}

class _IsiThread extends ConsumerStatefulWidget {
  final ChatThread thread;
  final String uid;
  const _IsiThread({required this.thread, required this.uid});

  @override
  ConsumerState<_IsiThread> createState() => _IsiThreadState();
}

class _IsiThreadState extends ConsumerState<_IsiThread> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Tandai dibaca sekali saat thread dibuka (di luar build agar tak loop).
    WidgetsBinding.instance.addPostFrameCallback((_) => _tandaiDibaca());
  }

  void _tandaiDibaca() {
    ref.read(socialRepositoryProvider).markTokoRead(widget.thread.id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    final teks = _controller.text.trim();
    if (teks.isEmpty) return;
    try {
      await ref.read(socialRepositoryProvider).sendTokoMessage(
            threadId: widget.thread.id,
            uid: widget.uid,
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
    final msgsAsync =
        ref.watch(tokoMessagesProvider(widget.thread.id));
    // Pesan baru masuk saat halaman terbuka → tandai dibaca.
    ref.listen(tokoMessagesProvider(widget.thread.id), (prev, next) {
      final sblm = prev?.valueOrNull?.length ?? 0;
      final skrg = next.valueOrNull?.length ?? 0;
      if (skrg > sblm) _tandaiDibaca();
    });
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.orange.withValues(alpha: 0.12),
          child: const Row(
            children: [
              Icon(Icons.storefront,
                  size: 18, color: AppColors.orange),
              SizedBox(width: 8),
              Text(
                Strings.tokoChatJudul,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Expanded(
          child: msgsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
                child: Text(Strings.butuhInternetUmum,
                    style: TextStyle(color: context.teksRedup))),
            data: (msgs) {
              if (msgs.isEmpty) {
                return Center(
                  child: Text(
                    Strings.chatTokoMulai,
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
                  final milikSaya = m.senderId == widget.uid;
                  return ChatBubble(
                    message: m,
                    milikSaya: milikSaya,
                    namaPengirim: milikSaya
                        ? null
                        : Strings.appName,
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
