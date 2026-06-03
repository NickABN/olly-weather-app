import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/features/auth/domain/app_user.dart';
import 'package:weather_app/features/auth/data/auth_repository.dart';
import 'package:weather_app/features/auth/data/in_memory_auth_repository.dart';

/// The whole app depends on the [AuthRepository] interface, never on a
/// concrete class. Swapping to a real backend (e.g. Supabase) is a one-line
/// change here — return a `SupabaseAuthRepository()` that implements the same
/// interface. The UI and controllers stay untouched.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return InMemoryAuthRepository();
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});
