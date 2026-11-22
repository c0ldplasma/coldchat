import 'package:coldchat/tools/megabytes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one decimal below 10 MB, whole numbers above', () {
    expect(megabytes(0, 'en'), '0');
    expect(megabytes(2345678, 'en'), '2.3');
    expect(megabytes(9940000, 'en'), '9.9');
    expect(megabytes(48400000, 'en'), '48');
    expect(megabytes(300000000, 'en'), '300');
  });

  test("uses the language's decimal separator", () {
    expect(megabytes(2345678, 'de'), '2,3');
  });
}
