import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/core/constants/api_constants.dart';
import 'package:weather_app/features/auth/domain/app_user.dart';
import 'package:weather_app/features/auth/data/auth_repository.dart';
import 'package:weather_app/features/auth/data/in_memory_auth_repository.dart';

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
