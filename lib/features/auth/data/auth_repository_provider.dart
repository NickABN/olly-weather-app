import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../domain/app_user.dart';
import 'auth_repository.dart';
import 'in_memory_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ApiConstants.hasSupabaseConfig) {
    // SupabaseAuthRepository goes here when deploying with Supabase vars.
    // Fallback to in-memory so the app always runs without configuration.
  }
  return InMemoryAuthRepository();
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});
