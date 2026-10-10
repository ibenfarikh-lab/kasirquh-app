import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/product.dart';

/// Satuan berat (timbangan) — qty desimal, stepper 0,1 (selaras PWA).
bool isWeightUnit(String unit) =>
    const ['kg', 'ons', 'gram'].contains(unit);

/// Satu baris keranjang. Qty desimal (selaras PWA ?v=20261012v):
/// produk timbangan (kg/ons/gram) memakai kelipatan 0,1, sisanya bulat.
class CartLine {
  final Product product;
  final double qty;
  final int? hargaSatuan; // override harga (mis. harga promo saat ditambah)

  const CartLine({required this.product, required this.qty, this.hargaSatuan});

  int get harga => hargaSatuan ?? product.price;

  /// Subtotal: harga proporsional, dibulatkan (Rp16.000/kg × 0,2 = Rp3.200).
  int get subtotal => (harga * qty).round();

  CartLine copyWith({Product? product, double? qty, int? hargaSatuan}) =>
      CartLine(
          product: product ?? this.product,
          qty: qty ?? this.qty,
          hargaSatuan: hargaSatuan ?? this.hargaSatuan);
}

/// Keranjang belanja — draf lokal per perangkat (tidak disinkronkan).
/// Qty dibatasi stok produk (tak bisa melebihi).
class CartNotifier extends StateNotifier<List<CartLine>> {
  CartNotifier() : super(const []);

  /// Tambah ke keranjang. [qty]: jumlah yang ditambah (default 1;
  /// produk timbangan dari detail memakai 0,5 dst.).
  /// Mengembalikan false bila stok habis/tercapai.
  /// [harga]: harga satuan override (mis. harga promo); disimpan di baris.
  bool add(Product product, {int? harga, double qty = 1}) {
    if (product.stock <= 0) return false;
    final tambah = qty <= 0 ? 1.0 : qty;
    final i = state.indexWhere((e) => e.product.id == product.id);
    if (i < 0) {
      if (tambah > product.stock) return false;
      state = [
        ...state,
        CartLine(product: product, qty: tambah, hargaSatuan: harga)
      ];
      return true;
    }
    final line = state[i];
    final baru = line.qty + tambah;
    if (baru > product.stock) return false;
    state = [
      ...state.sublist(0, i),
      line.copyWith(qty: baru, product: product),
      ...state.sublist(i + 1),
    ];
    return true;
  }

  /// Atur qty langsung (<= 0 = hapus baris). Dibatasi stok.
  void setQty(String productId, double qty) {
    final i = state.indexWhere((e) => e.product.id == productId);
    if (i < 0) return;
    final line = state[i];
    if (qty <= 0) {
      state = [...state.sublist(0, i), ...state.sublist(i + 1)];
      return;
    }
    final capped = qty.clamp(0.0, line.product.stock.toDouble());
    state = [
      ...state.sublist(0, i),
      line.copyWith(qty: capped),
      ...state.sublist(i + 1),
    ];
  }

  void clear() => state = const [];

  double get totalQty => state.fold(0.0, (s, e) => s + e.qty);

  int get total => state.fold(0, (s, e) => s + e.subtotal);
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartLine>>((ref) {
  return CartNotifier();
});

/// Menu belanja tersimpan — sesi ini saja (ala PWA: `S.savedMenu`).
/// Menyimpan salinan baris keranjang agar bisa dimuat ulang nanti.
final savedMenuProvider =
    StateProvider<List<CartLine>>((ref) => const []);
