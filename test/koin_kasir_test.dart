import 'package:flutter_test/flutter_test.dart';


int koinMaksimal({
  required int saldo,
  required int total,
  required int redeemLimit,
  required bool enabled,
}) {
  if (!enabled || saldo <= 0) return 0;
  final maksimal = (total * redeemLimit ~/ 100);
  return saldo < maksimal ? saldo : maksimal;
}

int koinDidapat({
  required int total,
  required int spendRule,
  required int spendReward,
  required bool enabled,
}) {
  if (!enabled || total <= 0) return 0;
  return (total ~/ spendRule) * spendReward;
}

void main() {
  group('Opsi B — penukaran koin di kasir', () {
    test('maksimal = min(saldo, 50% total)', () {
      expect(
          koinMaksimal(
              saldo: 1000,
              total: 10000,
              redeemLimit: 50,
              enabled: true),
          equals(1000));
      expect(
          koinMaksimal(
              saldo: 10000,
              total: 10000,
              redeemLimit: 50,
              enabled: true),
          equals(5000));
    });

    test('saldo 0 → tidak bisa pakai', () {
      expect(
          koinMaksimal(
              saldo: 0, total: 10000, redeemLimit: 50, enabled: true),
          equals(0));
    });

    test('program mati → tidak bisa pakai', () {
      expect(
          koinMaksimal(
              saldo: 1000,
              total: 10000,
              redeemLimit: 50,
              enabled: false),
          equals(0));
    });

    test('1 koin = Rp1 potongan', () {
      const coinRate = 1;
      const koinDipakai = 500;
      expect(koinDipakai * coinRate, equals(500));
    });
  });

  group('Opsi B — perolehan koin di kasir', () {
    test('default: Rp100 → 1 koin', () {
      expect(
          koinDidapat(
              total: 10000,
              spendRule: 100,
              spendReward: 1,
              enabled: true),
          equals(100));
    });

    test('total kecil → 0 koin', () {
      expect(
          koinDidapat(
              total: 50,
              spendRule: 100,
              spendReward: 1,
              enabled: true),
          equals(0));
    });

    test('program mati → 0 koin', () {
      expect(
          koinDidapat(
              total: 10000,
              spendRule: 100,
              spendReward: 1,
              enabled: false),
          equals(0));
    });
  });
}
