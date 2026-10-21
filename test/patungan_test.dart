import 'package:flutter_test/flutter_test.dart';
import 'package:kasirquh_app/data/models/patungan.dart';

void main() {
  group('PatunganParticipant.paymentStatus (seragam Web 2026-10-21)', () {
    test('nilai baru Web: menunggu bayar = belum lunas', () {
      final p = PatunganParticipant.fromMap(const {
        'customerId': 'u1',
        'name': 'Warga',
        'slots': 2,
        'paymentStatus': 'menunggu bayar',
        'paymentMethod': 'transfer',
      });
      expect(p.belumLunas, isTrue);
      expect(p.sudahLunas, isFalse);
      expect(p.paymentMethod, 'transfer');
    });

    test('nilai warisan Native lama: menunggu = tetap belum lunas', () {
      final p = PatunganParticipant.fromMap(const {
        'customerId': 'u1',
        'name': 'Warga',
        'slots': 1,
        'paymentStatus': 'menunggu',
      });
      expect(p.belumLunas, isTrue);
      expect(p.sudahLunas, isFalse);
    });

    test('lunas terbaca sudah lunas', () {
      final p = PatunganParticipant.fromMap(const {
        'customerId': 'u1',
        'paymentStatus': 'lunas',
      });
      expect(p.sudahLunas, isTrue);
      expect(p.belumLunas, isFalse);
    });

    test('tanpa field -> bawaan tulisan baru menunggu bayar', () {
      final p = PatunganParticipant.fromMap(const {'customerId': 'u1'});
      expect(p.paymentStatus, 'menunggu bayar');
      expect(p.belumLunas, isTrue);
    });

    test('konstruktor bawaan & toMap menulis nilai baru', () {
      final p = PatunganParticipant(
        customerId: 'u1',
        name: 'Warga',
        slots: 1,
        joinedAt: DateTime(2026, 10, 21),
      );
      expect(p.paymentStatus, 'menunggu bayar');
      expect(p.toMap()['paymentStatus'], 'menunggu bayar');
      expect(p.toMap()['paymentMethod'], 'tunai');
    });
  });
}
