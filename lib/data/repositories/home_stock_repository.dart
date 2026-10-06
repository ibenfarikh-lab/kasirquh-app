import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_database.dart';

/// Catatan stok rumah pelanggan — lokal per-perangkat, tidak disinkron.
/// Dipakai section "Stok rumah habis?" di Beranda (Dari riwayat belanjamu).
class HomeStockItem {
  final String id;
  final String name;
  final String status; // 'habis' | 'menipis'
  final DateTime createdAt;

  const HomeStockItem({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
  });

  factory HomeStockItem.fromMap(Map<String, dynamic> m) => HomeStockItem(
        id: (m['id'] as String?) ?? '',
        name: (m['name'] as String?) ?? '',
        status: (m['status'] as String?) ?? 'habis',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (m['createdAt'] as num?)?.toInt() ?? 0),
      );
}

/// Status stok rumah — dari konstanta, bukan string bebas.
String homeStockLabel(String status) =>
    status == 'menipis' ? 'Menipis' : 'Habis';

class HomeStockRepository {
  String _newId() =>
      'hs${DateTime.now().millisecondsSinceEpoch}';

  Future<List<HomeStockItem>> all() async {
    final db = await AppDatabase.db;
    final rows = await db.query('home_stock',
        orderBy: 'createdAt DESC', limit: 50);
    return rows.map(HomeStockItem.fromMap).toList();
  }

  Future<void> add(String name, String status) async {
    final db = await AppDatabase.db;
    await db.insert('home_stock', {
      'id': _newId(),
      'name': name.trim(),
      'status': status,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> setStatus(String id, String status) async {
    final db = await AppDatabase.db;
    await db.update('home_stock', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> remove(String id) async {
    final db = await AppDatabase.db;
    await db.delete('home_stock', where: 'id = ?', whereArgs: [id]);
  }
}

final homeStockRepositoryProvider =
    Provider<HomeStockRepository>((ref) => HomeStockRepository());

final homeStockProvider =
    FutureProvider<List<HomeStockItem>>((ref) async {
  return ref.watch(homeStockRepositoryProvider).all();
});
