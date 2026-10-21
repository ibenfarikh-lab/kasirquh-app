// Impor produk dari CSV — port setia fungsi Web
// (ProductsPage.tsx: parseCsvText, parseCsvNumber, mapCsvRows).
// Fungsi murni, tanpa Flutter — bisa di-unit-test.
library;

/// Satu baris produk hasil parse CSV.
class CsvProductItem {
  final String barcode;
  final String name;
  final String photo;
  final String cat;
  final String unit;
  final double stock;
  final double cost;
  final double price;

  const CsvProductItem({
    required this.barcode,
    required this.name,
    required this.photo,
    required this.cat,
    required this.unit,
    required this.stock,
    required this.cost,
    required this.price,
  });
}

/// Hasil pemetaan baris CSV: item valid + baris yang dilewati.
class CsvParseResult {
  final List<CsvProductItem> items;
  final List<({int row, String reason})> skipped;
  const CsvParseResult(this.items, this.skipped);
}

/// Alias judul kolom (Indonesia/Inggris), persis Web.
const csvHeaderAliases = <String, List<String>>{
  'barcode': ['kode', 'barcode', 'kode barang', 'kode produk', 'sku', 'plu'],
  'name': ['nama', 'nama produk', 'nama barang', 'produk'],
  'cat': ['kategori', 'category', 'kat'],
  'unit': ['satuan', 'unit'],
  'stock': ['stok', 'stock', 'jumlah', 'qty'],
  'cost': ['modal', 'harga modal', 'cost', 'harga beli', 'harga kulak'],
  'price': ['harga', 'harga jual', 'price'],
  'photo': ['foto', 'photo', 'gambar', 'image', 'photourl', 'foto url'],
};

/// Parse angka format campuran: "1.500" = 1500 (ribuan titik),
/// "2,5" = 2.5 (desimal koma) — persis parseCsvNumber Web.
double parseCsvNumber(Object? value) {
  var s = (value?.toString() ?? '').trim().replaceAll(RegExp(r'\s+'), '');
  if (s.isEmpty) return 0;
  if (RegExp(r'^-?\d{1,3}(\.\d{3})+(,\d+)?$').hasMatch(s)) {
    s = s.replaceAll('.', '').replaceAll(',', '.');
  } else {
    s = s.replaceAll(',', '.');
  }
  return double.tryParse(s) ?? 0;
}

/// Pecah teks CSV menjadi baris-baris sel — sadar tanda kutip
/// ("" = kutip lepas), pemisah koma, baris kosong dibuang.
List<List<String>> parseCsvText(Object? text) {
  final rows = <List<String>>[];
  var row = <String>[];
  var field = '';
  var inQuotes = false;
  void pushField() {
    row.add(field);
    field = '';
  }

  void pushRow() {
    if (row.any((c) => c.trim() != '')) rows.add(row);
    row = [];
  }

  var src = text?.toString() ?? '';
  if (src.startsWith('\uFEFF')) src = src.substring(1);
  for (var i = 0; i < src.length; i++) {
    final ch = src[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < src.length && src[i + 1] == '"') {
          field += '"';
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field += ch;
      }
    } else if (ch == '"') {
      inQuotes = true;
    } else if (ch == ',') {
      pushField();
    } else if (ch == '\r') {
      // ikut \n
    } else if (ch == '\n') {
      pushField();
      pushRow();
    } else {
      field += ch;
    }
  }
  pushField();
  pushRow();
  return rows;
}

/// Petakan baris CSV (baris pertama = judul) menjadi item produk.
/// Dedup per barcode di dalam file (baris terakhir menang), persis Web.
CsvParseResult mapCsvRows(List<List<String>> rows) {
  final items = <CsvProductItem>[];
  final skipped = <({int row, String reason})>[];
  if (rows.isEmpty) return CsvParseResult(items, skipped);
  final header = rows.first.map((h) => h.trim().toLowerCase()).toList();
  final colIndex = <String, int>{};
  for (final key in csvHeaderAliases.keys) {
    colIndex[key] =
        header.indexWhere((h) => csvHeaderAliases[key]!.contains(h));
  }
  if ((colIndex['name'] ?? -1) < 0) {
    skipped.add((
      row: 1,
      reason: 'kolom Nama tidak ditemukan di baris judul',
    ));
    return CsvParseResult(items, skipped);
  }
  final seen = <String, CsvProductItem>{};
  for (var i = 1; i < rows.length; i++) {
    final cells = rows[i];
    final lineNo = i + 1;
    String get(String key) {
      final idx = colIndex[key] ?? -1;
      if (idx < 0 || idx >= cells.length) return '';
      return cells[idx].trim();
    }

    final name = get('name');
    if (name.isEmpty) {
      skipped.add((row: lineNo, reason: 'tanpa nama'));
      continue;
    }
    final barcode = get('barcode');
    final dedupeKey = barcode.isNotEmpty ? 'kode:$barcode' : 'baris:$lineNo';
    seen[dedupeKey] = CsvProductItem(
      barcode: barcode,
      name: name,
      photo: get('photo'),
      cat: get('cat').isEmpty ? 'Lainnya' : get('cat'),
      unit: get('unit').isEmpty ? 'pcs' : get('unit'),
      stock: parseCsvNumber(get('stock')),
      cost: parseCsvNumber(get('cost')),
      price: parseCsvNumber(get('price')),
    );
  }
  items.addAll(seen.values);
  return CsvParseResult(items, skipped);
}
