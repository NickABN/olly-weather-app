import 'dart:async';
import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/features/auth/domain/app_user.dart';
import 'package:weather_app/features/auth/data/auth_repository.dart';

class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository() {
    _loadFromPrefs();
  }

  static const _prefsKey = 'auth_store';

  final Map<String, String> _store = {};
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  // Pre-seeded demo account so evaluators can log in without registering.
  static const _demoEmail = 'demo@demo.com';
  static const _demoPassword = 'demo1234';

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      final map = Map<String, String>.from(jsonDecode(raw) as Map);
      _store.addAll(map);
    }
    if (!_store.containsKey(_demoEmail)) {
      _store[_demoEmail] = BCrypt.hashpw(_demoPassword, BCrypt.gensalt());
      await _persist();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_store));
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    if (_store.containsKey(email)) {
      throw Exception('Email already registered');
    }
    // In production, client sends plaintext over TLS and server hashes with Argon2id.
    // Here we hash client-side only to avoid storing plaintext in this demo store.
    final hash = BCrypt.hashpw(password, BCrypt.gensalt());
    _store[email] = hash;
    await _persist();

    final user = AppUser(id: email, email: email);
    _current = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final hash = _store[email];
    if (hash == null || !BCrypt.checkpw(password, hash)) {
      throw Exception('Invalid email or password');
    }
    final user = AppUser(id: email, email: email);
    _current = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }
}
