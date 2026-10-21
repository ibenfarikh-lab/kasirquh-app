class CustomerNote {
  final String id;
  final String customerId;
  final String type;
  final int amount;
  final String note;
  final DateTime createdAt;

  const CustomerNote({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.note,
    required this.createdAt,
  });

  factory CustomerNote.fromDoc(String id, Map<String, dynamic> m) {
    final ts = m['createdAt'];
    return CustomerNote(
      id: id,
      customerId: (m['customerId'] as String?) ?? '',
      type: (m['type'] as String?) ?? 'catatan',
      amount: (m['amount'] as num?)?.toInt() ?? 0,
      note: (m['note'] as String?) ?? '',
      createdAt: ts is DateTime
          ? ts
          : DateTime.fromMillisecondsSinceEpoch(
              (m['createdAt'] as num?)?.toInt() ?? 0),
    );
  }
}

String customerNoteTypeLabel(String type) => switch (type) {
      'tagihan' => 'Tagihan',
      'pembayaran' => 'Pembayaran',
      'umum' => 'Catatan Umum',
      _ => 'Catatan',
    };

String customerNoteTypeFromForm(String formValue) => switch (formValue) {
      'belanja' => 'tagihan',
      'cicilan' => 'tagihan',
      'pembayaran' => 'pembayaran',
      'umum' => 'catatan',
      _ => formValue,
    };

int totalTagihan(List<CustomerNote> notes) {
  var total = 0;
  for (final n in notes) {
    if (n.type == 'tagihan') {
      total += n.amount;
    } else if (n.type == 'pembayaran') {
      total -= n.amount;
    }
  }
  return total;
}
