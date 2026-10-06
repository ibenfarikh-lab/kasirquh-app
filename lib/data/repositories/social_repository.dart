import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/chat.dart';
import '../../data/models/rumpi.dart';
import '../../data/remote/firestore_service.dart';

/// Repository sosial (Mode Pelanggan): Rumpi, Chat Toko, Chat Komunitas,
/// riwayat koin. Baca realtime via snapshot Firestore; tulis butuh online
/// (jujur: tanpa antrean siluman — chat/posting butuh server).
class SocialRepository {
  final FirebaseFirestore? _db;

  SocialRepository(this._db);

  bool get online => _db != null;

  // ============ RUMPI ============

  /// Feed Rumpi terbaru dulu. Seed contoh (isSeed) disaring di UI berlabel —
  /// aplikasi tidak pernah membuatnya (toFirestore selalu isSeed=false).
  Stream<List<RumpiPost>> watchRumpiPosts({int limit = 50}) async* {
    final db = _db;
    if (db == null) {
      yield const [];
      return;
    }
    try {
      yield* db
          .collection('rumpi_posts')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => RumpiPost.fromDoc(d.id, d.data()))
              .toList());
    } catch (_) {
      yield const [];
    }
  }

  /// Set id postingan yang disukai uid (untuk status tombol like).
  Stream<Set<String>> watchMyLikes(String uid) async* {
    final db = _db;
    if (db == null) {
      yield const {};
      return;
    }
    try {
      // Catatan: documentId di collectionGroup = path penuh, jadi filter
      // memakai field 'uid' yang ditulis saat toggleLike.
      yield* db
          .collectionGroup('likes')
          .where('uid', isEqualTo: uid)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => d.reference.parent.parent?.id ?? '')
              .where((id) => id.isNotEmpty)
              .toSet());
    } catch (_) {
      yield const {};
    }
  }

  Future<void> createPost({
    required String uid,
    required String authorName,
    required String text,
    String? imageUrl,
  }) async {
    final db = _db;
    if (db == null) throw StateError('Butuh internet untuk posting.');
    final bersih = text.trim();
    if (bersih.isEmpty) throw StateError('Tulis kabar dulu ya.');
    await db.collection('rumpi_posts').add(RumpiPost(
          id: '',
          authorId: uid,
          authorName: authorName,
          text: bersih,
          imageUrl: imageUrl,
          createdAt: DateTime.now(),
        ).toFirestore());
  }

  /// Suka / batal suka. Transaksi: doc likes/{uid} + likeCount.
  /// BUTUH rules tambahan (lihat laporan): update likeCount oleh member
  /// dan baca/tulis subkoleksi likes.
  Future<void> toggleLike({
    required String postId,
    required String uid,
  }) async {
    final db = _db;
    if (db == null) throw StateError('Butuh internet.');
    final postRef = db.collection('rumpi_posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(uid);
    await db.runTransaction((tx) async {
      final likeDoc = await tx.get(likeRef);
      if (likeDoc.exists) {
        tx.delete(likeRef);
        tx.update(postRef, {
          'likeCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.set(likeRef, {
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(postRef, {
          'likeCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // ============ CHAT TOKO (pelanggan) ============

  /// Thread toko milik pelanggan (id doc = uid; dibuat admin saat menyetujui).
  Stream<ChatThread?> watchMyThread(String uid) async* {
    final db = _db;
    if (db == null) {
      yield null;
      return;
    }
    try {
      yield* db.collection('chat_threads').doc(uid).snapshots().map((doc) {
        final data = doc.data();
        if (data == null) return null;
        return ChatThread.fromDoc(doc.id, data);
      });
    } catch (_) {
      yield null;
    }
  }

  Stream<List<ChatMessage>> watchThreadMessages(String threadId) async* {
    final db = _db;
    if (db == null) {
      yield const [];
      return;
    }
    try {
      yield* db
          .collection('chat_threads')
          .doc(threadId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => ChatMessage.fromDoc(d.id, d.data()))
              .toList());
    } catch (_) {
      yield const [];
    }
  }

  Future<void> sendTokoMessage({
    required String threadId,
    required String uid,
    required String text,
  }) async {
    final db = _db;
    if (db == null) throw StateError('Butuh internet untuk chat.');
    final bersih = text.trim();
    if (bersih.isEmpty) return;
    final msgRef = db
        .collection('chat_threads')
        .doc(threadId)
        .collection('messages')
        .doc();
    final batch = db.batch();
    batch.set(
        msgRef,
        ChatMessage(
          id: msgRef.id,
          senderId: uid,
          senderRole: 'customer',
          text: bersih,
          createdAt: DateTime.now(),
        ).toFirestore());
    batch.update(db.collection('chat_threads').doc(threadId), {
      'lastMessage': bersih,
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadAdmin': FieldValue.increment(1),
      'unreadCustomer': 0,
    });
    await batch.commit();
  }

  Future<void> markTokoRead(String threadId) async {
    final db = _db;
    if (db == null) return;
    try {
      await db
          .collection('chat_threads')
          .doc(threadId)
          .update({'unreadCustomer': 0});
    } catch (_) {}
  }

  // ============ CHAT KOMUNITAS (grup tunggal 'rumpi') ============
  // BUTUH rules tambahan (lihat laporan): baca thread + tulis pesan grup.

  static const groupThreadId = 'rumpi';

  Stream<List<ChatMessage>> watchGroupMessages({int limit = 100}) async* {
    final db = _db;
    if (db == null) {
      yield const [];
      return;
    }
    try {
      yield* db
          .collection('chat_threads')
          .doc(groupThreadId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => ChatMessage.fromDoc(d.id, d.data()))
              .toList()
              .reversed
              .toList());
    } catch (_) {
      yield const [];
    }
  }

  Future<void> sendGroupMessage({
    required String uid,
    required String senderName,
    required String text,
  }) async {
    final db = _db;
    if (db == null) throw StateError('Butuh internet untuk chat.');
    final bersih = text.trim();
    if (bersih.isEmpty) return;
    final threadRef = db.collection('chat_threads').doc(groupThreadId);
    final msgRef = threadRef.collection('messages').doc();
    final batch = db.batch();
    batch.set(
        msgRef,
        ChatMessage(
          id: msgRef.id,
          senderId: uid,
          senderRole: 'customer',
          text: bersih,
          createdAt: DateTime.now(),
        ).toFirestore());
    batch.set(
        threadRef,
        {
          'type': 'group',
          'customerId': '',
          'customerName': 'Komunitas',
          'lastMessage': '$senderName: $bersih',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));
    await batch.commit();
  }

  // ============ RIWAYAT KOIN ============

  Stream<List<CoinEntry>> watchCoinLedger(String uid,
      {int limit = 50}) async* {
    final db = _db;
    if (db == null) {
      yield const [];
      return;
    }
    try {
      yield* db
          .collection('coin_ledger')
          .where('customerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => CoinEntry.fromDoc(d.id, d.data()))
              .toList());
    } catch (_) {
      yield const [];
    }
  }
}

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository(ref.watch(firestoreOrNullProvider));
});

final rumpiPostsProvider = StreamProvider<List<RumpiPost>>((ref) {
  return ref.watch(socialRepositoryProvider).watchRumpiPosts();
});

final myLikesProvider =
    StreamProvider.family<Set<String>, String>((ref, uid) {
  return ref.watch(socialRepositoryProvider).watchMyLikes(uid);
});

final myTokoThreadProvider =
    StreamProvider.family<ChatThread?, String>((ref, uid) {
  return ref.watch(socialRepositoryProvider).watchMyThread(uid);
});

final tokoMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, threadId) {
  return ref.watch(socialRepositoryProvider).watchThreadMessages(threadId);
});

final groupMessagesProvider = StreamProvider<List<ChatMessage>>((ref) {
  return ref.watch(socialRepositoryProvider).watchGroupMessages();
});

final coinLedgerProvider =
    StreamProvider.family<List<CoinEntry>, String>((ref, uid) {
  return ref.watch(socialRepositoryProvider).watchCoinLedger(uid);
});
