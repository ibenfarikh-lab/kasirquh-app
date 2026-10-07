import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/product.dart';

/// Satu baris keranjang.
class CartLine {
  final Product product;
  final int qty;
  final int? hargaSatuan; // override harga (mis. harga promo saat ditambah)

  const CartLine({required this.product, required this.qty, this.hargaSatuan});

  int get harga => hargaSatuan ?? product.price;

  int get subtotal => harga * qty;

  CartLine copyWith({Product? product, int? qty, int? hargaSatuan}) =>
      CartLine(
          product: product ?? this.product,
          qty: qty ?? this.qty,
          hargaSatuan: hargaSatuan ?? this.hargaSatuan);
}

/// Keranjang belanja — draf lokal per perangkat (tidak disinkronkan).
/// Qty dibatasi stok produk (tak bisa melebihi).
class CartNotifier extends StateNotifier<List<CartLine>> {
  CartNotifier() : super(const []);

  /// Tambah 1 pcs. Mengembalikan false bila stok habis/tercapai.
  /// [harga]: harga satuan override (mis. harga promo); disimpan di baris.
  bool add(Product product, {int? harga}) {
    if (product.stock <= 0) return false;
    final i = state.indexWhere((e) => e.product.id == product.id);
    if (i < 0) {
      state = [
        ...state,
        CartLine(product: product, qty: 1, hargaSatuan: harga)
      ];
      return true;
    }
    final line = state[i];
    if (line.qty >= product.stock) return false;
    state = [
      ...state.sublist(0, i),
      line.copyWith(qty: line.qty + 1, product: product),
      ...state.sublist(i + 1),
    ];
    return true;
  }

  /// Atur qty langsung (0 = hapus baris). Dibatasi stok.
  /// Penjualan satuan bulat (selaras PWA: stepper kasir ±1) —
  /// stok desimal 3,75 → maksimal 3 satuan.
  void setQty(String productId, int qty) {
    final i = state.indexWhere((e) => e.product.id == productId);
    if (i < 0) return;
    final line = state[i];
    final capped = qty.clamp(0, line.product.stock.floor());
    if (capped <= 0) {
      state = [...state.sublist(0, i), ...state.sublist(i + 1)];
    } else {
      state = [
        ...state.sublist(0, i),
        line.copyWith(qty: capped),
        ...state.sublist(i + 1),
      ];
    }
  }

  void remove(String productId) => setQty(productId, 0);

  void clear() => state = const [];

  int get totalQty => state.fold(0, (s, e) => s + e.qty);

  int get total => state.fold(0, (s, e) => s + e.subtotal);
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartLine>>((ref) {
  return CartNotifier();
});
