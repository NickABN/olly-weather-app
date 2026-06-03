# Architecture & Design Decisions

## 1. Weather API — Open-Meteo

**Chosen:** [Open-Meteo](https://open-meteo.com/) — free, no API key.

**Why:** No registration or key to leak in a public repo, native CORS for Flutter Web (no proxy), and the evaluator can clone and run with zero config. Tradeoff: it returns WMO weather codes, not human strings, so a local mapping table (`wmo_codes.dart`) is needed. Data is CC BY 4.0; attribution is shown in the UI.

## 2. Security Decision — Password Hashing + In-Memory Session

**Chosen:** bcrypt (salted, adaptive) for stored credentials; session kept in memory only.

**Why password hashing:** Passwords must never be stored in plaintext, even in a demo. The store persists to `shared_preferences`, so only the bcrypt hash survives reloads — never the password.

**Why in-memory session:** No token is written to `localStorage`. A page reload requires re-login. That's a deliberate trade — it removes an XSS-stealable session at the cost of convenience.

**Honest caveats — this is a demo artifact:** In production the client sends the password over TLS and the *server* hashes it (OWASP #1: Argon2id); client-side hashing only makes sense here because there is no server. Likewise, truly secure client storage doesn't exist on web (`flutter_secure_storage` falls back to `localStorage`/`IndexedDB`) — the production answer is to keep sensitive state server-side.

## 3. Tradeoff — Cache vs. Freshness

**Chosen:** Cache-first with background refresh (stale-while-revalidate). On load, the last weather snapshot renders immediately from `shared_preferences` while a fresh fetch updates the UI when it arrives — the user never stares at a spinner.

**Give up:** Displayed data can be a few minutes stale until the refresh lands.

**With more time:** Show a "last updated" timestamp and a TTL that invalidates the cache after N minutes, so freshness is explicit.

## 4. Auth in Production

The app depends on the `AuthRepository` interface, not on any concrete class — so the production swap is one line in `auth_repository_provider.dart`: return a `SupabaseAuthRepository` instead of the in-memory one. UI and controllers don't change. In that setup:

- **Transport:** password over TLS to the auth endpoint.
- **Server hashing:** bcrypt server-side (Argon2id is the stronger, OWASP-recommended choice for new systems).
- **Session:** JWT in an `HttpOnly` cookie (web) or secure keychain (mobile), with refresh + expiry.

## 5. Stack (one-liners)

Flutter Web (one codebase, web + mobile web) · Riverpod (compile-safe providers, `AsyncValue` for loading/error/data) · go_router (declarative routing + auth redirect guard) · `http` over dio (one REST call, no interceptors needed) · `shared_preferences` (light persistence, no SQLite overhead).
