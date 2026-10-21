import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory StoreNote.fromDoc(String id, Map<String, dynamic> m) {
    final ts = m['createdAt'];
    return StoreNote(
      id: id,
      title: (m['title'] as String?) ?? '',
      body: (m['body'] as String?) ?? '',
      createdAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.fromMillisecondsSinceEpoch(
              (ts as num?)?.toInt() ?? 0),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toFirestoreMigrasi() => {
        'title': title,
        'body': body,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
