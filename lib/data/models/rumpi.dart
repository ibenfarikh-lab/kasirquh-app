import 'package:cloud_firestore/cloud_firestore.dart';

class RumpiPost {
  final String id;
  final String authorId;
  final String authorName;

  final String authorRole;
  final String authorPhoto;
  final String text;
  final String? imageUrl;
  final int likeCount;
  final bool isSeed;
  final DateTime createdAt;

  const RumpiPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorRole = 'customer',
    this.authorPhoto = '',
    required this.text,
    this.imageUrl,
    this.likeCount = 0,
    this.isSeed = false,
    required this.createdAt,
  });

  bool get punyaFoto => imageUrl != null && imageUrl!.isNotEmpty;
  bool get isAdmin => authorRole == 'admin';

  factory RumpiPost.fromDoc(String id, Map<String, dynamic> m) {
    final ts = m['createdAt'];
    return RumpiPost(
      id: id,
      authorId: (m['authorId'] as String?) ?? '',
      authorName: (m['authorName'] as String?) ?? '',
      authorRole: (m['authorRole'] as String?) ?? 'customer',
      authorPhoto: (m['authorPhoto'] as String?) ?? '',
      text: (m['text'] as String?) ?? '',
      imageUrl: m['imageUrl'] as String?,
      likeCount: (m['likeCount'] as num?)?.toInt() ?? 0,
      isSeed: (m['isSeed'] as bool?) ?? false,
      createdAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.fromMillisecondsSinceEpoch(
              (m['createdAt'] as num?)?.toInt() ?? 0),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'authorId': authorId,
        'authorName': authorName,
        'authorRole': authorRole,
        'authorPhoto': authorPhoto,
        'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'likeCount': 0,
        'isSeed': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class CoinEntry {
  final String id;
  final String customerId;
  final int amount;
  final String reason;
  final String label;
  final String detail;
  final String? orderId;
  final DateTime createdAt;

  const CoinEntry({
    required this.id,
    this.customerId = '',
    required this.amount,
    required this.reason,
    this.label = '',
    this.detail = '',
    this.orderId,
    required this.createdAt,
  });

  factory CoinEntry.fromDoc(String id, Map<String, dynamic> m) {
    final ts = m['createdAt'];
    return CoinEntry(
      id: id,
      customerId: (m['customerId'] as String?) ?? '',
      amount: (m['amount'] as num?)?.toInt() ?? 0,
      reason: (m['reason'] as String?) ?? '',
      label: (m['label'] as String?) ?? '',
      detail: (m['detail'] as String?) ?? '',
      orderId: m['orderId'] as String?,
      createdAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.fromMillisecondsSinceEpoch(
              (m['createdAt'] as num?)?.toInt() ?? 0),
    );
  }
}

String labelAlasanKoin(String reason) => switch (reason) {
      'harian' => 'Koin harian',
      'belanja' => 'Bonus belanja',
      'tukar' => 'Penukaran koin',
      'koreksi_admin' => 'Penyesuaian admin',
      'bonus_event' => 'Bonus event',
      _ => reason.isEmpty ? 'Lainnya' : reason,
    };

String waktuRelatif(DateTime t, {DateTime? sekarang}) {
  final now = sekarang ?? DateTime.now();
  final diff = now.difference(t);
  if (diff.isNegative) return 'baru saja';
  if (diff.inSeconds < 60) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  final minggu = diff.inDays ~/ 7;
  if (minggu < 5) return '$minggu mgg lalu';
  return '${t.day}/${t.month}/${t.year}';
}
