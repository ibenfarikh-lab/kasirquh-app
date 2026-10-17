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
    String authorRole = 'customer',
  }) async {
    final db = _db;
    if (db == null) throw StateError('Butuh internet untuk posting.');
    final bersih = text.trim();
    if (bersih.isEmpty) throw StateError('Tulis kabar dulu ya.');
    await db.collection('rumpi_posts').add(RumpiPost(
          id: '',
          authorId: uid,
          authorName: authorName,
          authorRole: authorRole,
          text: bersih,
          imageUrl: imageUrl,
          createdAt: DateTime.now(),
        ).toFirestore());
  }

  /// Hapus postingan Rumpi (moderasi admin) beserta like-nya.
  /// Rules: hanya admin atau penulis yang boleh hapus.
  Future<void> deletePost(String postId) async {
    final db = _db;
    if (db == null) throw StateError('Butuh internet untuk menghapus.');
    final postRef = db.collection('rumpi_posts').doc(postId);
    final likes = await postRef.collection('likes').get();
    final batch = db.batch();
    for (final d in likes.docs) {
      batch.delete(d.reference);
    }
    batch.delete(postRef);
    await batch.commit();
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
    // Anti-gagal-diam-diam: error DITERUSKAN ke UI.
    yield* db.collection('chat_threads').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return ChatThread.fromDoc(doc.id, data);
    });
  }

  Stream<List<ChatMessage>> watchThreadMessages(String threadId) async* {
    final db = _db;
    if (db == null) {
      yield const [];
      return;
    }
    // Anti-gagal-diam-diam: error DITERUSKAN ke UI.
    yield* db
        .collection('chat_threads')
        .doc(threadId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessage.fromDoc(d.id, d.data()))
            .toList());
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

  // ============ RIWAYAT KOIN ============

  Stream<List<CoinEntry>> watchCoinLedger(String uid,
      {int limit = 50}) async* {
    final db = _db;
    if (db == null) {
      yield const [];
      return;
    }
    try {
      // Tanpa orderBy di Firestore: query where+orderBy butuh composite index
      // khusus (tanpanya query gagal total — insiden 2026-10-09).
      // Urutkan di Dart (terbaru dulu).
      yield* db
          .collection('coin_ledger')
          .where('customerId', isEqualTo: uid)
          .limit(limit)
          .snapshots()
          .map((snap) {
        final list = snap.docs
            .map((d) => CoinEntry.fromDoc(d.id, d.data()))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    } catch (_) {
      yield const [];
    }
  }

  // ============ GAME (Misi Koin) ============

  /// Hasil klaim koin game.
  /// Ikut pola Web (Store.grantGameCoins): transaction atomik,
  /// kuota 500 koin/hari DIPISAH per game (via dateField/todayField).
  Future<({int granted, bool capped})> grantGameCoins(
    String uid,
    int requestedCoins, {
    required int points,
    required String reason,
    required String label,
    required String dateField,
    required String todayField,
    required String eventKey, // 'tangkapDiskon' atau 'buruDiskon'
  }) async {
    final db = _db;
    requestedCoins = requestedCoins.clamp(0, 100000);
    if (db == null || uid.isEmpty || requestedCoins <= 0) {
      return (granted: 0, capped: false);
    }
    const maxPerDay = 500;
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return db.runTransaction((tx) async {
      // Cek program koin & event aktif — selaras Web.
      final settingsSnap =
          await tx.get(db.collection('store_settings').doc('main'));
      final settings = settingsSnap.data() ?? {};
      final programOn = settings['coinProgramEnabled'] != false;
      final events =
          (settings['coinEvents'] as Map? ?? {}).map(
        (k, v) => MapEntry(k.toString(), v == true),
      );
      final eventOn = events[eventKey] ?? true;
      if (!programOn || !eventOn) {
        throw StateError('Program koin sedang dimatikan admin');
      }

      final ref = db.collection('customers').doc(uid);
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final already = (data[dateField] == today)
          ? ((data[todayField] as num?)?.toInt() ?? 0).clamp(0, 100000)
          : 0;
      final grant = (requestedCoins).clamp(0, maxPerDay - already);
      if (grant <= 0) return (granted: 0, capped: true);
      tx.update(ref, {
        'coins': FieldValue.increment(grant),
        dateField: today,
        todayField: already + grant,
      });
      tx.set(db.collection('coin_ledger').doc(), {
        'customerId': uid,
        'amount': grant,
        'reason': reason,
        'label': label,
        'detail': '$points poin',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return (granted: grant, capped: grant < requestedCoins);
    });
  }

  /// Progres koin game hari ini (untuk tile progres).
  Future<int> gameCoinsToday(
      String uid, String dateField, String todayField) async {
    final db = _db;
    if (db == null || uid.isEmpty) return 0;
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      final doc = await db.collection('customers').doc(uid).get();
      final data = doc.data();
      if (data == null || data[dateField] != today) return 0;
      return ((data[todayField] as num?)?.toInt() ?? 0).clamp(0, 100000);
    } catch (_) {
      return 0;
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

final coinLedgerProvider =
    StreamProvider.family<List<CoinEntry>, String>((ref, uid) {
  return ref.watch(socialRepositoryProvider).watchCoinLedger(uid);
});
