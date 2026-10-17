/// Model Pelanggan — mirror koleksi Firestore `customers`.
/// approvalStatus: pending | approved | rejected
///
/// Kode member: 'KQ-' + 8 karakter pertama UID (uppercase).
/// Format IDENTIK dengan PWA — jangan diubah sepihak.
String memberCodeFromUid(String uid) {
  final bersih =
      uid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
  final potong = bersih.length >= 8
      ? bersih.substring(0, 8)
      : bersih.padRight(8, '0');
  return 'KQ-$potong';
}

class Customer {
  final String uid;
  final String name;
  final String email;
  final String? wa; // nomor WA opsional (skema)
  final String? address; // alamat opsional — selaras Web ?v=20261020ar
  final String? photoURL; // foto profil base64 — selaras Web (2026-10-18)
  final String approvalStatus;
  final int coins;
  final String? memberCode;
  final DateTime createdAt;

  const Customer({
    required this.uid,
    required this.name,
    required this.email,
    this.wa,
    this.address,
    this.photoURL,
    required this.approvalStatus,
    this.coins = 0,
    this.memberCode,
    required this.createdAt,
  });

  bool get isApproved => approvalStatus == 'approved';

  /// Kode member — dari field DB, fallback hitung dari UID.
  String get kodeMember => memberCode ?? memberCodeFromUid(uid);

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'wa': wa,
        'address': address,
        'photoURL': photoURL,
        'approvalStatus': approvalStatus,
        'coins': coins,
        'memberCode': memberCode,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
        uid: m['uid'] as String,
        name: m['name'] as String? ?? '',
        email: m['email'] as String? ?? '',
        wa: m['wa'] as String?,
        address: m['address'] as String?,
        photoURL: m['photoURL'] as String?,
        approvalStatus: m['approvalStatus'] as String? ?? 'pending',
        coins: (m['coins'] as num?)?.toInt() ?? 0,
        memberCode: m['memberCode'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (m['createdAt'] as num?)?.toInt() ?? 0),
      );

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'wa': wa,
        'address': address,
        'photoURL': photoURL,
        'approvalStatus': approvalStatus,
        'coins': coins,
        'memberCode': memberCode,
        'createdAt': createdAt,
      };
}
