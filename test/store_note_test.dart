import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasirquh_app/data/models/store_note.dart';

/// Domain A: skema terkunci `store_memos` = title, body, createdAt.
void main() {
  test('fromDoc membaca title/body/createdAt dari Timestamp', () {
    final t = DateTime(2026, 10, 7, 10, 30);
    final n = StoreNote.fromDoc('abc', {
      'title': 'Kulak',
      'body': 'Beli gula',
      'createdAt': Timestamp.fromDate(t),
    });
    expect(n.id, 'abc');
    expect(n.title, 'Kulak');
    expect(n.body, 'Beli gula');
    expect(n.createdAt, t);
  });

  test('fromDoc default aman untuk field kosong (dok lama PWA)', () {
    final n = StoreNote.fromDoc('x', {'body': 'saja'});
    expect(n.title, '');
    expect(n.body, 'saja');
    expect(n.createdAt.millisecondsSinceEpoch, 0);
  });

  test('toFirestore menulis title/body/createdAt', () {
    final m = StoreNote(
      id: '',
      title: 'J',
      body: 'I',
      createdAt: DateTime(2026, 1, 1),
    ).toFirestore();
    expect(m['title'], 'J');
    expect(m['body'], 'I');
    expect(m.containsKey('createdAt'), true);
  });

  test('toFirestoreMigrasi mempertahankan createdAt asli', () {
    final t = DateTime(2025, 5, 5, 8, 0);
    final m = StoreNote(
      id: 'l1',
      title: 'Lama',
      body: 'Isi lama',
      createdAt: t,
    ).toFirestoreMigrasi();
    expect(m['title'], 'Lama');
    expect(m['createdAt'], isA<Timestamp>());
    expect((m['createdAt'] as Timestamp).toDate(), t);
  });

  test('fromMap/toMap SQLite tetap kompatibel (outbox lokal)', () {
    final t = DateTime(2026, 10, 7);
    final n = StoreNote.fromMap({
      'id': 'k1',
      'title': 'T',
      'body': 'B',
      'createdAt': t.millisecondsSinceEpoch,
    });
    expect(n.createdAt, t);
    final m = n.toMap();
    expect(m['id'], 'k1');
    expect(m['createdAt'], t.millisecondsSinceEpoch);
  });
}
