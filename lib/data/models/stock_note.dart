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
  /// Jumlah — boleh desimal (cth. 2,5 kg). Jangan .toInt().
  final double qty;
  final int price; // harga per satuan/baris (Rp integer)

  const StockNoteItem({
    required this.name,
    required this.qty,
    required this.price,
  });

  Map<String, dynamic> toMap() =>
      {'name': name, 'qty': qty, 'price': price};

  factory StockNoteItem.fromMap(Map<String, dynamic> m) {
    int asInt(dynamic v) =>
        v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    double asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      // PWA menulis qty sebagai string ('1') — terima keduanya;
      // koma Indonesia ('3,75') juga diterima.
      return double.tryParse('$v'.replaceAll(',', '.')) ?? 0;
    }

    return StockNoteItem(
      name: m['name'] as String? ?? '',
      qty: asDouble(m['qty']),
      price: asInt(m['price']),
    );
  }

  double get subtotal => qty * price;
}
