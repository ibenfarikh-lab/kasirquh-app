import 'package:cloud_firestore/cloud_firestore.dart';

/// Item dalam paket: produk + qty.
class PaketItem {
  final String productId;
  final int qty;

  const PaketItem({required this.productId, required this.qty});

  factory PaketItem.fromMap(Map<String, dynamic> m) => PaketItem(
        productId: (m['productId'] as String?) ?? '',
        qty: (m['qty'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toMap() => {'productId': productId, 'qty': qty};
}

/// Paket Belanja — skema SAMA PERSIS dengan PWA.
/// Dipakai untuk koleksi `rutinPackages` dan `hajatanPackages`.
/// Field: name, description, items [{productId, qty}], isActive.
class PaketBelanja {
  final String id;
  final String name;
  final String description;
  final List<PaketItem> items;
  final bool isActive;
  final DateTime createdAt;

  const PaketBelanja({
    required this.id,
    required this.name,
    required this.description,
    required this.items,
    required this.isActive,
    required this.createdAt,
  });

  factory PaketBelanja.fromDoc(String id, Map<String, dynamic> m) {
    final ts = m['createdAt'];
    final items = (m['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PaketItem.fromMap)
        .toList();
    return PaketBelanja(
      id: id,
      name: (m['name'] as String?) ?? '',
      description: (m['description'] as String?) ?? '',
      items: items,
      isActive: m['isActive'] != false,
      createdAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
