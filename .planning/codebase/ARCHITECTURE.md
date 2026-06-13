<!-- refreshed: 2026-06-13 -->
# Architecture

**Analysis Date:** 2026-06-13

## System Overview

```text
┌─────────────────────────────────────────────────────────────────────┐
│                    Presentation Layer (Flutter UI)                   │
│   Screens / Widgets                    Providers (Riverpod)          │
│   `lib/features/*/presentation/`       `lib/features/*/presentation/ │
│                                         providers/`                  │
└────────────┬────────────────────────────────────┬───────────────────┘
             │ reads/writes via providers          │ watches
             ▼                                     ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       Domain Layer                                   │
│   Entities / Repositories (interfaces) / Services / Logic           │
│   `lib/features/*/domain/`                                           │
└────────────┬────────────────────────────────────────────────────────┘
             │ implemented by
             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Data Layer                                    │
│   Repository Impls / Datasources / Services                         │
│   `lib/features/*/data/`                                             │
└──────┬──────────────────┬─────────────────────┬─────────────────────┘
       │                  │                      │
       ▼                  ▼                      ▼
┌────────────┐  ┌──────────────────┐  ┌──────────────────────────────┐
│  Hive CE   │  │   SQLite         │  │  External APIs                │
│  (local    │  │  (DSO/Star DB)   │  │  Open-Meteo (weather)         │
│   cache)   │  │  `lib/core/      │  │  Open-Meteo Geocoding         │
│`lib/hive/` │  │   engine/        │  │  Cloudflare Proxy (optional)  │
└────────────┘  │   database/`     │  └──────────────────────────────┘
                └──────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│               Astronomy Engine (Isolate-backed)                      │
│   Swiss Ephemeris (sweph) + Meeus algorithms                         │
│   `lib/core/engine/`  → offloads >16ms work to Dart Isolates         │
└─────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File / Path |
|-----------|----------------|-------------|
| `MyApp` | Root widget, GoRouter wiring, red-mode overlay | `lib/my_app.dart` |
| `AppRouter` | Declarative routing, splash/ToS/deep-link redirects | `lib/app/router/app_router.dart` |
| `AstronomyService` | Swiss Ephemeris init, rise/set/transit calculations | `lib/features/astronomy/domain/services/astronomy_service.dart` |
| `AstroEngine` | Meeus-algorithm position calculations, isolate offload | `lib/core/engine/astro_engine.dart` |
| `EngineIsolateManager` | Spawns/manages Dart Isolates for CPU-heavy calc | `lib/core/engine/isolates/engine_isolate_manager.dart` |
| `WeatherNotifier` | Async Riverpod notifier, fetches/caches weather | `lib/features/dashboard/presentation/providers/weather_provider.dart` |
| `OpenMeteoWeatherService` | HTTP client for Open-Meteo weather API | `lib/features/dashboard/data/datasources/open_meteo_weather_service.dart` |
| `CachedWeatherRepository` | Cache-first weather data with Hive CE | `lib/features/dashboard/data/repositories/cached_weather_repository.dart` |
| `LocationRepositoryImpl` | SQLite-backed user location CRUD | `lib/features/profile/data/repositories/location_repository_impl.dart` |
| `DsoRepository` / `StarRepository` | SQLite read-only celestial catalog | `lib/core/engine/database/dso_repository.dart`, `star_repository.dart` |
| `H3Service` | H3 hexagonal grid for zone/light-pollution lookup | `lib/features/data_layer/services/h3_service.dart` |
| `BackgroundSyncHandler` | WorkManager-based background weather prefetch | `lib/core/platform/background_sync_handler.dart` |
| `WeatherCachePruningService` | Evicts stale Hive cache entries on resume | `lib/features/dashboard/data/services/weather_cache_pruning_service.dart` |
| `InitializationNotifier` | Tracks splash-screen init sequence gate | `lib/features/splash/presentation/providers/initialization_provider.dart` |

## Pattern Overview

**Overall:** Feature-first Clean Architecture with Riverpod state management

**Key Characteristics:**
- Each feature in `lib/features/*/` is divided into three layers: `domain/`, `data/`, `presentation/`
- Domain layer contains interfaces (abstract repos, service contracts) that the data layer implements
- Riverpod providers wire implementations into the presentation layer without direct imports from `data/`
- Heavy computations (astronomical calculations) are offloaded to Dart Isolates via `EngineIsolateManager`
- Platform-specific behaviour (web vs. mobile) uses conditional imports (`dart.library.html`)
- State management uses both `AsyncNotifier` (async data) and `StateNotifier` (sync state machines)

## Layers

**Presentation Layer:**
- Purpose: Flutter widgets and Riverpod providers that consume domain services
- Location: `lib/features/*/presentation/`
- Contains: Screens, widgets, providers, theme overrides per feature
- Depends on: Domain layer interfaces (via providers)
- Used by: App router, end users

**Domain Layer:**
- Purpose: Business rules, entities, repository contracts
- Location: `lib/features/*/domain/`
- Contains: Entities, abstract repository interfaces, domain services, logic classes
- Depends on: Nothing platform-specific
- Used by: Presentation layer (via providers), data layer (implements interfaces)

**Data Layer:**
- Purpose: Concrete implementations of domain contracts, external I/O
- Location: `lib/features/*/data/`
- Contains: Repository impls, datasource classes (HTTP/SQLite/Hive), services
- Depends on: Domain interfaces, external packages (Dio, Hive, SQLite)
- Used by: Presentation providers via Riverpod dependency injection

**Core Layer:**
- Purpose: Shared infrastructure not tied to any single feature
- Location: `lib/core/`
- Contains: Engine (astro calculations), error types, utils, platform helpers, config, shared widgets
- Depends on: External packages only
- Used by: Any feature layer

**Shared Data Layer:**
- Purpose: Global data models and cross-feature repositories
- Location: `lib/data/`, `lib/hive/`
- Contains: Network repository, user model (freezed), Hive adapter registrations
- Used by: Multiple features

## Data Flow

### Weather Forecast Request (Primary Path)

1. User opens Dashboard → `HomeScreen` widget (`lib/features/dashboard/presentation/home_screen.dart`)
2. Widget watches `weatherProvider` → `WeatherNotifier.build()` (`lib/features/dashboard/presentation/providers/weather_provider.dart`)
3. Notifier reads active location from `locationProvider`
4. Calls `CachedWeatherRepository.getWeather()` (`lib/features/dashboard/data/repositories/cached_weather_repository.dart`)
5. Cache miss → `OpenMeteoWeatherService.getHourlyForecast()` via Dio (`lib/features/dashboard/data/datasources/open_meteo_weather_service.dart`)
6. Response stored in Hive CE `weatherCache` box
7. `Weather` entity returned up the chain → UI rebuilt

### Astronomical Calculation Path

1. Splash screen triggers `AstronomyService.init()` (`lib/features/astronomy/domain/services/astronomy_service.dart`)
2. Swiss Ephemeris (sweph) initialised via platform-conditional `initializeSwephPlatform()`
3. Feature providers call `AstronomyService.calculateRiseSetTransit()` or `AstroEngine.calculatePosition()`
4. `AstroEngine` wraps call in `CalculatePositionCommand` → sends to `EngineIsolateManager` (`lib/core/engine/isolates/engine_isolate_manager.dart`)
5. Isolate runs Meeus algorithm (`lib/core/engine/algorithms/coordinate_transformations.dart`)
6. Result returned as `Result<HorizontalCoordinates>` (fpdart-style)

### App Startup / Routing

1. `main()` initialises: timezones, EasyLocalization, Hive CE, orientation lock (`lib/main.dart`)
2. `BackgroundSync` registered with WorkManager (`lib/core/platform/background_sync_handler.dart`)
3. GoRouter starts at `/splash` → `SplashScreen` runs initialization sequence
4. `InitializationNotifier` flips to true → router redirect re-evaluated
5. If ToS not accepted → `/tos`; else LaunchResult decides `/` vs `/settings/locations/add`

**State Management:**
- Riverpod `AsyncNotifier`: async data fetching with loading/error/data states (`weatherProvider`, `initializationNotifierProvider`)
- Riverpod `StateNotifier`: synchronous state machines (`visibilityProvider`)
- Riverpod `Provider`: simple DI for services and repositories (e.g. `astronomyServiceProvider`)
- `@riverpod` code-gen annotations used in some newer providers (`.g.dart` files present)

## Key Abstractions

**`IAstroEngine`:**
- Purpose: Interface for astronomical position calculations
- Examples: `lib/core/engine/interfaces/i_astro_engine.dart`
- Pattern: Interface implemented by `AstroEngine`, injected via `Provider`

**`IWeatherRepository`:**
- Purpose: Contract for weather data access (cache-first or direct)
- Examples: `lib/features/dashboard/domain/repositories/i_weather_repository.dart`
- Pattern: Implemented by `CachedWeatherRepository`, injected into `WeatherNotifier`

**`Result<T>`:**
- Purpose: Functional error handling (success/failure union)
- Examples: `lib/core/engine/models/result.dart`
- Pattern: Used throughout engine layer; callers inspect `.isSuccess` / `.failure`

**`LaunchResult`:**
- Purpose: Sealed class encoding app launch outcomes (success, timeout, permission denied, service disabled)
- Examples: `lib/features/splash/domain/entities/launch_result.dart`
- Pattern: Router `switch` on `LaunchResult` to determine initial route

## Entry Points

**`main()`:**
- Location: `lib/main.dart`
- Triggers: App launch (mobile) or `lib/main_web.dart` (web)
- Responsibilities: Bootstrap all services, create `ProviderContainer`, run `MyApp`

**`BackgroundSyncHandler`:**
- Location: `lib/core/platform/background_sync_handler.dart`
- Triggers: WorkManager scheduled task (background)
- Responsibilities: Prefetch weather data for saved locations while app is closed

**`SplashScreen`:**
- Location: `lib/features/splash/presentation/splash_screen.dart`
- Triggers: Router initial route `/splash`
- Responsibilities: Runs initialization sequence (astronomy service, location permission), fires `onInitializationComplete`

## Architectural Constraints

- **Threading:** Single-threaded UI; CPU-heavy astronomical calculations offloaded to Dart Isolates automatically when estimated >16ms by `EngineIsolateManager`
- **Global state:** `ProviderContainer` created in `main()` and wrapped in `UncontrolledProviderScope`; Hive boxes opened globally in `initHive()` (`lib/hive/hive.dart`)
- **Platform splits:** Web vs mobile behaviour separated via `dart.library.html` conditional imports for astronomy init (`astronomy_service_mobile.dart` / `astronomy_service_web.dart`), database init (`database_service_mobile.dart` / `_web.dart`), and location DB (`location_database_service_mobile.dart` / `_web.dart`)
- **Portrait-only:** `setPreferredOrientations()` locks to portrait in `main.dart`
- **Dark mode only:** `ThemeMode.dark` forced; `AppTheme.darkTheme` only theme in use (`lib/app/theme/app_theme.dart`)

## Anti-Patterns

### Mixed Provider Styles

**What happens:** Some providers use `StateNotifier` + `StateNotifierProvider` (older pattern), while others use code-gen `@riverpod` / `AsyncNotifier` (newer pattern). Both exist in the same feature (`visibilityProvider` vs `weatherProvider`).
**Why it's wrong:** Inconsistency increases cognitive load; `StateNotifier` is deprecated in Riverpod 2.x.
**Do this instead:** Use `@riverpod` annotation with `AsyncNotifier` or `Notifier` for all new providers. Reference `lib/features/dashboard/presentation/providers/weather_provider.dart` for the preferred async pattern.

### Presentation Providers Importing Data Layer Directly

**What happens:** Some presentation providers instantiate datasource classes directly rather than accessing them through the domain repository interface.
**Why it's wrong:** Bypasses the clean architecture boundary; makes unit testing harder.
**Do this instead:** All datasource access should flow through a repository interface defined in `domain/repositories/`, resolved via a Riverpod provider from the data layer.

## Error Handling

**Strategy:** Functional Result types in the engine layer; exceptions surfaced as Riverpod `AsyncError` in the presentation layer.

**Patterns:**
- `Result<T>` (success/failure) used by `AstroEngine` (`lib/core/engine/models/result.dart`)
- `Failure` sealed class hierarchy for typed errors: `CalculationFailure`, `WeatherFailure`, `LightPollutionFailure` (`lib/core/error/`, `lib/core/engine/error/`)
- Riverpod `AsyncNotifier` automatically wraps thrown exceptions as `AsyncError` state; UI watches and renders error widgets
- Silent fail with `debugPrint` used in non-critical paths (cache pruning, service init)

## Cross-Cutting Concerns

**Logging:** `logger` package (v2.5) for structured logging; `debugPrint` for development traces; `debugPrint` overridden to no-op in release builds (`lib/main.dart`)
**Validation:** Coordinate validation service at `lib/features/data_layer/services/coordinate_validation_service.dart`
**Authentication:** None — app is fully local/offline-capable; no user auth system
**Localisation:** `easy_localization` with locale files in `assets/`; supported: `en`, `tr`
**Analytics:** Microsoft Clarity via `clarity_flutter` SDK, configured in `main()` with project ID `ujfp0i4u4p`

---

*Architecture analysis: 2026-06-13*
