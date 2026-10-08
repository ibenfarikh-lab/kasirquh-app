/// Model Produk — mirror koleksi Firestore `products`.
class Product {
  final String id;
  final String name;
  final String category;
  final int price; // harga jual (Rp, integer)
  final int cost; // modal/pcs (Rp, integer)
  /// Stok desimal — kg/liter WAJIB mempertahankan presisi
  /// (cth. 3,75); pcs/dus tampil bulat. Jangan .toInt()/.round().
  final double stock;
  final int lowStockAt; // batas menipis per produk (default 5)
  final String? barcode;
  final String? photoPath;
  final bool active;
  /// Satuan produk (pcs/dus/kg/liter/dll) — dari PWA.
  final String unit;
  /// Harga grosir: min qty, harga/item, dan label — dari PWA.
  final int wholesaleQty;
  final int wholesalePrice;
  final String wholesaleLabel;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.cost,
    required this.stock,
    this.lowStockAt = 5,
    this.barcode,
    this.photoPath,
    this.active = true,
    this.unit = 'pcs',
    this.wholesaleQty = 0,
    this.wholesalePrice = 0,
    this.wholesaleLabel = '',
  });

  /// Ada harga grosir?
  bool get adaGrosir => wholesaleQty > 0 && wholesalePrice > 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'cost': cost,
        'stock': stock,
        'lowStockAt': lowStockAt,
        'barcode': barcode,
        'photoPath': photoPath,
        'active': active ? 1 : 0,
        'unit': unit,
        'wholesaleQty': wholesaleQty,
        'wholesalePrice': wholesalePrice,
        'wholesaleLabel': wholesaleLabel,
      };

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as String,
        name: m['name'] as String,
        category: m['category'] as String? ?? '',
        price: (m['price'] as num).toInt(),
        cost: (m['cost'] as num?)?.toInt() ?? 0,
        stock: (m['stock'] as num).toDouble(),
        lowStockAt: (m['lowStockAt'] as num?)?.toInt() ?? 5,
        barcode: m['barcode'] as String?,
        photoPath: m['photoPath'] as String?,
        active: (m['active'] == 1 || m['active'] == true),
        unit: m['unit'] as String? ?? 'pcs',
        wholesaleQty: (m['wholesaleQty'] as num?)?.toInt() ?? 0,
        wholesalePrice: (m['wholesalePrice'] as num?)?.toInt() ?? 0,
        wholesaleLabel: m['wholesaleLabel'] as String? ?? '',
      );

  /// Payload Firestore — NAMA FIELD SELARAS SKEMA
  /// (costPrice / photoUrl / isActive / lowStockAt; tanpa 'id').
  Map<String, dynamic> toFirestore() => {
        'name': name,
        'category': category,
        'price': price,
        'costPrice': cost,
        'stock': stock,
        'lowStockAt': lowStockAt,
        'barcode': barcode,
        'photoUrl': photoPath,
        'isActive': active,
        'unit': unit,
        'wholesaleQty': wholesaleQty,
        'wholesalePrice': wholesalePrice,
        'wholesaleLabel': wholesaleLabel,
      };
}
