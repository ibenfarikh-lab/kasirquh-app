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
    // Anti-gagal-diam-diam: error Firestore DITERUSKAN ke UI (bukan ditelan).
    // UI wajib menangani via .when(error:) + tombol "Coba lagi".
    yield* _db
        .collection('products')
        .snapshots()
        .map((snap) => _fromDocs(snap.docs));
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
        stock: (m['stock'] as num?)?.toDouble() ?? 0.0,
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

  /// Jalur baca KHUSUS hitungan NILAI STOK di Catatan Belanja:
  /// SEMUA produk tanpa filter isActive (ikut PWA).
  /// Jangan dipakai untuk katalog/kasir — mereka tetap pakai
  /// watchProducts()/productsProvider yang memfilter nonaktif.
  Stream<List<Product>> watchAllProducts() async* {
    if (_db == null) {
      yield await _allFromSqlite();
      return;
    }
    try {
      yield* _db
          .collection('products')
          .snapshots()
          .map((snap) => _fromDocsAll(snap.docs));
    } catch (_) {
      yield await _allFromSqlite();
    }
  }

  /// Varian _fromDocs tanpa buang isActive == false.
  /// _fromDocs (jalur katalog/kasir) TIDAK diubah.
  List<Product> _fromDocsAll(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final list = <Product>[];
    for (final d in docs) {
      final m = d.data();
      list.add(Product(
        id: d.id,
        name: (m['name'] as String?) ?? '',
        category: (m['category'] as String?) ?? '',
        price: (m['price'] as num?)?.toInt() ?? 0,
        cost: (m['costPrice'] as num?)?.toInt() ?? 0,
        stock: (m['stock'] as num?)?.toDouble() ?? 0.0,
        lowStockAt: (m['lowStockAt'] as num?)?.toInt() ?? 5,
        barcode: m['barcode'] as String?,
        photoPath: m['photoUrl'] as String?,
        active: m['isActive'] != false,
      ));
    }
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<List<Product>> _allFromSqlite() async {
    try {
      final db = await AppDatabase.db;
      final rows = await db.query(
        'products',
        orderBy: 'name ASC',
      );
      return rows.map((r) => Product.fromMap(r)).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Ambil stok terkini satu produk dari server (untuk validasi checkout).
  Future<double?> fetchStock(String productId) async {
    if (_db == null) return null;
    final doc = await _db.collection('products').doc(productId).get();
    final data = doc.data();
    if (data == null) return null;
    return (data['stock'] as num?)?.toDouble();
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(firestoreOrNullProvider));
});

final productsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchProducts();
});

/// SEMUA produk tanpa filter isActive — KHUSUS hitungan NILAI STOK
/// (Catatan Belanja, ikut PWA). Jangan dipakai katalog/kasir.
final allProductsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchAllProducts();
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
