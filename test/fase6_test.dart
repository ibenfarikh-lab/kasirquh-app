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

Order _order(String id, List<OrderItem> items,
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
        _order('o1', [
          const OrderItem(
              productId: 'p1', name: 'A', qty: 2, price: 1000),
          const OrderItem(
              productId: 'p2', name: 'B', qty: 5, price: 1000),
        ]),
        _order('o2', [
          const OrderItem(
              productId: 'p1', name: 'A', qty: 3, price: 1000),
        ]),
        _order('o3', [
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
        _order('o1', [
          for (var i = 0; i < 10; i++)
            OrderItem(
                productId: 'p$i',
                name: 'X',
                qty: 10 - i,
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
    test('peta capaian per misi', () {
      final p = misiProgress(selesaiCount: 3, kabarCount: 7);
      expect(p['belanja_pertama'], 3);
      expect(p['pelanggan_setia'], 3);
      expect(p['kabar_pertama'], 7);
      expect(p['tukang_cerita'], 7);
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
  });
}
