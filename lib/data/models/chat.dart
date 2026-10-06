import 'package:cloud_firestore/cloud_firestore.dart';

/// Thread chat — mirror koleksi Firestore `chat_threads`.
/// Satu thread per pelanggan (type 'toko'); tidak bocor antar-thread.
class ChatThread {
  final String id;
  final String customerId;
  final String customerName;
  final String? lastMessage;
  final int unreadAdmin;
  final DateTime updatedAt;

  const ChatThread({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.lastMessage,
    this.unreadAdmin = 0,
    required this.updatedAt,
  });

  factory ChatThread.fromDoc(String id, Map<String, dynamic> m) {
    final ts = m['updatedAt'];
    return ChatThread(
      id: id,
      customerId: (m['customerId'] as String?) ?? '',
      customerName: (m['customerName'] as String?) ?? '',
      lastMessage: m['lastMessage'] as String?,
      unreadAdmin: (m['unreadAdmin'] as num?)?.toInt() ?? 0,
      updatedAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Pesan chat — mirror subkoleksi `chat_threads/{id}/messages`.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderRole; // 'admin' | 'customer'
  final String text;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  bool get fromAdmin => senderRole == 'admin';

  factory ChatMessage.fromDoc(String id, Map<String, dynamic> m) {
    final ts = m['createdAt'];
    return ChatMessage(
      id: id,
      senderId: (m['senderId'] as String?) ?? '',
      senderRole: (m['senderRole'] as String?) ?? 'customer',
      text: (m['text'] as String?) ?? '',
      createdAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.fromMillisecondsSinceEpoch(
              (m['createdAt'] as num?)?.toInt() ?? 0),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'senderId': senderId,
        'senderRole': senderRole,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
