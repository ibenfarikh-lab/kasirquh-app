import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasirquh_app/core/theme/theme_settings.dart';
import 'package:kasirquh_app/core/widgets/product_photo.dart';
import 'package:kasirquh_app/data/models/customer_note.dart';
import 'package:kasirquh_app/data/models/order.dart';
import 'package:kasirquh_app/features/admin/menu/ai_admin_sheet.dart'
    show hasilkanSaran;
import 'package:kasirquh_app/features/customer/account/misi_koin_page.dart'
    show misiProgress;
import 'package:kasirquh_app/features/customer/account/tebak_harga_page.dart'
    show buatPengecoh;

Order buatOrder(String id, List<OrderItem> items,
    {OrderStatus status = OrderStatus.selesai}) {
  return Order(
    id: id,
    customerId: 'c1',
    customerName: 'Tes',
    code: id,
    items: items,
    total: 0,
    status: status,
    payment: 'cod',
    createdAt: DateTime(2026, 10, 6),
  );
}

CustomerNote _note(String type, int amount) => CustomerNote(
      id: '$type$amount',
      customerId: 'c1',
      type: type,
      amount: amount,
      note: '',
      createdAt: DateTime(2026, 10, 6),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('topProductsByQty', () {
    test('urut terbanyak, batal tidak dihitung', () {
      final orders = [
        buatOrder('o1', [
          const OrderItem(
              productId: 'p1', name: 'A', qty: 2, price: 1000),
          const OrderItem(
              productId: 'p2', name: 'B', qty: 5, price: 1000),
        ]),
        buatOrder('o2', [
          const OrderItem(
              productId: 'p1', name: 'A', qty: 3, price: 1000),
        ]),
        buatOrder('o3', [
          const OrderItem(
              productId: 'p3', name: 'C', qty: 99, price: 1000),
        ], status: OrderStatus.dibatalkan),
      ];
      final top = topProductsByQty(orders);
      expect(top, ['p1', 'p2']);
    });

    test('kosong bila tanpa pesanan', () {
      expect(topProductsByQty([]), isEmpty);
    });

    test('limit dihormati', () {
      final orders = [
        buatOrder('o1', [
          for (var i = 0; i < 10; i++)
            OrderItem(
                productId: 'p$i',
                name: 'X',
                qty: (10 - i).toDouble(),
                price: 1000),
        ]),
      ];
      expect(topProductsByQty(orders, limit: 3).length, 3);
    });
  });

  group('totalTagihan', () {
    test('tagihan dikurangi pembayaran', () {
      final notes = [
        _note('tagihan', 50000),
        _note('tagihan', 25000),
        _note('pembayaran', 30000),
        _note('catatan', 0),
      ];
      expect(totalTagihan(notes), 45000);
    });

    test('kosong = 0', () {
      expect(totalTagihan([]), 0);
    });
  });

  group('hasilkanSaran', () {
    test('tanpa data → saran ajakan jualan', () {
      final saran = hasilkanSaran(
        omzetHariIni: 0,
        transaksiHariIni: 0,
        pesananMenunggu: 0,
        stokMenipis: const [],
        produkLaris: const [],
      );
      expect(saran, isNotEmpty);
      expect(
          saran.any((s) => s.teks.contains('Belum ada transaksi')),
          isTrue);
    });

    test('stok menipis & pesanan menunggu muncul', () {
      final saran = hasilkanSaran(
        omzetHariIni: 100000,
        transaksiHariIni: 5,
        pesananMenunggu: 2,
        stokMenipis: const ['Gula', 'Minyak', 'Telur', 'Beras'],
        produkLaris: const ['Indomie'],
      );
      final teks = saran.map((s) => s.teks).join(' ');
      expect(teks.contains('2 pesanan menunggu'), isTrue);
      expect(teks.contains('Stok menipis'), isTrue);
      expect(teks.contains('+1 lainnya'), isTrue);
      expect(teks.contains('Paling laris: Indomie'), isTrue);
    });
  });

  group('misiProgress', () {
    Order buatOrderMisi(String id, DateTime t, List<String> productIds) => Order(
          id: id,
          customerId: 'u1',
          customerName: 'T',
          code: id,
          items: [
            for (final pid in productIds)
              OrderItem(
                  productId: pid, name: pid, qty: 1, price: 1000),
          ],
          total: 1000,
          status: OrderStatus.selesai,
          payment: 'cod',
          createdAt: t,
        );

    test('belanja_3x_minggu: hitung pesanan 7 hari terakhir', () {
      final now = DateTime.now();
      final orders = [
        buatOrderMisi('a', now.subtract(const Duration(days: 1)), ['p1']),
        buatOrderMisi('b', now.subtract(const Duration(days: 3)), ['p1']),
        buatOrderMisi('c', now.subtract(const Duration(days: 10)), ['p1']),
      ];
      final p = misiProgress(orders);
      expect(p['belanja_3x_minggu'], 2);
    });

    test('coba_produk_baru: pesanan terbaru ada produk baru', () {
      final now = DateTime.now();
      final orders = [
        buatOrderMisi('lama', now.subtract(const Duration(days: 5)), ['p1']),
        buatOrderMisi('baru', now.subtract(const Duration(days: 1)), ['p1', 'p2']),
      ];
      expect(misiProgress(orders)['coba_produk_baru'], 1);
    });

    test('coba_produk_baru: tanpa produk baru = 0', () {
      final now = DateTime.now();
      final orders = [
        buatOrderMisi('lama', now.subtract(const Duration(days: 5)), ['p1']),
        buatOrderMisi('baru', now.subtract(const Duration(days: 1)), ['p1']),
      ];
      expect(misiProgress(orders)['coba_produk_baru'], 0);
    });

    test('tanpa pesanan: semua 0', () {
      final p = misiProgress([]);
      expect(p['belanja_3x_minggu'], 0);
      expect(p['coba_produk_baru'], 0);
    });
  });

  group('photoImageProvider', () {
    test('null/kosong → null', () {
      expect(photoImageProvider(null), isNull);
      expect(photoImageProvider(''), isNull);
      expect(photoImageProvider('bukan-foto'), isNull);
    });

    test('data URI valid → MemoryImage', () {
      // PNG 1x1 transparan.
      const uri =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
      final p = photoImageProvider(uri);
      expect(p, isNotNull);
    });

    test('URL http → NetworkImage', () {
      final p = photoImageProvider('https://contoh.id/foto.png');
      expect(p, isNotNull);
    });
  });

  group('TemaPilihan', () {
    test('fromString & label', () {
      expect(TemaPilihan.fromString('gelap'), TemaPilihan.gelap);
      expect(TemaPilihan.fromString('sistem'), TemaPilihan.sistem);
      expect(TemaPilihan.fromString(null), TemaPilihan.terang);
      expect(TemaPilihan.fromString('aneh'), TemaPilihan.terang);
      expect(TemaPilihan.terang.label, 'Terang');
      expect(TemaPilihan.gelap.label, 'Gelap');
      expect(TemaPilihan.sistem.label, 'Ikuti HP');
    });
  });

  group('resolveGelap', () {
    test('terang selalu false, gelap selalu true', () {
      expect(resolveGelap(TemaPilihan.terang, Brightness.dark), isFalse);
      expect(resolveGelap(TemaPilihan.terang, Brightness.light), isFalse);
      expect(resolveGelap(TemaPilihan.gelap, Brightness.dark), isTrue);
      expect(resolveGelap(TemaPilihan.gelap, Brightness.light), isTrue);
    });

    test('sistem mengikuti HP', () {
      expect(resolveGelap(TemaPilihan.sistem, Brightness.dark), isTrue);
      expect(resolveGelap(TemaPilihan.sistem, Brightness.light), isFalse);
    });
  });

  group('customerNoteTypeLabel', () {
    test('label jenis', () {
      expect(customerNoteTypeLabel('tagihan'), 'Tagihan');
      expect(customerNoteTypeLabel('pembayaran'), 'Pembayaran');
      expect(customerNoteTypeLabel('catatan'), 'Catatan');
      expect(customerNoteTypeLabel('aneh'), 'Catatan');
    });
  
  group('buatPengecoh', () {
    test('kelipatan 500, positif, beda dari harga asli', () {
      final rand = Random(42);
      for (final harga in [500, 1000, 3500, 7500, 12500, 50000]) {
        final p = buatPengecoh(harga, rand);
        expect(p.length, 2, reason: 'harga $harga');
        for (final x in p) {
          expect(x % 500, 0, reason: 'bukan kelipatan 500: $x');
          expect(x > 0, isTrue);
          expect(x != harga, isTrue, reason: 'sama dengan harga asli');
        }
      }
    });

    test('hasil acak tapi selalu valid (100x)', () {
      final rand = Random();
      for (var i = 0; i < 100; i++) {
        final harga = 500 + rand.nextInt(50) * 500;
        final p = buatPengecoh(harga, rand);
        expect(p.length, 2);
        expect(p.toSet().length, 2);
        for (final x in p) {
          expect(x % 500, 0);
          expect(x > 0, isTrue);
          expect(x != harga, isTrue);
        }
      }
    });
  });
});
}
