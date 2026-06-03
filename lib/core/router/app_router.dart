import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:weather_app/features/auth/domain/app_user.dart';
import 'package:weather_app/features/auth/presentation/login_screen.dart';
import 'package:weather_app/features/auth/presentation/register_screen.dart';
import 'package:weather_app/features/weather/presentation/weather_screen.dart';
import 'package:weather_app/features/auth/data/auth_repository_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Puente: auth state → Listenable que GoRouter escucha sin recrearse.
  final authNotifier = ValueNotifier<AsyncValue<AppUser?>>(const AsyncLoading());
  ref.listen(authStateProvider, (_, next) => authNotifier.value = next,
      fireImmediately: true);
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation: '/weather',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final auth = authNotifier.value;
      // Mientras el stream no emitió aún, no redirigir (evita bounce inicial).
      if (auth.isLoading) return null;

      final isLoggedIn = auth.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/weather';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/weather', builder: (c, s) => const WeatherScreen()),
    ],
  );
});
