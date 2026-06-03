import 'package:weather_app/features/auth/domain/app_user.dart';

abstract interface class AuthRepository {
  Future<AppUser> signUp({required String email, required String password});
  Future<AppUser> signIn({required String email, required String password});
  Future<void> signOut();
  Stream<AppUser?> authStateChanges();
}
