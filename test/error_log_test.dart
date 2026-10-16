import 'package:flutter_test/flutter_test.dart';
import 'package:kasirquh_app/core/utils/error_log.dart';

void main() {
  setUp(() => ErrorLog.clear());

  test('log menambah entry', () {
    ErrorLog.log('test', 'pesan error');
    expect(ErrorLog.entries.length, 1);
    expect(ErrorLog.entries.first.source, 'test');
    expect(ErrorLog.entries.first.message, 'pesan error');
  });

  test('maksimal 50 entry', () {
    for (var i = 0; i < 60; i++) {
      ErrorLog.log('test', 'error $i');
    }
    expect(ErrorLog.entries.length, 50);
    // Yang tersisa adalah 50 terakhir.
    expect(ErrorLog.entries.first.message, 'error 10');
    expect(ErrorLog.entries.last.message, 'error 59');
  });

  test('pesan dipotong 500 karakter', () {
    final panjang = 'x' * 600;
    ErrorLog.log('test', panjang);
    expect(ErrorLog.entries.first.message.length, 500);
  });

  test('clear mengosongkan', () {
    ErrorLog.log('test', 'pesan');
    ErrorLog.clear();
    expect(ErrorLog.entries.isEmpty, true);
  });

  test('error non-string di-toString', () {
    ErrorLog.log('test', Exception('boom'));
    expect(ErrorLog.entries.first.message.contains('boom'), true);
  });
}
