import 'package:flutter_test/flutter_test.dart';
import 'package:kasirquh_app/core/utils/dering.dart';
import 'package:kasirquh_app/data/repositories/store_repository.dart';

void main() {
  group('modeDeringPelanggan', () {
    test('khas -> khas, hening -> hening, lain -> bawaan', () {
      expect(modeDeringPelanggan('khas'), ModeDering.khas);
      expect(modeDeringPelanggan('hening'), ModeDering.hening);
      expect(modeDeringPelanggan('bawaan'), ModeDering.bawaan);
      expect(modeDeringPelanggan(null), ModeDering.bawaan);
      expect(modeDeringPelanggan('acak'), ModeDering.bawaan);
    });
  });

  group('modeDeringAdmin (kosakata Web)', () {
    test('mimi -> khas, silent -> hening, system -> bawaan', () {
      expect(modeDeringAdmin('mimi'), ModeDering.khas);
      expect(modeDeringAdmin('silent'), ModeDering.hening);
      expect(modeDeringAdmin('system'), ModeDering.bawaan);
      expect(modeDeringAdmin(null), ModeDering.bawaan);
    });
  });

  group('idKanalDering', () {
    test('satu kanal per mode, khas & hening terpisah dari bawaan', () {
      expect(idKanalDering(ModeDering.bawaan), 'kasirquh');
      expect(idKanalDering(ModeDering.khas), 'kasirquh_khas');
      expect(idKanalDering(ModeDering.hening), 'kasirquh_hening');
    });
  });

  group('AdminSoundSettings.fromMap', () {
    test('dokumen live Web terbaca utuh', () {
      final s = AdminSoundSettings.fromMap(const {
        'order': 'mimi',
        'chat': 'mimi',
        'promo': 'mimi',
        'vibrate': true,
      });
      expect(s.order, 'mimi');
      expect(s.chat, 'mimi');
      expect(s.promo, 'mimi');
      expect(s.vibrate, isTrue);
      expect(modeDeringAdmin(s.order), ModeDering.khas);
    });

    test('nilai tak dikenal dinormalkan ke system; getar bawaan nyala', () {
      final s = AdminSoundSettings.fromMap(const {'order': 'aneh'});
      expect(s.order, 'system');
      expect(s.chat, 'system');
      expect(s.vibrate, isTrue);
    });

    test('tanpa field -> bawaan system & getar nyala', () {
      final s = AdminSoundSettings.fromMap(null);
      expect(s.order, 'system');
      expect(s.vibrate, isTrue);
    });

    test('vibrate false dihormati', () {
      final s = AdminSoundSettings.fromMap(const {'vibrate': false});
      expect(s.vibrate, isFalse);
    });
  });

  group('StoreInfo.fromMap membawa soundSettings', () {
    test('adminSoundSettings ikut terbaca', () {
      final info = StoreInfo.fromMap(const {
        'adminSoundSettings': {
          'order': 'silent',
          'chat': 'system',
          'promo': 'mimi',
          'vibrate': false,
        },
      });
      expect(info.soundSettings.order, 'silent');
      expect(info.soundSettings.promo, 'mimi');
      expect(info.soundSettings.vibrate, isFalse);
    });
  });
}
