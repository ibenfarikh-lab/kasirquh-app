import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/rumpi.dart';
import '../../../data/repositories/social_repository.dart';
import '../../../l10n/strings_id.dart';
import 'compose_post_sheet.dart';

/// Feed kabar Rumpi + tombol tulis. Dipakai Mode Pelanggan dan
/// (modeAdmin) Tab Rumpi admin — admin bisa posting sebagai admin dan
/// menghapus postingan (moderasi).
/// [modeSheet]: true bila di dalam sheet modal ala PWA (composer inline,
/// tanpa FAB); false = tampilan tab biasa dengan FAB.
class RumpiFeed extends ConsumerStatefulWidget {
  final String uid;
  final String nama;

  /// true bila dipakai admin: tulis sebagai admin + tombol hapus tiap post.
  final bool modeAdmin;

  /// true bila di dalam sheet modal (ala PWA).
  final bool modeSheet;

  /// ScrollController dari DraggableScrollableSheet (opsional).
  final ScrollController? scrollController;

  const RumpiFeed({
    super.key,
    required this.uid,
    required this.nama,
    this.modeAdmin = false,
    this.modeSheet = false,
    this.scrollController,
  });

  @override
  ConsumerState<RumpiFeed> createState() => _RumpiFeedState();
}

class _RumpiFeedState extends ConsumerState<RumpiFeed> {
  final _composer = TextEditingController();

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
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(rumpiPostsProvider),
          child: ListView.builder(
            controller: widget.scrollController,
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, widget.modeSheet ? 12 : 90),
            itemCount: posts.length,
            itemBuilder: (context, i) {
              final p = posts[i];
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

    if (!widget.modeSheet) {
      return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _tulis(context, ref),
          backgroundColor: AppColors.orange,
          icon: const Icon(Icons.edit, color: Colors.white),
          label: const Text(
            Strings.tulisKabar,
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        body: feed,
      );
    }

    // Mode sheet ala PWA: feed + composer inline di bawah.
    return Column(
      children: [
        Expanded(child: feed),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
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

  /// Kirim postingan langsung (composer inline ala PWA).
  Future<void> _kirim(BuildContext context, WidgetRef ref) async {
    final teks = _composer.text.trim();
    if (teks.isEmpty) {
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
            authorRole: widget.modeAdmin ? 'admin' : 'customer',
          );
      _composer.clear();
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

  Future<void> _tulis(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ComposePostSheet(
        uid: widget.uid,
        nama: widget.nama,
        authorRole: widget.modeAdmin ? 'admin' : 'customer',
      ),
    );
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
                  child: Text(
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
