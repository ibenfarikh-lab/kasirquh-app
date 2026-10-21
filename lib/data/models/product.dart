class Product {
  final String id;
  final String name;
  final String category;
  final int price;
  final int cost;
  final double stock;
  final int lowStockAt;
  final String? barcode;
  final String? photoPath;
  final bool active;
  final String unit;
  final int wholesaleQty;
  final int wholesalePrice;
  final String wholesaleLabel;
  final bool budgetEligible;
  final int budgetMaxQty;

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
    this.budgetEligible = true,
    this.budgetMaxQty = 4,
  });

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
        'budgetEligible': budgetEligible ? 1 : 0,
        'budgetMaxQty': budgetMaxQty,
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
        budgetEligible: m['budgetEligible'] != 0 && m['budgetEligible'] != false,
        budgetMaxQty: (m['budgetMaxQty'] as num?)?.toInt() ?? 4,
      );

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
        'budgetEligible': budgetEligible,
        'budgetMaxQty': budgetMaxQty,
      };
}
