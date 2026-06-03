# PLAN — Weather App (Flutter Web + Mobile Web)

Plan de desarrollo para el take-home. Pensado para pasarse directo a desarrollo
(o a un agente de código). Los puntos marcados con ⏳ quedan pendientes de la
plática de decisiones y no deben precocinarse.

---

## Stack y decisiones base

- **Flutter Web** como target principal (corre responsive en navegadores móviles → cubre "mobile web").
- **State management:** Riverpod.
- **Navegación:** go_router con redirect guard de auth.
- **HTTP:** `http` (subir a `dio` solo si se necesitan interceptors).
- **Ubicación:** `geolocator` (soporta web vía browser API).
- **Persistencia ligera:** `shared_preferences`.

### Dependencias (`pubspec.yaml`)
- `flutter_riverpod`
- `go_router`
- `http`
- `geolocator`
- `shared_preferences`
- `bcrypt` (hash de passwords en el store en memoria)

### Estructura de carpetas (feature-first pragmática)
```
lib/
  main.dart
  core/
    theme/          # ThemeData propio (no el default morado)
    constants/      # endpoints, flags
    router/         # go_router + guard de auth
  features/
    auth/
      data/         # AuthRepository (interfaz) + implementaciones
      domain/       # modelo AppUser
      presentation/ # pantallas login/registro + AuthController
    weather/
      data/         # cliente API + modelo + servicio de ubicación
      presentation/ # pantalla weather + WeatherController
  shared/
    widgets/        # widgets reusables (loaders, botones, error views)
```

> Nota de criterio: estructura right-sized a propósito. Clean Architecture con
> 3 capas por feature sería over-engineering para un alcance de 4–8 h.

---

## Fase 0 — Setup
- Verificar entorno (`flutter doctor`, canal stable, `flutter config --enable-web`).
- `flutter create --platforms=web,android,ios --org com.tunombre weather_app`.
- Agregar dependencias y envolver `main.dart` en `ProviderScope`.

**Listo cuando:** corre en Chrome dentro de `ProviderScope` sin errores.

---

## Fase 1 — Core
- `core/theme/`: un `ThemeData` propio y simple.
- `core/router/`: go_router con rutas `/login`, `/register`, `/weather` y un
  **redirect guard** que manda a `/login` si no hay sesión.
- `core/constants/`: endpoints y lectura de config desde `--dart-define`
  (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).

**Listo cuando:** navegar a `/weather` sin sesión redirige a `/login`.

---

## Fase 2 — Auth (abstracción + registro)

El corazón del diseño: **una interfaz, dos implementaciones intercambiables**.
La UI y los controllers nunca saben qué hay detrás.

### Interfaz
```dart
abstract interface class AuthRepository {
  Future<AppUser> signUp({required String email, required String password});
  Future<AppUser> signIn({required String email, required String password});
  Future<void> signOut();
  Stream<AppUser?> authStateChanges();
}
```

### Implementación A — `InMemoryAuthRepository` (lo que se entrega)
- `Map<String, AppUser>` editable en runtime.
- `signUp`: valida que el email no exista y agrega el usuario.
- `signIn`: compara el password contra el hash guardado.
- **Passwords hasheados con `bcrypt`** (salted), nunca en texto plano. → conecta
  con la decisión de seguridad del assignment.
- **Persistencia con `shared_preferences`:** se respalda el `Map` (emails +
  hashes) para que los usuarios registrados sobrevivan a un reload del navegador.
  Sin esto, al ser web, el store se perdería en cada recarga.

### Implementación B — `SupabaseAuthRepository` (experimento local)
- Envuelve `supabase_flutter`, mapeando `signUp` / `signInWithPassword` /
  `signOut` / `onAuthStateChange` a la misma interfaz.
- No va en la entrega; sirve para probar en local y para sustentar la respuesta
  de "auth en producción".

