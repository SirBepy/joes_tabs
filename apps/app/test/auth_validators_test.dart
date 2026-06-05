import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/screens/auth_form_validators.dart';

void main() {
  group('validateEmail', () {
    test('rejects empty', () => expect(validateEmail(''), isNotNull));
    test('rejects null', () => expect(validateEmail(null), isNotNull));
    test('rejects whitespace-only', () {
      expect(validateEmail('   '), isNotNull);
    });
    test('rejects malformed', () {
      expect(validateEmail('joe'), isNotNull);
      expect(validateEmail('joe@'), isNotNull);
      expect(validateEmail('joe@x'), isNotNull);
      expect(validateEmail('@example.com'), isNotNull);
      expect(validateEmail('joe @example.com'), isNotNull);
      expect(validateEmail('joe@@example.com'), isNotNull);
      expect(validateEmail('joe@exam ple.com'), isNotNull);
    });
    test('accepts well-formed (trimmed)', () {
      expect(validateEmail('joe@example.com'), isNull);
      expect(validateEmail('  joe@example.com  '), isNull);
      expect(validateEmail('a.b+tag@sub.example.co.uk'), isNull);
    });
  });

  group('validatePassword', () {
    test('rejects empty', () => expect(validatePassword(''), isNotNull));
    test('rejects null', () => expect(validatePassword(null), isNotNull));
    test(
      'rejects shorter than 6',
      () => expect(validatePassword('12345'), isNotNull),
    );
    test('accepts exactly 6 (boundary)', () {
      expect(validatePassword('123456'), isNull);
    });
    test('a password is not trimmed: spaces count toward length', () {
      // Six spaces is a (silly but) valid 6-char password; the validator does
      // not trim, so this must pass.
      expect(validatePassword('      '), isNull);
    });
  });

  group('validatePasswordRepeat', () {
    test('rejects mismatch', () {
      expect(validatePasswordRepeat('abcdef', 'abcdeF'), isNotNull);
    });
    test('rejects too-short even when matching', () {
      expect(validatePasswordRepeat('123', '123'), isNotNull);
    });
    test('rejects null repeat', () {
      expect(validatePasswordRepeat(null, 'abcdef'), isNotNull);
    });
    test('password-rule error takes precedence over a mismatch error', () {
      // Repeat is too short AND differs from the original: the length error
      // wins (it is checked first), so the user sees the actionable message.
      final err = validatePasswordRepeat('12', 'abcdef');
      expect(err, contains('at least 6'));
    });
    test('whitespace-sensitive: a trailing space breaks the match', () {
      expect(validatePasswordRepeat('abcdef ', 'abcdef'), isNotNull);
    });
    test('accepts matching valid', () {
      expect(validatePasswordRepeat('abcdef', 'abcdef'), isNull);
    });
  });
}
