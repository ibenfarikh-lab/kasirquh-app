import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/product_photo.dart';
import '../../../data/models/rumpi.dart';
import '../../../data/repositories/social_repository.dart';
import '../../../l10n/strings_id.dart';
import '../session.dart';

/// Feed kabar Rumpi + composer inline gaya chat. Dipakai Mode
/// Pelanggan dan (modeAdmin) Tab Rumpi admin — admin bisa posting
/// sebagai admin dan menghapus postingan (moderasi).
/// Composer-nya sama seperti chat lain (perintah user 2026-10-21):
/// kolom input + tombol kirim + tombol foto dengan pratinjau —
/// BUKAN lagi tombol "Tulis Kabar" / halaman form terpisah.
class RumpiFeed extends ConsumerStatefulWidget {
  final String uid;
  final String nama;

  /// true bila dipakai admin: tulis sebagai admin + tombol hapus tiap post.
  final bool modeAdmin;

  /// ScrollController dari DraggableScrollableSheet (opsional).
  final ScrollController? scrollController;

  const RumpiFeed({
    super.key,
    required this.uid,
    required this.nama,
    this.modeAdmin = false,
    this.scrollController,
  });

  @override
  ConsumerState<RumpiFeed> createState() => _RumpiFeedState();
}

class _RumpiFeedState extends ConsumerState<RumpiFeed> {
  final _composer = TextEditingController();

  /// Foto terlampir di composer (data URI 300px PNG, pola Chat Toko).
  String? _fotoUrl;

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(rumpiPostsProvider);
    final likesAsync = ref.watch(myLikesProvider(widget.uid));

    final feed = postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const EmptyState(
        icon: Icons.forum_outlined,
        title: Strings.rumpiKosong,
        hint: Strings.butuhInternetUmum,
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return const EmptyState(
            icon: Icons.forum_outlined,
            // Teks PWA persis.
            title: 'Belum ada obrolan di Rumpi Warga.',
            hint: Strings.rumpiKosongHint,
          );
        }
        final disukai = likesAsync.valueOrNull ?? const <String>{};
        // Terbaru di bawah ala chat (perintah user 2026-10-18:
        // "Samakan saja, bawah semuanya") — selaras Chat Toko.
        final urut = [...posts]
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(rumpiPostsProvider),
          child: ListView.builder(
            reverse: true,
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: urut.length,
            itemBuilder: (context, i) {
              final p = urut[urut.length - 1 - i];
              return _PostCard(
                post: p,
                disukai: disukai.contains(p.id),
                onLike: () => _like(context, ref, p.id),
                tampilkanHapus: widget.modeAdmin,
                onHapus: () => _hapus(context, ref, p.id),
              );
            },
          ),
        );
      },
    );

    // Composer inline gaya chat (pelanggan & admin sama): feed +
    // bar input di bawah dengan tombol foto & kirim.
    return Column(
      children: [
        Expanded(child: feed),
        const Divider(height: 1),
        // Pratinjau foto terlampir (pola Chat Toko P1-2).
        if (_fotoUrl != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(
                    image: photoImageProvider(_fotoUrl!)!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Foto terlampir'),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _fotoUrl = null),
                  icon: const Icon(Icons.close),
                  tooltip: 'Batal foto',
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 12, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: _pilihFoto,
                icon: const Icon(Icons.image_outlined),
                color: AppColors.orange,
                tooltip: 'Tambah foto',
              ),
              Expanded(
                child: TextField(
                  controller: _composer,
                  maxLength: 180,
                  decoration: const InputDecoration(
                    hintText: 'Tulis kabar untuk warga…',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(20)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => _kirim(context, ref),
                icon: const Icon(Icons.send),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Pilih foto untuk postingan (galeri → 300px PNG data URI —
  /// helper yang sama dengan Chat Toko & foto produk).
  Future<void> _pilihFoto() async {
    final uri = await pickProductPhoto();
    if (uri != null && mounted) {
      setState(() => _fotoUrl = uri);
    }
  }

  /// Kirim postingan dari composer inline — teks dan/atau foto
  /// (foto saja boleh, persis Web).
  Future<void> _kirim(BuildContext context, WidgetRef ref) async {
    final teks = _composer.text.trim();
    if (teks.isEmpty && _fotoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tulis kabar atau tambah foto dulu')),
      );
      return;
    }
    try {
      await ref.read(socialRepositoryProvider).createPost(
            uid: widget.uid,
            authorName: widget.nama,
            text: teks,
            imageUrl: _fotoUrl,
            authorRole: widget.modeAdmin ? 'admin' : 'customer',
            authorPhoto: widget.modeAdmin
                ? ''
                : (ref.read(sessionProvider).valueOrNull?.photoURL ?? ''),
          );
      _composer.clear();
      setState(() => _fotoUrl = null);
      ref.invalidate(rumpiPostsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Postingan tampil di Rumpi Warga')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.butuhInternetUmum)),
        );
      }
    }
  }

  Future<void> _hapus(
      BuildContext context, WidgetRef ref, String postId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(Strings.hapusPostinganTanya),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Strings.batal),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              Strings.hapus,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(socialRepositoryProvider).deletePost(postId);
      ref.invalidate(rumpiPostsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.berhasilDihapus)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.hapusPostinganGagal)),
        );
      }
    }
  }

  Future<void> _like(
      BuildContext context, WidgetRef ref, String postId) async {
    try {
      await ref
          .read(socialRepositoryProvider)
          .toggleLike(postId: postId, uid: widget.uid);
    } catch (_) {
      // Gagal (mis. rules belum dipublish / offline) → beri tahu user,
      // jangan diam-diam: like tidak tercatat.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.sukaGagal)),
        );
      }
    }
  }
}