### Swap por provider (config-driven, defaults seguros)
La selección **se deriva de la presencia de variables de entorno**, no de un
booleano hardcodeado. Sin config → corre out-of-the-box (in-memory + Open-Meteo);
con config → usa Supabase.
```dart
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  final hasSupabase = supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

  return hasSupabase
      ? SupabaseAuthRepository(Supabase.instance.client)
      : InMemoryAuthRepository();
});
```
- Entrega: sin variables → in-memory. El evaluador clona y corre sin configurar nada.
- Local: `flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
- El clima no entra en este fallback: Open-Meteo no usa key, es el default permanente.

### Presentation
- `AuthController` (`AsyncNotifier`) con estado `loading / authenticated / error`.
- Pantalla **Login**: form con validación, botón con loading, manejo de error.
- Pantalla **Registro**: form simple (email + password + confirmación), validación.
- El guard del router lee el provider de sesión.

✅ **Decisión de seguridad: hashing con `bcrypt` en el store en memoria.**
- Passwords nunca en texto plano; se guardan hasheados (bcrypt, salted/adaptativo,
  pure-Dart y web-safe) y `signIn` verifica contra el hash.
- **Insight central a documentar:** hashear en el cliente es un artefacto del demo.
  En producción el cliente *no* hashea — manda el password por TLS y el **servidor**
  lo hashea con **Argon2id** (recomendación #1 de OWASP). Aquí se hace en memoria
  solo para no almacenar texto plano y demostrar el principio.
- Matiz de web a mencionar: `flutter_secure_storage` en web cae a
  localStorage/IndexedDB y no es realmente seguro, así que la decisión honesta en
  web difiere de la de móvil nativo.
- Rationale de no usar Argon2id en el cliente: store efímero + en prod no debería
  vivir ahí. Se mantiene el cliente simple y se documenta el approach de producción.

**Listo cuando:** registro crea usuario que persiste tras reload; login válido
entra a weather; inválido muestra error.

---

## Fase 3 — Weather

✅ **API decidida: Open-Meteo.** Sin API key (nada que filtrar en repo público),
CORS nativo (funciona directo desde Flutter Web sin proxy), sin registro/tarjeta
(el evaluador clona y corre). Costo asumido: devuelve WMO weather codes numéricos
(hay que mapearlos a texto/icono) y la data es CC BY 4.0 (requiere atribución).

- Endpoint:
  `https://api.open-meteo.com/v1/forecast?latitude=LAT&longitude=LON&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m`
- Unidades en métrico/Celsius (default; coherente con MX).
- `weather/data/`:
  - Modelo `Weather` con `fromJson`.
  - `WeatherRepository` que recibe lat/lon y pega a Open-Meteo.
  - Mapeo de **WMO weather codes** → descripción + icono (un `switch`/`Map`).
  - Servicio de ubicación (`geolocator`): pide permiso, obtiene coords y
    **maneja permiso denegado** (fallback o mensaje claro, sin crashear).
- `weather/presentation/`:
  - `WeatherController` (`AsyncNotifier`) → usa `AsyncValue` para loading/data/error.
  - Pantalla con clima actual, refresh manual y pull-to-refresh.
  - Atribución a Open-Meteo (CC BY 4.0) visible en algún punto de la UI.

**Listo cuando:** tras login, pide ubicación y muestra clima real; permiso
denegado se maneja con gracia.

---

## Fase 4 — Tradeoff deliberado + pulido

✅ **Tradeoff: caché vs. frescura en el clima → se elige caché.**
- Se guarda la última respuesta de Open-Meteo (en `shared_preferences`).
- Al abrir la pantalla, **muestra el dato cacheado de inmediato** y refresca en
  segundo plano (patrón stale-while-revalidate).
- Se gana: percepción de velocidad y algo que mostrar sin red. Se cede: el dato
  puede estar unos minutos viejo hasta que llega el refresh.
- **Con más tiempo:** mostrar timestamp de "última actualización" e invalidar el
  caché tras N minutos (TTL).

- Responsive en viewport móvil.
- Estados de loading/error consistentes con widgets de `shared/`.

---

## Fase 5 — Entregables
- `DECISIONS.md` (máx 1 página): API elegida, decisión de seguridad, tradeoff +
  qué haría con más tiempo, y cómo implementaría auth en producción.
- `README.md`: cómo correr (`flutter run -d chrome`), credenciales de prueba
  (usuario semilla), y nota sobre las variables `SUPABASE_URL` / `SUPABASE_ANON_KEY`
  para activar Supabase en local.
- Repo público con **commits atómicos por fase** (el historial comunica cómo se
  dirigió el trabajo → puntos en "AI fluency").

---

## Anexo — Contexto del stack del equipo (no es entregable)
El backend del equipo es **Supabase + Deno + TypeScript** (confirmado): las Edge
Functions de Supabase corren sobre Deno y se escriben en TS, así que el stack
describe ese esquema de forma directa. Útil para la entrevista; **no se implementa
aquí** — la prioridad es respetar el brief (sin backend requerido).

## Decisiones pendientes (cerrar en la plática)
1. ✅ API de clima → **Open-Meteo** (sin key, CORS, gratis no comercial).
2. ✅ Decisión de seguridad → **bcrypt** en memoria; Argon2id como prod (server-side).
3. ✅ Tradeoff → **caché vs. frescura** en clima (stale-while-revalidate).
4. ✅ Stack backend → **Deno** (confirmado). Contexto para entrevista, no se implementa.
