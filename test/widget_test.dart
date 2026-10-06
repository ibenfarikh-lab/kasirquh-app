import 'package:flutter_test/flutter_test.dart';
import 'package:kasirquh_app/core/utils/currency.dart';

void main() {
  test('formatRp memformat integer tanpa desimal', () {
    expect(formatRp(25500), 'Rp25.500');
    expect(formatRp(0), 'Rp0');
    expect(formatRp(1000000), 'Rp1.000.000');
  });
}
