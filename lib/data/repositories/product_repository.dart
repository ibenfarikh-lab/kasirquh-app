import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/models/product.dart';
import '../../data/remote/firestore_service.dart';

/// Kategori katalog kelontong (keputusan dikunci).
const kProductCategories = [
  'Sembako',
  'Minuman',
  'Snack',
  'Rokok',
  'Rumah Tangga',
];

/// Repository katalog: baca Firestore (publik, server menang untuk stok)
/// dengan fallback SQLite saat offline/mode lokal.
/// Catatan: ambang "stok menipis" kini per produk (Product.lowStockAt,
/// selaras skema), bukan konstanta global lagi.
class ProductRepository {
  final FirebaseFirestore? _db;

  ProductRepository(this._db);

  Stream<List<Product>> watchProducts() async* {
    if (_db == null) {
      yield await _fromSqlite();
      return;
    }
    try {
      yield* _db
          .collection('products')
          .snapshots()
          .map((snap) => _fromDocs(snap.docs));
    } catch (_) {
      yield await _fromSqlite();
    }
  }

  List<Product> _fromDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final list = <Product>[];
    for (final d in docs) {
      final m = d.data();
      if (m['isActive'] == false) continue;
      list.add(Product(
        id: d.id,
        name: (m['name'] as String?) ?? '',
        category: (m['category'] as String?) ?? '',
        price: (m['price'] as num?)?.toInt() ?? 0,
        cost: (m['costPrice'] as num?)?.toInt() ?? 0,
        stock: (m['stock'] as num?)?.toInt() ?? 0,
        lowStockAt: (m['lowStockAt'] as num?)?.toInt() ?? 5,
        barcode: m['barcode'] as String?,
        photoPath: m['photoUrl'] as String?,
        active: true,
      ));
    }
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<List<Product>> _fromSqlite() async {
    try {
      final db = await AppDatabase.db;
      final rows = await db.query(
        'products',
        where: 'active = 1',
        orderBy: 'name ASC',
      );
      return rows.map((r) => Product.fromMap(r)).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Ambil stok terkini satu produk dari server (untuk validasi checkout).
  Future<int?> fetchStock(String productId) async {
    if (_db == null) return null;
    final doc = await _db.collection('products').doc(productId).get();
    final data = doc.data();
    if (data == null) return null;
    return (data['stock'] as num?)?.toInt();
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(firestoreOrNullProvider));
});

final productsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchProducts();
});

/// Filter katalog murni — bisa di-unit-test.
List<Product> filterProducts(
  List<Product> all, {
  String query = '',
  String category = '',
}) {
  final q = query.trim().toLowerCase();
  return all.where((p) {
    final matchCat = category.isEmpty || p.category == category;
    final matchQuery = q.isEmpty ||
        p.name.toLowerCase().contains(q) ||
        (p.barcode?.toLowerCase().contains(q) ?? false);
    return matchCat && matchQuery;
  }).toList();
}
