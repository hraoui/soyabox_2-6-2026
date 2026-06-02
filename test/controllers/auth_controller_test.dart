import 'package:caisse_1/controllers/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthController.extractAuthTokenFromApiBody', () {
    test('returns token from top-level token key', () {
      final token = AuthController.extractAuthTokenFromApiBody({
        'token': 'top-level-token',
      });

      expect(token, 'top-level-token');
    });

    test('returns token from top-level access_token key', () {
      final token = AuthController.extractAuthTokenFromApiBody({
        'access_token': 'access-token',
      });

      expect(token, 'access-token');
    });

    test('returns token from nested data map', () {
      final token = AuthController.extractAuthTokenFromApiBody({
        'success': true,
        'data': {'access_token': 'nested-token'},
      });

      expect(token, 'nested-token');
    });

    test('returns empty string when body has no token', () {
      final token = AuthController.extractAuthTokenFromApiBody({
        'success': true,
      });

      expect(token, isEmpty);
    });
  });

  group('AuthController.extractAuthUserFromApiBody', () {
    test('returns user from top-level user key', () {
      final user = AuthController.extractAuthUserFromApiBody({
        'user': {'id': 6, 'email': 'staff@example.com', 'role': 'staff'},
      });

      expect(user['id'], 6);
      expect(user['email'], 'staff@example.com');
      expect(user['role'], 'staff');
    });

    test('returns nested user from data.user key', () {
      final user = AuthController.extractAuthUserFromApiBody({
        'success': true,
        'data': {
          'user': {'id': 7, 'email': 'admin@example.com', 'role': 'admin'},
        },
      });

      expect(user['id'], 7);
      expect(user['email'], 'admin@example.com');
      expect(user['role'], 'admin');
    });

    test('returns direct data payload when it looks like a user', () {
      final user = AuthController.extractAuthUserFromApiBody({
        'success': true,
        'data': {'id': 8, 'phone': '0600000000', 'role': 'staff'},
      });

      expect(user['id'], 8);
      expect(user['phone'], '0600000000');
      expect(user['role'], 'staff');
    });

    test('returns empty map when body has no user payload', () {
      final user = AuthController.extractAuthUserFromApiBody({'success': true});

      expect(user, isEmpty);
    });
  });
}
