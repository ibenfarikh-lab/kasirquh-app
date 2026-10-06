import 'dart:convert';

/// Catatan Belanja Harian — mirror koleksi Firestore `stock_notes`.
/// source: 'manual' | 'belanja_stok'.
/// items: [{name, qty, price}] — qty & price integer.
class StockNote {
  final String id;
  final String date; // YYYY-MM-DD
  final String supplier;
  final List<StockNoteItem> items;
  final int total;
  final String source;
  final DateTime createdAt;

  const StockNote({
    required this.id,
    required this.date,
    required this.supplier,
    required this.items,
    required this.total,
    this.source = 'manual',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'supplier': supplier,
        'items': jsonEncode(items.map((e) => e.toMap()).toList()),
        'total': total,
        'source': source,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory StockNote.fromMap(Map<String, dynamic> m) => StockNote(
        id: m['id'] as String,
        date: m['date'] as String? ?? '',
        supplier: m['supplier'] as String? ?? '',
        items: itemsFrom(m['items']),
        total: (m['total'] as num?)?.toInt() ?? 0,
        source: m['source'] as String? ?? 'manual',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (m['createdAt'] as num?)?.toInt() ?? 0),
      );

  Map<String, dynamic> toFirestore() => {
        'date': date,
        'supplier': supplier,
        'items': items.map((e) => e.toMap()).toList(),
        'total': total,
        'source': source,
        'createdAt': createdAt,
      };

  static List<StockNoteItem> itemsFrom(dynamic raw) {
    try {
      final list = raw is String ? jsonDecode(raw) as List : raw as List;
      return list
          .map((e) => StockNoteItem.fromMap(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

class StockNoteItem {
  final String name;
  final int qty;
  final int price; // harga per satuan/baris (Rp integer)

  const StockNoteItem({
    required this.name,
    required this.qty,
    required this.price,
  });

  Map<String, dynamic> toMap() =>
      {'name': name, 'qty': qty, 'price': price};

  factory StockNoteItem.fromMap(Map<String, dynamic> m) => StockNoteItem(
        name: m['name'] as String? ?? '',
        qty: (m['qty'] as num?)?.toInt() ?? 0,
        price: (m['price'] as num?)?.toInt() ?? 0,
      );

  int get subtotal => qty * price;
}
