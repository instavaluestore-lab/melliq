import 'package:flutter_test/flutter_test.dart';
import 'package:lupinusbuild/features/auth/validation/auth_validation.dart';

void main() {
  group('validateAccountEmail', () {
    test('rejects null, empty, and whitespace-only values', () {
      expect(validateAccountEmail(null), 'Enter your email address');
      expect(validateAccountEmail(''), 'Enter your email address');
      expect(validateAccountEmail('   '), 'Enter your email address');
    });

    test('rejects an address without an at sign', () {
      expect(
        validateAccountEmail('support.maxshade.com'),
        'Enter a valid email address',
      );
    });

    test('accepts and trims a valid account email', () {
      expect(validateAccountEmail(' support@maxshade.com '), isNull);
    });
  });

  group('validateNewPassword', () {
    test('rejects passwords shorter than eight characters', () {
      expect(validateNewPassword(null), 'Use at least 8 characters');
      expect(validateNewPassword('1234567'), 'Use at least 8 characters');
    });

    test('accepts passwords with at least eight characters', () {
      expect(validateNewPassword('12345678'), isNull);
      expect(validateNewPassword('a secure password'), isNull);
    });
  });

  group('validatePasswordConfirmation', () {
    test('rejects a mismatched confirmation', () {
      expect(
        validatePasswordConfirmation(
          value: 'different',
          password: 'correct-password',
        ),
        'Passwords do not match',
      );
    });

    test('accepts an exact confirmation match', () {
      expect(
        validatePasswordConfirmation(
          value: 'correct-password',
          password: 'correct-password',
        ),
        isNull,
      );
    });
  });

  group('authentication callback parsing', () {
    test('detects a non-empty PKCE authorization code', () {
      expect(
        hasAuthCodeCallback(Uri.parse('http://localhost:3000/?code=test-code')),
        isTrue,
      );
    });

    test('rejects missing and empty PKCE codes', () {
      expect(hasAuthCodeCallback(Uri.parse('http://localhost:3000/')), isFalse);
      expect(
        hasAuthCodeCallback(Uri.parse('http://localhost:3000/?code=')),
        isFalse,
      );
    });

    test('reads and decodes an authentication error', () {
      expect(
        readAuthCallbackError(
          Uri.parse(
            'http://localhost:3000/'
            '?error=access_denied'
            '&error_description=Email+link+is+invalid+or+has+expired',
          ),
        ),
        'Email link is invalid or has expired',
      );
    });

    test('returns null when no callback error exists', () {
      expect(
        readAuthCallbackError(Uri.parse('http://localhost:3000/')),
        isNull,
      );
    });

    test('recognizes only the password recovery redirect type', () {
      expect(isPasswordRecoveryRedirectType('passwordRecovery'), isTrue);
      expect(isPasswordRecoveryRedirectType('signedIn'), isFalse);
      expect(isPasswordRecoveryRedirectType(null), isFalse);
    });
  });
}
