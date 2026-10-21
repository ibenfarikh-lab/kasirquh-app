class RecipeItem {
  final String productId;
  final int qty;

  const RecipeItem({required this.productId, this.qty = 1});

  factory RecipeItem.fromMap(Map<String, dynamic> m) => RecipeItem(
        productId: m['productId'] as String? ?? '',
        qty: (m['qty'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toMap() => {'productId': productId, 'qty': qty};
}

class Recipe {
  final String id;
  final String nama;
  final String desc;
  final String foto;
  final List<RecipeItem> items;

  const Recipe({
    required this.id,
    required this.nama,
    this.desc = '',
    this.foto = '',
    this.items = const [],
  });

  factory Recipe.fromDoc(String id, Map<String, dynamic> d) => Recipe(
        id: id,
        nama: (d['nama'] as String? ?? '').trim(),
        desc: (d['desc'] as String? ?? '').trim(),
        foto: (d['foto'] as String? ?? '').trim(),
        items: ((d['items'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(RecipeItem.fromMap)
            .where((it) => it.productId.isNotEmpty)
            .toList(),
      );

  int totalHarga(Map<String, int> hargaProduk) => items.fold(
      0,
      (sum, it) =>
          sum + (hargaProduk[it.productId] ?? 0) * it.qty);

  String teksBahan(Map<String, String> namaProduk) => items
      .map((it) {
        final nama = namaProduk[it.productId];
        return nama == null ? '' : '$nama ×${it.qty}';
      })
      .where((s) => s.isNotEmpty)
      .join(', ');
}
