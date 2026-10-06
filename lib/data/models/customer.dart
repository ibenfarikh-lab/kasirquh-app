/// Model Pelanggan — mirror koleksi Firestore `customers`.
/// approvalStatus: pending | approved | rejected
class Customer {
  final String uid;
  final String name;
  final String email;
  final String? wa; // nomor WA opsional (skema)
  final String approvalStatus;
  final int coins;
  final DateTime createdAt;

  const Customer({
    required this.uid,
    required this.name,
    required this.email,
    this.wa,
    required this.approvalStatus,
    this.coins = 0,
    required this.createdAt,
  });

  bool get isApproved => approvalStatus == 'approved';

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'wa': wa,
        'approvalStatus': approvalStatus,
        'coins': coins,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
        uid: m['uid'] as String,
        name: m['name'] as String? ?? '',
        email: m['email'] as String? ?? '',
        wa: m['wa'] as String?,
        approvalStatus: m['approvalStatus'] as String? ?? 'pending',
        coins: (m['coins'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (m['createdAt'] as num?)?.toInt() ?? 0),
      );

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'approvalStatus': approvalStatus,
        'coins': coins,
        'createdAt': createdAt,
      };
}
