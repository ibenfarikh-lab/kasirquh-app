import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasirquh_app/data/models/titip_request.dart';

/// Domain B — Titip Belanja terstruktur.
void main() {
  test('TitipRequest.fromDoc: mapping skema PWA', () {
    final t = TitipRequest.fromDoc('abc', {
      'customerId': 'u1',
      'customerName': 'Mimi',
      'item': 'Susu bayi 400 g',
      'note': 'Merek X',
      'method': 'Diantar ke rumah',
      'status': 'baru',
      'createdAt': Timestamp.fromDate(DateTime(2026, 10, 8, 10, 30)),
    });
    expect(t.id, 'abc');
    expect(t.customerId, 'u1');
    expect(t.customerName, 'Mimi');
    expect(t.item, 'Susu bayi 400 g');
    expect(t.note, 'Merek X');
    expect(t.method, 'Diantar ke rumah');
    expect(t.status, 'baru');
    expect(t.createdAt, DateTime(2026, 10, 8, 10, 30));
  });

  test('TitipRequest.fromDoc: default aman bila field kosong', () {
    final t = TitipRequest.fromDoc('x', {});
    expect(t.customerName, 'Pelanggan');
    expect(t.status, 'baru');
    expect(t.item, '');
  });

  test('Filter inbox: hanya status baru yang tampil', () {
    final semua = [
      TitipRequest(
          id: '1',
          customerId: 'u1',
          customerName: 'A',
          item: 'Tepung',
          note: '',
          method: 'Ambil di warung',
          status: 'baru',
          createdAt: DateTime(2026, 10, 8)),
      TitipRequest(
          id: '2',
          customerId: 'u2',
          customerName: 'B',
          item: 'Gula',
          note: '',
          method: 'Ambil di warung',
          status: 'selesai',
          createdAt: DateTime(2026, 10, 7)),
    ];
    final baru = semua.where((t) => t.status == 'baru').toList();
    expect(baru.length, 1);
    expect(baru.first.item, 'Tepung');
  });
}
