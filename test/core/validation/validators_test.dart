import 'package:flutter_test/flutter_test.dart';
import 'package:dirassty/core/validation/validators.dart';

void main() {
  group('isValidPin', () {
    test('accepts exactly 4 digits', () => expect(isValidPin('1234'), isTrue));
    test('rejects fewer than 4 digits',
        () => expect(isValidPin('123'), isFalse));
    test('rejects more than 4 digits',
        () => expect(isValidPin('12345'), isFalse));
    test('rejects non-digit characters',
        () => expect(isValidPin('12ab'), isFalse));
  });

  group('isValidUsername', () {
    test('accepts letters, digits, underscore, 3-20 chars', () {
      expect(isValidUsername('ali_2010'), isTrue);
    });
    test('rejects under 3 characters',
        () => expect(isValidUsername('ab'), isFalse));
    test('rejects over 20 characters',
        () => expect(isValidUsername('a' * 21), isFalse));
    test('rejects spaces and symbols',
        () => expect(isValidUsername('ali 2010!'), isFalse));
  });

  group('isValidPhone', () {
    test('accepts 8+ digit strings',
        () => expect(isValidPhone('12345678'), isTrue));
    test('rejects under 8 characters',
        () => expect(isValidPhone('1234567'), isFalse));
  });
}
