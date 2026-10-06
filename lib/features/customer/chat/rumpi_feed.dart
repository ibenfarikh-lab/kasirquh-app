import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/rumpi.dart';
import '../../../data/repositories/social_repository.dart';
import '../../../l10n/strings_id.dart';
import 'compose_post_sheet.dart';

/// Mode Pelanggan > Chat > Rumpi — feed kabar warga + tombol tulis.
class RumpiFeed extends ConsumerWidget {
  final String uid;
  final String nama;
  const RumpiFeed({super.key, required this.uid, required this.nama});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(rumpiPostsProvider);
    final likesAsync = ref.watch(myLikesProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.paper,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tulis(context, ref),
        backgroundColor: AppColors.orange,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text(
          Strings.tulisKabar,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: postsAsync.when(
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
              title: Strings.rumpiKosong,
              hint: Strings.rumpiKosongHint,
            );
          }
          final disukai = likesAsync.valueOrNull ?? const <String>{};
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(rumpiPostsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: posts.length,
              itemBuilder: (context, i) {
                final p = posts[i];
                return _PostCard(
                  post: p,
                  disukai: disukai.contains(p.id),
                  onLike: () => _like(context, ref, p.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _tulis(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ComposePostSheet(uid: uid, nama: nama),
    );
  }

  Future<void> _like(
      BuildContext context, WidgetRef ref, String postId) async {
    try {
      await ref
          .read(socialRepositoryProvider)
          .toggleLike(postId: postId, uid: uid);
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
  const _PostCard({
    required this.post,
    required this.disukai,
    required this.onLike,
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
                                color: AppColors.muted
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'CONTOH',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        waktuRelatif(post.createdAt),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
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
                          : AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.likeCount}',
                      style: TextStyle(
                        color: disukai
                            ? AppColors.danger
                            : AppColors.muted,
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
