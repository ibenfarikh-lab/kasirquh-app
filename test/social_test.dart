import 'package:flutter_test/flutter_test.dart';
import 'package:kasirquh_app/data/models/chat.dart';
import 'package:kasirquh_app/data/models/rumpi.dart';

void main() {
  group('waktuRelatif', () {
    final now = DateTime(2026, 10, 6, 12, 0, 0);
    test('baru saja (< 60 detik)', () {
      expect(
          waktuRelatif(now.subtract(const Duration(seconds: 30)),
              sekarang: now),
          'baru saja');
    });
    test('menit', () {
      expect(
          waktuRelatif(now.subtract(const Duration(minutes: 5)),
              sekarang: now),
          '5 mnt lalu');
    });
    test('jam', () {
      expect(
          waktuRelatif(now.subtract(const Duration(hours: 3)),
              sekarang: now),
          '3 jam lalu');
    });
    test('hari', () {
      expect(
          waktuRelatif(now.subtract(const Duration(days: 2)),
              sekarang: now),
          '2 hari lalu');
    });
    test('minggu', () {
      expect(
          waktuRelatif(now.subtract(const Duration(days: 14)),
              sekarang: now),
          '2 mgg lalu');
    });
    test('lebih dari sebulan → tanggal', () {
      expect(
          waktuRelatif(now.subtract(const Duration(days: 40)),
              sekarang: now),
          isNotEmpty);
    });
    test('masa depan → baru saja', () {
      expect(waktuRelatif(now.add(const Duration(minutes: 1)),
          sekarang: now), 'baru saja');
    });
  });

  group('labelAlasanKoin', () {
    test('semua alasan punya label Indonesia', () {
      for (final r in ['harian', 'belanja', 'tukar', 'koreksi_admin']) {
        expect(labelAlasanKoin(r), isNotEmpty);
      }
      expect(labelAlasanKoin('harian'), 'Koin harian');
      expect(labelAlasanKoin('belanja'), 'Bonus belanja');
      expect(labelAlasanKoin('tukar'), 'Penukaran koin');
      expect(labelAlasanKoin('koreksi_admin'), 'Penyesuaian admin');
    });
    test('alasan tak dikenal dikembalikan apa adanya', () {
      expect(labelAlasanKoin('promo_x'), 'promo_x');
      expect(labelAlasanKoin(''), 'Lainnya');
    });
  });

  group('RumpiPost.fromDoc', () {
    test('default aman untuk field kosong', () {
      final p = RumpiPost.fromDoc('a', {});
      expect(p.likeCount, 0);
      expect(p.isSeed, false);
      expect(p.text, '');
      expect(p.punyaFoto, false);
    });
    test('punyaFoto true bila imageUrl terisi', () {
      final p = RumpiPost.fromDoc('a', {'imageUrl': 'data:image/png;base64,x'});
      expect(p.punyaFoto, true);
    });
    test('toFirestore selalu isSeed=false & likeCount=0', () {
      final m = RumpiPost(
        id: '',
        authorId: 'u1',
        authorName: 'Budi',
        text: 'Halo',
        createdAt: DateTime(2026, 1, 1),
      ).toFirestore();
      // createdAt diisi server; pastikan field kunci ada.
      expect(m['isSeed'], false);
      expect(m['likeCount'], 0);
      expect(m['authorId'], 'u1');
      expect(m['text'], 'Halo');
      expect(m.containsKey('createdAt'), true);
    });
  });

  group('ChatThread.fromDoc', () {
    test('unreadCustomer terbaca (default 0)', () {
      final t = ChatThread.fromDoc('u1', {'unreadCustomer': 3});
      expect(t.unreadCustomer, 3);
      expect(t.unreadAdmin, 0);
      final t2 = ChatThread.fromDoc('u1', {});
      expect(t2.unreadCustomer, 0);
    });
  });
}
