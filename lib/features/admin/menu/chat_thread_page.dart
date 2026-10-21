import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/product_photo.dart';
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
  String _fotoUrl = '';

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

  /// Pilih foto (kompres 300px PNG data URI — pola Web, P1-2).
  Future<void> _pilihFoto() async {
    final url = await pickProductPhoto();
    if (url != null && mounted) setState(() => _fotoUrl = url);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _fotoUrl.isEmpty) return;
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
            imageUrl: _fotoUrl,
          );
      _controller.clear();
      if (mounted) setState(() => _fotoUrl = '');
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
                          // Aturan 3: bubble ≈ kartu = L2. Ikut tema
                          // (fix 2026-10-17: sebelumnya AppColors.panel
                          // hardcoded gelap → melanggar aturan di theme light).
                          color: mine
                              ? AppColors.orange
                              : (context.temaGelap
                                  ? AppColors.panel
                                  : AppColors.card),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Foto terlampir (skema Web imageUrl, P1-2).
                            if (m.punyaFoto) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _fotoAdmin(m.imageUrl),
                              ),
                              if (m.text.isNotEmpty)
                                const SizedBox(height: 6),
                            ],
                            if (m.text.isNotEmpty)
                              Text(
                                m.text,
                                style: TextStyle(
                                  color: mine
                                      ? AppColors.adminBg
                                      : context.teksUtama,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Pratinjau foto yang akan dikirim (P1-2).
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
          Container(
            color: context.permukaanKartu, // Aturan 1&3: adaptif.
            padding: const EdgeInsets.all(12),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    color: AppColors.orange,
                    onPressed: _pilihFoto,
                    tooltip: 'Tambah foto',
                  ),
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

  /// Gambar pesan dari data URI/URL — kosong rapi bila gagal muat.
  Widget _fotoAdmin(String url) {
    final provider = photoImageProvider(url);
    if (provider == null) return const SizedBox.shrink();
    return Image(
      image: provider,
      width: 180,
      height: 180,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}
