import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/features/auth/data/in_memory_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Fresh, empty store for every test.
    SharedPreferences.setMockInitialValues({});
  });

  group('InMemoryAuthRepository', () {
    test('signUp then signIn with same credentials succeeds', () async {
      final repo = InMemoryAuthRepository();
      await repo.signUp(email: 'a@b.com', password: 'secret123');

      final user = await repo.signIn(email: 'a@b.com', password: 'secret123');
      expect(user.email, 'a@b.com');
    });

    test('signIn with wrong password throws', () async {
      final repo = InMemoryAuthRepository();
      await repo.signUp(email: 'a@b.com', password: 'secret123');

      expect(
        () => repo.signIn(email: 'a@b.com', password: 'wrong'),
        throwsA(isA<Exception>()),
      );
    });

    test('signIn with unknown email throws', () async {
      final repo = InMemoryAuthRepository();
      expect(
        () => repo.signIn(email: 'nope@b.com', password: 'whatever'),
        throwsA(isA<Exception>()),
      );
    });

    test('duplicate signUp throws', () async {
      final repo = InMemoryAuthRepository();
      await repo.signUp(email: 'a@b.com', password: 'secret123');

      expect(
        () => repo.signUp(email: 'a@b.com', password: 'other123'),
        throwsA(isA<Exception>()),
      );
    });

    test('password is never stored in plaintext', () async {
      final repo = InMemoryAuthRepository();
      await repo.signUp(email: 'a@b.com', password: 'secret123');

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('auth_store') ?? '';
      expect(raw.contains('secret123'), isFalse);
    });
  });
}
