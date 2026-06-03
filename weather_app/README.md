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

## Optional: Supabase Auth

To swap the in-memory auth for Supabase, run with:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

> **Note:** `SupabaseAuthRepository` is scaffolded but not wired to the Supabase SDK in this delivery (no `supabase_flutter` dependency). The interface and provider swap are ready — adding the dependency and the implementation is the only step needed.

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
