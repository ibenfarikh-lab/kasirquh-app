import 'package:cloud_firestore/cloud_firestore.dart';

/// Peserta patungan — skema SAMA PERSIS dengan PWA.
class PatunganParticipant {
  final String customerId;
  final String name;
  final int slots;
  final DateTime joinedAt;

  const PatunganParticipant({
    required this.customerId,
    required this.name,
    required this.slots,
    required this.joinedAt,
  });

  factory PatunganParticipant.fromMap(Map<String, dynamic> m) {
    final ja = m['joinedAt'];
    DateTime parsed;
    if (ja is Timestamp) {
      parsed = ja.toDate();
    } else if (ja is String) {
      parsed = DateTime.tryParse(ja) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      parsed = DateTime.fromMillisecondsSinceEpoch(0);
    }
    return PatunganParticipant(
      customerId: (m['customerId'] as String?) ?? '',
      name: (m['name'] as String?) ?? 'Warga',
      slots: (m['slots'] as num?)?.toInt() ?? 1,
      joinedAt: parsed,
    );
  }

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'name': name,
        'slots': slots,
        'joinedAt': joinedAt.toIso8601String(),
      };
}

/// Patungan Warga — skema SAMA PERSIS dengan PWA (koleksi `patungan`).
/// Status: 'aktif' | 'penuh' | 'selesai' | 'batal'
class Patungan {
  final String id;
  final String title;
  final String productName;
  final int pricePerSlot;
  final int totalSlots;
  final int filledSlots;
  final List<PatunganParticipant> participants;
  final String deadline;
  final String note;
  final String status;
  final DateTime createdAt;

  const Patungan({
    required this.id,
    required this.title,
    required this.productName,
    required this.pricePerSlot,
    required this.totalSlots,
    required this.filledSlots,
    required this.participants,
    required this.deadline,
    required this.note,
    required this.status,
    required this.createdAt,
  });

  /// Slot tersisa.
  int get remainingSlots => totalSlots - filledSlots;

  /// Persentase terisi (0-100).
  int get percentFilled =>
      totalSlots > 0 ? (filledSlots * 100 ~/ totalSlots).clamp(0, 100) : 0;

  /// Apakah pelanggan tertentu sudah ikut.
  bool isJoined(String customerId) =>
      participants.any((p) => p.customerId == customerId);

  factory Patungan.fromDoc(String id, Map<String, dynamic> m) {
    final ts = m['createdAt'];
    final parts = m['participants'];
    return Patungan(
      id: id,
      title: (m['title'] as String?) ?? '',
      productName: (m['productName'] as String?) ?? '',
      pricePerSlot: (m['pricePerSlot'] as num?)?.toInt() ?? 0,
      totalSlots: (m['totalSlots'] as num?)?.toInt() ?? 0,
      filledSlots: (m['filledSlots'] as num?)?.toInt() ?? 0,
      participants: parts is List
          ? parts
              .whereType<Map<String, dynamic>>()
              .map(PatunganParticipant.fromMap)
              .toList()
          : const [],
      deadline: (m['deadline'] as String?) ?? '',
      note: (m['note'] as String?) ?? '',
      status: (m['status'] as String?) ?? 'aktif',
      createdAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
