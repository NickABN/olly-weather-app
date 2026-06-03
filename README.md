# Weather App

Flutter Web app with authentication and real-time weather via [Open-Meteo](https://open-meteo.com/).

## Requirements

- Flutter SDK (stable channel) with web enabled
- Chrome browser

```bash
flutter doctor
flutter config --enable-web
```

## Run

```bash
flutter run -d chrome
```

No API keys or environment variables needed. The app runs fully out of the box.

## Test Credentials (pre-seeded)

The in-memory store is empty on first run. Register any user via the Register screen — credentials persist across browser reloads thanks to `shared_preferences`.

**Quick test:**
1. Open the app → redirected to `/login`
2. Tap **"Don't have an account? Register"**
3. Register with any email + password (min 6 chars)
4. You're redirected to the weather screen automatically

## Swapping the auth backend

Auth is in-memory by design (no backend required for this exercise). The app
depends only on the `AuthRepository` interface, so moving to a real backend
(e.g. Supabase) is a single change in
[auth_repository_provider.dart](lib/features/auth/data/auth_repository_provider.dart):
implement `SupabaseAuthRepository implements AuthRepository` and return it
there. UI and controllers stay untouched. See [DECISIONS.md](DECISIONS.md) §4.

## Architecture

```
lib/
  main.dart                   # Entry point — ProviderScope + MaterialApp.router
  core/
    theme/                    # ThemeData
    constants/                # API endpoints, dart-define keys
    router/                   # go_router + auth redirect guard
  features/
    auth/
      data/                   # AuthRepository interface + InMemoryAuthRepository
      domain/                 # AppUser model
      presentation/           # AuthController, LoginScreen, RegisterScreen
    weather/
      data/                   # WeatherRepository, LocationService, WMO codes
      presentation/           # WeatherController, WeatherScreen
  shared/widgets/             # LoadingIndicator, ErrorView
```

See [DECISIONS.md](DECISIONS.md) for architecture and design decisions.
