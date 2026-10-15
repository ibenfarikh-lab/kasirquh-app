import 'package:flutter_test/flutter_test.dart';
import 'package:kasirquh_app/data/models/customer.dart';

void main() {
  group('memberCodeFromUid — format identik PWA', () {
    test('UID normal → KQ- + 8 karakter pertama uppercase', () {
      expect(memberCodeFromUid('abc123def456'),
          equals('KQ-ABC123DE'));
    });

    test('UID Firebase asli (28 karakter alfanumerik)', () {
      expect(memberCodeFromUid('XyZ9AbC2dEfGhIjKlMnOpQrStUv'),
          equals('KQ-XYZ9ABC2'));
    });

    test('UID pendek → pad dengan 0', () {
      expect(memberCodeFromUid('ab12'), equals('KQ-AB120000'));
    });

    test('deterministik — UID sama selalu hasil sama', () {
      const uid = 'testUid123456789';
      expect(memberCodeFromUid(uid),
          equals(memberCodeFromUid(uid)));
    });

    test('prefix KQ- selalu ada', () {
      expect(memberCodeFromUid('anything123'),
          startsWith('KQ-'));
    });
  });

  group('Customer.kodeMember', () {
    test('pakai field DB jika ada', () {
      final c = Customer(
        uid: 'abc123def456',
        name: 'Budi',
        email: 'budi@x.id',
        approvalStatus: 'approved',
        memberCode: 'KQ-CUSTOM01',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(c.kodeMember, equals('KQ-CUSTOM01'));
    });

    test('fallback hitung dari UID jika field kosong', () {
      final c = Customer(
        uid: 'abc123def456',
        name: 'Budi',
        email: 'budi@x.id',
        approvalStatus: 'approved',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(c.kodeMember, equals('KQ-ABC123DE'));
    });
  });
}
