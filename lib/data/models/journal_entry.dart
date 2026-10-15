/// Entri jurnal — satu kas terpusat (Pembukuan).
/// kind: 'penjualan' | 'kulakan' | 'beban' | 'modal'
class JournalEntry {
  final String id;
  final String kind;
  final String label;
  final int amount; // positif = masuk, negatif = keluar (Rp integer)
  final String? refId; // rujukan: id pesanan / nota / dokumen terkait
  final String? customerId; // member yang dilayani (kasir scan kartu)
  final String? customerName;
  final DateTime createdAt;

  const JournalEntry({
    required this.id,
    required this.kind,
    required this.label,
    required this.amount,
    this.refId,
    this.customerId,
    this.customerName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind,
        'label': label,
        'amount': amount,
        'refId': refId,
        'customerId': customerId,
        'customerName': customerName,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  Map<String, dynamic> toFirestore() => {
        'kind': kind,
        'label': label,
        'amount': amount,
        'customerId': customerId,
        'customerName': customerName,
        'createdAt': createdAt,
      };
}
