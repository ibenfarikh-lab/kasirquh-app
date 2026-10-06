/// Entri jurnal — satu kas terpusat (Pembukuan).
/// kind: 'penjualan' | 'kulakan' | 'beban' | 'modal'
class JournalEntry {
  final String id;
  final String kind;
  final String label;
  final int amount; // positif = masuk, negatif = keluar (Rp integer)
  final DateTime createdAt;

  const JournalEntry({
    required this.id,
    required this.kind,
    required this.label,
    required this.amount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind,
        'label': label,
        'amount': amount,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  Map<String, dynamic> toFirestore() => {
        'kind': kind,
        'label': label,
        'amount': amount,
        'createdAt': createdAt,
      };
}
