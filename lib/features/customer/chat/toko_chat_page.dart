import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/product_photo.dart';
import '../../../data/models/chat.dart';
import '../../../data/repositories/social_repository.dart';
import '../../../l10n/strings_id.dart';
import 'chat_widgets.dart';

class TokoChatPage extends ConsumerStatefulWidget {
  final String uid;

  final bool modeSheet;

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
          return const EmptyState(
            icon: Icons.storefront_outlined,
            title: Strings.chatTokoKosong,
            hint: Strings.chatTokoKosongHint,
          );
        }
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
  String _fotoUrl = '';

  @override
  void initState() {
    super.initState();
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

  Future<void> _pilihFoto() async {
    final url = await pickProductPhoto();
    if (url != null && mounted) setState(() => _fotoUrl = url);
  }

  Future<void> _kirim() async {
    final teks = _controller.text.trim();
    if (teks.isEmpty && _fotoUrl.isEmpty) return;
    try {
      await ref.read(socialRepositoryProvider).sendTokoMessage(
            threadId: widget.thread.id,
            uid: widget.uid,
            text: teks,
            imageUrl: _fotoUrl,
          );
      _controller.clear();
      if (mounted) setState(() => _fotoUrl = '');
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
        if (_fotoUrl.isNotEmpty)
          Container(
            color: context.permukaanKartu,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(
                    image: photoImageProvider(_fotoUrl)!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Foto siap dikirim'),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _fotoUrl = ''),
                  icon: const Icon(Icons.close),
                  tooltip: 'Batalkan foto',
                ),
              ],
            ),
          ),
        ChatInputBar(
          controller: _controller,
          onSend: _kirim,
          hint: Strings.ketikPesan,
          onPickPhoto: _pilihFoto,
        ),
      ],
    );
  }
}
