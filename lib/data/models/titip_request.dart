import 'package:cloud_firestore/cloud_firestore.dart';

/// Titip belanja — mekanisme terstruktur (Domain B).
/// Skema Firestore SAMA PERSIS dengan PWA (koleksi `titip_requests`).
class TitipRequest {
  final String id;
  final String customerId;
  final String customerName;
  final String item; // ≤100
  final String note; // ≤300
  final String method; // 'Ambil di warung' | 'Diantar ke rumah'
  final String status; // 'baru'
  final DateTime createdAt;

  const TitipRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.item,
    required this.note,
    required this.method,
    required this.status,
    required this.createdAt,
  });

  factory TitipRequest.fromDoc(
      String id, Map<String, dynamic> m) {
    final ts = m['createdAt'];
    return TitipRequest(
      id: id,
      customerId: (m['customerId'] as String?) ?? '',
      customerName: (m['customerName'] as String?) ?? 'Pelanggan',
      item: (m['item'] as String?) ?? '',
      note: (m['note'] as String?) ?? '',
      method: (m['method'] as String?) ?? '',
      status: (m['status'] as String?) ?? 'baru',
      createdAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
