import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/screens/auth_form_validators.dart';

void main() {
  group('validateEmail', () {
    test('rejects empty', () => expect(validateEmail(''), isNotNull));
    test('rejects malformed', () {
      expect(validateEmail('joe'), isNotNull);
      expect(validateEmail('joe@'), isNotNull);
      expect(validateEmail('joe@x'), isNotNull);
    });
    test('accepts well-formed (trimmed)', () {
      expect(validateEmail('joe@example.com'), isNull);
      expect(validateEmail('  joe@example.com  '), isNull);
    });
  });

  group('validatePassword', () {
    test('rejects empty', () => expect(validatePassword(''), isNotNull));
    test(
      'rejects shorter than 6',
      () => expect(validatePassword('12345'), isNotNull),
    );
    test('accepts 6+', () => expect(validatePassword('123456'), isNull));
  });

  group('validatePasswordRepeat', () {
    test('rejects mismatch', () {
      expect(validatePasswordRepeat('abcdef', 'abcdeF'), isNotNull);
    });
    test('rejects too-short even when matching', () {
      expect(validatePasswordRepeat('123', '123'), isNotNull);
    });
    test('accepts matching valid', () {
      expect(validatePasswordRepeat('abcdef', 'abcdef'), isNull);
    });
  });
}
