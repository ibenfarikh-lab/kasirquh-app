/// Catatan Toko — coretan admin. Disimpan lokal saja
/// (tidak ada koleksi Firestore/rules untuknya).
class StoreNote {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  const StoreNote({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory StoreNote.fromMap(Map<String, dynamic> m) => StoreNote(
        id: m['id'] as String,
        title: (m['title'] as String?) ?? '',
        body: (m['body'] as String?) ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (m['createdAt'] as num?)?.toInt() ?? 0),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}
