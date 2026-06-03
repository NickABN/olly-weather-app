# Architecture & Design Decisions

## 1. Weather API — Open-Meteo

**Chosen:** [Open-Meteo](https://open-meteo.com/) (free, no API key required)

**Why:** No registration, no API key to manage or leak in a public repo, native CORS support for Flutter Web (no proxy needed), and the evaluator can clone and run without any configuration. Tradeoff: returns WMO weather codes instead of human-readable strings, so a local mapping table (`wmo_codes.dart`) is required.

**Attribution:** Open-Meteo data is licensed CC BY 4.0. Attribution is shown in the weather screen UI.

---

## 2. Security Decision — Password Hashing

**Chosen:** bcrypt (pure-Dart, web-safe) in the in-memory store.

**Why:** Passwords must never be stored in plaintext — even in a demo. The in-memory store persists to `shared_preferences` so hashed values survive page reloads. bcrypt is salted and adaptive, satisfying the core security principle without requiring a backend.

**Important caveat — this is a demo artifact:** In production, the client sends the password in plaintext over TLS and the *server* hashes it using **Argon2id** (OWASP recommendation #1). Client-side hashing only makes sense here because there is no server.

**Web-specific note:** `flutter_secure_storage` on web falls back to `localStorage`/`IndexedDB`, which is not truly secure. The honest production choice for web would defer all sensitive state to the server.

---

## 3. Tradeoff — Cache vs. Freshness

**Chosen:** Cache-first with background refresh (stale-while-revalidate).

**Trade:** On load, the last known weather data is shown immediately from `shared_preferences`. A background fetch updates the UI once the new data arrives. The user always sees something rather than a loading spinner.

**What we give up:** The displayed data may be a few minutes stale until the background refresh completes.

**With more time:** Show a "last updated" timestamp and invalidate the cache after N minutes (TTL), so the user knows how fresh the data is.

---

## 4. Auth in Production

In a real product backed by Supabase:

- **Transport:** password sent over TLS to Supabase Auth endpoint.
- **Server hashing:** Supabase Auth uses bcrypt server-side (Argon2id is the stronger choice and what OWASP recommends for new systems).
- **Session:** JWT issued by Supabase, stored in a `HttpOnly` cookie (web) or secure keychain (mobile).
- **The swap:** Replace `InMemoryAuthRepository` with `SupabaseAuthRepository` by passing `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` at build time. The UI and controllers are unchanged — they depend on the `AuthRepository` interface, not the implementation.

---

## 5. Stack Rationale

| Choice | Reason |
|--------|--------|
| Flutter Web | Single codebase covering both web and mobile web; responsive out of the box |
| Riverpod | Compile-safe providers, no `BuildContext` dependency in business logic, easy `AsyncValue` for loading/error/data |
| go_router | Declarative routing, redirect guard for auth, deep-link ready |
| http (not dio) | Sufficient for a single REST call; dio would be over-engineering without interceptors needed |
| shared_preferences | Lightweight persistence for auth store and weather cache; no SQLite overhead needed |