class _PostCard extends StatelessWidget {
  final RumpiPost post;
  final bool disukai;
  final VoidCallback onLike;

  /// Moderasi admin: tampilkan tombol hapus + aksi hapus.
  final bool tampilkanHapus;
  final VoidCallback? onHapus;
  const _PostCard({
    required this.post,
    required this.disukai,
    required this.onLike,
    this.tampilkanHapus = false,
    this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      AppColors.orange.withValues(alpha: 0.15),
                  // Foto profil penulis (P2-9): ditampilkan bila ada;
                  // tanpa foto → huruf inisial seperti sebelumnya.
                  backgroundImage: post.authorPhoto.isNotEmpty
                      ? photoImageProvider(post.authorPhoto)
                      : null,
                  child: post.authorPhoto.isNotEmpty
                      ? null
                      : Text(
                          post.authorName.isEmpty
                              ? '?'
                              : post.authorName[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.authorName.isEmpty
                                  ? 'Warga'
                                  : post.authorName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (post.isSeed) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.teksRedup
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'CONTOH',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: context.teksRedup,
                                ),
                              ),
                            ),
                          ],
                          if (post.isAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.orange
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                Strings.lencanaAdmin,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.orange,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        waktuRelatif(post.createdAt),
                        style: TextStyle(
                          color: context.teksRedup,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (tampilkanHapus)
                  IconButton(
                    onPressed: onHapus,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: AppColors.danger,
                    tooltip: Strings.hapus,
                  ),
              ],
            ),
            if (post.text.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(post.text, style: const TextStyle(fontSize: 15)),
            ],
            if (post.punyaFoto) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _PostImage(dataUri: post.imageUrl!),
              ),
            ],
            const SizedBox(height: 8),
            InkWell(
              onTap: onLike,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      disukai ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: disukai
                          ? AppColors.danger
                          : context.teksRedup,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.likeCount}',
                      style: TextStyle(
                        color: disukai
                            ? AppColors.danger
                            : context.teksRedup,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gambar postingan dari data URI base64 (tanpa Storage).
class _PostImage extends StatelessWidget {
  final String dataUri;
  const _PostImage({required this.dataUri});

  @override
  Widget build(BuildContext context) {
    try {
      final base64Part = dataUri.contains(',')
          ? dataUri.split(',').last
          : dataUri;
      final bytes = base64Decode(base64Part);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
