class JournalEntry {
  final String id;
  final String kind;
  final String label;
  final int amount;
  final String? refId;
  final String? customerId;
  final String? customerName;
  final DateTime createdAt;
  final int profit;
  final String method;
  final num itemCount;

  const JournalEntry({
    required this.id,
    required this.kind,
    required this.label,
    required this.amount,
    this.refId,
    this.customerId,
    this.customerName,
    required this.createdAt,
    this.profit = 0,
    this.method = '',
    this.itemCount = 0,
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
