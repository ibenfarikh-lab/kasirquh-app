import 'package:cloud_firestore/cloud_firestore.dart';

class ChatThread {
  final String id;
  final String type;
  final String customerId;
  final String customerName;
  final String? lastMessage;
  final int unreadAdmin;
  final int unreadCustomer;
  final DateTime updatedAt;

  const ChatThread({
    required this.id,
    this.type = 'toko',
    required this.customerId,
    required this.customerName,
    this.lastMessage,
    this.unreadAdmin = 0,
    this.unreadCustomer = 0,
    required this.updatedAt,
  });

  factory ChatThread.fromDoc(String id, Map<String, dynamic> m) {
    final ts = m['updatedAt'];
    return ChatThread(
      id: id,
      type: (m['type'] as String?) ?? 'toko',
      customerId: (m['customerId'] as String?) ?? '',
      customerName: (m['customerName'] as String?) ?? '',
      lastMessage: m['lastMessage'] as String?,
      unreadAdmin: (m['unreadAdmin'] as num?)?.toInt() ?? 0,
      unreadCustomer: (m['unreadCustomer'] as num?)?.toInt() ?? 0,
      updatedAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderRole;
  final String text;
  final String imageUrl;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    this.imageUrl = '',
    required this.createdAt,
  });

  bool get fromAdmin => senderRole == 'admin';
  bool get punyaFoto => imageUrl.isNotEmpty;

  factory ChatMessage.fromDoc(String id, Map<String, dynamic> m) {
    final ts = m['createdAt'];
    return ChatMessage(
      id: id,
      senderId: (m['senderId'] as String?) ?? '',
      senderRole: (m['senderRole'] as String?) ?? 'customer',
      text: (m['text'] as String?) ?? '',
      imageUrl: (m['imageUrl'] as String?) ?? '',
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
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
