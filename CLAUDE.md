<!-- GSD:project-start source:PROJECT.md -->

## Project

**Astr**

Astr is a Flutter stargazing conditions app for iOS and Android. It tells you exactly how good your current location is for observing the night sky tonight — and lets you explore any location in the world. It uses a custom Astr Zone system (based on light pollution Zenith Brightness data with skyglow diffusion) combined with live weather data to calculate one of 6 sky states, each with a distinct illustrated background. Beyond conditions, it shows astronomical data: moon phase, visible planets, and deep sky objects from a bundled SQLite catalog.

**Core Value:** Know instantly whether tonight's sky is worth going outside — and if not, know why.

### Constraints

- **Tech Stack**: Flutter (Dart) — no platform change
- **State Management**: Riverpod — established pattern, not changing
- **Navigation**: GoRouter — stay with declarative routing
- **Zone data**: Cloudflare Workers + R2/D1 — active production infrastructure
- **Weather**: Open-Meteo — free, accurate, no key required
- **Design**: Figma specs provided per screen — implement exactly as designed
- **App Store**: Must meet both Google Play and Apple App Store submission requirements
- **Night Vision**: Red Mode overlay must be preserved — core to astronomy use case

<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->

## Technology Stack

## Languages

- Dart 3.x (SDK `>=3.0.5 <4.0.0`) - Flutter mobile/web app (`lib/`)
- Python 3.x - Backend API (`backend/api/index.py`)
- JavaScript / TypeScript - Cloudflare Worker (`cloudflare/worker.js`)

## Runtime

- Flutter SDK (multi-platform: Android, iOS, Web, Linux, macOS, Windows)
- Python (Vercel serverless via `@vercel/python`)
- Cloudflare Workers runtime (`cloudflare/wrangler.toml`, compatibility_date 2024-12-01)

## Package Manager

- `pub` (Dart package manager)
- Lockfile: `pubspec.lock` (present)
- `pip` with `requirements.txt`
- Virtual env: `venv/`
- `npm` (lockfile: `cloudflare/package-lock.json`)

## Frameworks

- Flutter (multi-platform) - Primary app framework
- `flutter_riverpod` ^2.6.1 + `riverpod_annotation` ^2.6.1 - Reactive state management
- `go_router` ^16.2.4 - Declarative routing
- `dio` ^5.8.0+1 - Primary HTTP client for weather/geocoding API calls
- `http` ^1.6.0 - Used in `RemoteZoneService` for Cloudflare Worker calls
- Flask 3.0.0 - Python web framework for `/api/light-pollution` endpoint
- Cloudflare Workers (Wrangler ^4.0.0) - Serves zone data from R2/D1
- `flutter_test` (SDK built-in) - Unit and widget tests
- `riverpod_test` ^0.1.9 - Riverpod provider testing
- `mockito` ^5.4.6 + `mocktail` ^1.0.4 - Mocking
- `sqflite_common_ffi` ^2.3.0 - SQLite testing on desktop/CI
- Vitest ^4.0.18 - Cloudflare Worker tests
- `build_runner` ^2.4.15 - Code generation runner
- `json_serializable` ^6.9.4 - JSON serialization codegen
- `riverpod_generator` ^2.6.4 - Riverpod provider codegen
- `freezed` ^3.0.6 - Immutable data class codegen
- `hive_ce_generator` ^1.9.1 - Hive type adapter codegen
- `custom_lint` ^0.7.5 + `riverpod_lint` ^2.6.4 - Custom lint rules

## Key Dependencies

- `sweph` ^3.2.1+2.10.3 - Swiss Ephemeris bindings for astronomical calculations (planet/star positions)
- `h3_flutter` ^0.7.1 - Uber H3 geospatial indexing for light pollution zone lookups
- `geolocator` ^14.0.2 - Device GPS location with permission handling
- `hive_ce` ^2.11.1 + `hive_ce_flutter` ^2.3.0 - Primary local cache (weather, zones, locations, prefs)
- `sqflite` ^2.4.1 - Local SQLite for bundled star/DSO catalog (`assets/db/`)
- `workmanager` ^0.9.0 - Background sync scheduling (Android WorkManager / iOS BGTaskScheduler)
- `fpdart` ^1.1.0 - Functional programming types (`Either`, `Option`) for error handling
- `rive` ^0.13.20 - Rive animations
- `flutter_animate` ^4.5.2 - Animation helpers
- `lottie` ^3.1.0 - Lottie animations
- `flex_color_scheme` ^8.0.2 - Theming
- `google_fonts` ^6.2.1 - Google Fonts
- `flutter_svg` ^2.0.10 - SVG rendering for constellation/celestial icons
- `gap` ^3.0.1 - Spacing widget
- `easy_localization` ^3.0.7 - i18n (English + Turkish supported)
- `intl` ^0.20.2 - Date/number formatting
- `get_storage` ^2.1.1 - Simple key-value storage (used in `astr_context_provider.dart` for selected location)
- `timezone` ^0.10.1 + `lat_lng_to_timezone` ^0.2.0 - Timezone resolution from coordinates
- `crypto` ^3.0.7 - Hashing utilities
- `freezed_annotation` ^3.0.0 + `json_annotation` ^4.9.0 - Annotation support for codegen
- `equatable` ^2.0.7 - Value equality
- `logger` ^2.5.0 - Structured logging
- `package_info_plus` ^9.0.0 - App version info
- `device_info_plus` ^11.4.0 - Device metadata
- `timeago` ^3.7.0 - Relative time strings
- `stack_trace` ^1.11.0 - Enhanced stack traces in release mode
- `image` ^4.5.4 - Image processing
- `permission_handler` ^12.0.1 - Runtime permission requests
- `url_launcher` ^6.1.11 - Open external URLs
- `ionicons` ^0.2.2 - Ionicons icon set
- `path_provider` ^2.1.5 - Platform-specific paths
- `pymongo` 4.6.0 - MongoDB client
- `python-dotenv` 1.0.0 - Environment variable loading
- `dnspython` 2.6.1 - DNS resolution for MongoDB SRV URIs

## Configuration

- Flutter: Build-time environment injection via `--dart-define=API_KEY=...`
- Backend: `.env` file loaded via `python-dotenv` (not committed)
- Required backend env var: `MONGODB_URI`
- `build.sh` - Flutter web build script invoked by Vercel
- `analysis_options.yaml` - Dart analyzer config
- `lint_rules.yaml` - Custom lint rule definitions
- `devtools_options.yaml` - Flutter DevTools settings
- Run `flutter pub run build_runner build` to regenerate `.g.dart` and `.freezed.dart` files

## Platform Requirements

- Flutter SDK (Dart >=3.0.5)
- Android Studio / Xcode for native targets
- Node.js + Wrangler CLI for Cloudflare Worker development
- Python 3.x + pip for backend development
- Flutter app: Android (minSdk 21), iOS, Web
- Backend API: Vercel (Python serverless)
- Web app: Vercel (Flutter web, custom `build.sh`)
- Zone data: Cloudflare Workers + R2 + D1

<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->

## Conventions

## Naming Patterns

- Dart source files use `snake_case`: `darkness_calculator.dart`, `weather_repository_impl.dart`
- Generated files end with `.g.dart` (json_serializable, riverpod_generator), `.freezed.dart` (Freezed)
- Interface files are prefixed with `i_`: `i_weather_repository.dart`, `i_location_service.dart`
- Implementation files are suffixed with `_impl`: `weather_repository_impl.dart`, `cached_weather_repository.dart`
- Test files mirror source paths and end with `_test.dart`: `darkness_calculator_test.dart`
- Mock files generated by Mockito end with `.mocks.dart`: `astr_context_test.mocks.dart`
- `PascalCase` for all class names: `DarknessCalculator`, `CachedWeatherRepository`, `AstrContextNotifier`
- Abstract interfaces prefixed with `I`: `IWeatherRepository`, `ILocationService`, `ICatalogRepository`
- Fake test implementations prefixed with `Fake`: `FakeWeatherRepository`, `FakeOpenMeteoWeatherService`
- Mock implementations prefixed with `Mock`: `MockILocationService`, `MockICatalogRepository`
- Riverpod notifiers end with `Notifier`: `AstrContextNotifier`, `ObjectDetailNotifier`
- `camelCase` for methods and functions: `calculateDarkness()`, `getDarknessLabel()`, `getHourlyForecast()`
- Private members prefixed with `_`: `_inner`, `_cache`, `_h3`, `_loadInitialContext()`
- Private constants prefixed with `_k`: `_kLastLatitude`, `_kLastLongitude`, `_kUsePersistedLocation`
- Boolean getters use `is`/`has` prefix when appropriate: `isStale`, `isCurrentLocation`
- `camelCase` for local variables: `moonPenalty`, `altitudeRadians`, `effectiveAltitudeFactor`
- Type-annotated variables are preferred for clarity: `final double result`, `final Either<Failure, Weather> result`
- Test subjects named `sut` (System Under Test) or descriptively: `calculator`, `repository`
- Test fixtures prefixed with `t`: `tLocation`, `tLightPollution`
- Constants are `camelCase` at class level: `_h3Resolution`
- Enums use `PascalCase` for the type, `camelCase` for values: `StargazingQuality.excellent`, `CelestialType.planet`
- Type aliases use `PascalCase`

## Code Style

- Dart analyzer enforces strict mode: `strict-casts: true`, `strict-inference: true`, `strict-raw-types: true`
- Configured via `analysis_options.yaml` which includes `lint_rules.yaml`
- Single quotes preferred over double quotes (`prefer_double_quotes: false`)
- No trailing commas required (`require_trailing_commas: false`)
- Lines over 80 chars permitted (`lines_longer_than_80_chars: false`)
- Control body on same line allowed: `if (bool) return;`
- Local variable types must be specified (`omit_local_variable_types: false`)
- `prefer_final_locals` is enabled — use `final` for local variables when not reassigned
- Tool: `flutter_lints` + `custom_lint` + `riverpod_lint`
- Config: `analysis_options.yaml`, `lint_rules.yaml`
- Generated files excluded from analysis: `lib/**.freezed.dart`, `lib/**.g.dart`

## Import Organization

- Package imports use `package:astr/...` in tests
- Source files use relative imports internally: `'../../../../core/error/failure.dart'`
- No path aliases configured (`@` style not used)

## Error Handling

- All repository methods return `Future<Either<Failure, T>>`
- `Left` wraps typed `Failure` subclasses; `Right` wraps success value
- Callers use `.fold()` to handle both arms
- `Failure` (abstract base with `message`)
- `ServerFailure` — HTTP/network errors
- `CacheFailure` — local storage errors
- `DatabaseFailure` — SQLite/Hive errors
- `LocationFailure` — GPS/location errors
- `PermissionFailure` — OS permission errors
- `CalculationFailure` — domain computation errors
- `TimeoutFailure` — timeout errors
- Additional: `WeatherFailure` (`lib/core/error/weather_failure.dart`), `LightPollutionFailure` (`lib/core/error/light_pollution_failure.dart`)
- Datasource layer throws raw exceptions (e.g., `throw Exception('Failed to fetch')`)
- Repository layer catches and wraps into typed `Failure`: `Left(ServerFailure(e.toString()))`
- Non-critical errors (e.g., staleness tracking) are caught silently and logged
- `AsyncValue.guard()` used for async notifier builds
- Providers expose `AsyncValue<T>` for loading/error/data states
- Optimistic updates applied before async completion with a state correction after

## Logging

- `debugPrint` used throughout for debug-level output
- Release mode: all `debugPrint` calls are suppressed via override in `lib/main.dart` (line 50)
- Structured messages include class prefix: `'[SmartLaunchController] GPS timeout'`
- Stack traces logged in `kDebugMode` block only
- `logger` package is imported in `pubspec.yaml` but `debugPrint` is the observed pattern in practice

## Comments

- Public API: doc comments (`///`) on all public classes, methods, and parameters
- Algorithm references: cite external documents (`/// See docs/calculations.md`)
- Functional requirements: inline comments reference spec IDs (`// AC#3`, `// FR-09`, `// NFR-10`)
- Non-obvious logic: explain the "why", not the "what"
- Deprecated methods: marked with `/// AC#X: This method is now deprecated...`
- `///` for doc comments on public members
- `//` for inline implementation comments
- Comment block at top of test files naming what's being tested and any references

## Function Design

- Named parameters preferred for 2+ arguments, especially in constructors and service methods
- `required` keyword used for mandatory named parameters
- Optional parameters use `?` types with defaults in constructors: `this.isStale = false`
- `Either<Failure, T>` for all fallible async operations
- `(String, int)` record types used for returning coupled values (e.g., `getDarknessLabel` returns label + color)
- `copyWith` pattern on immutable entity classes

## Module Design

- Feature barrels via `index.dart` (e.g., `lib/features/data_layer/index.dart`)
- No global barrel at `lib/` root; imports are explicit
- Riverpod providers: `riverpod_generator` + `@riverpod` annotation → `.g.dart`
- Freezed data classes: `freezed` + `@freezed` annotation → `.freezed.dart`
- JSON: `json_serializable` + `@JsonSerializable()` → `.g.dart`
- Hive adapters: `hive_ce_generator` → `.g.dart`
- Mocks: `mockito` + `@GenerateMocks([...])` → `.mocks.dart`
- Run: `dart run build_runner build`

<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->

## Architecture

## System Overview

```text

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

- Each feature in `lib/features/*/` is divided into three layers: `domain/`, `data/`, `presentation/`
- Domain layer contains interfaces (abstract repos, service contracts) that the data layer implements
- Riverpod providers wire implementations into the presentation layer without direct imports from `data/`
- Heavy computations (astronomical calculations) are offloaded to Dart Isolates via `EngineIsolateManager`
- Platform-specific behaviour (web vs. mobile) uses conditional imports (`dart.library.html`)
- State management uses both `AsyncNotifier` (async data) and `StateNotifier` (sync state machines)

## Layers

- Purpose: Flutter widgets and Riverpod providers that consume domain services
- Location: `lib/features/*/presentation/`
- Contains: Screens, widgets, providers, theme overrides per feature
- Depends on: Domain layer interfaces (via providers)
- Used by: App router, end users
- Purpose: Business rules, entities, repository contracts
- Location: `lib/features/*/domain/`
- Contains: Entities, abstract repository interfaces, domain services, logic classes
- Depends on: Nothing platform-specific
- Used by: Presentation layer (via providers), data layer (implements interfaces)
- Purpose: Concrete implementations of domain contracts, external I/O
- Location: `lib/features/*/data/`
- Contains: Repository impls, datasource classes (HTTP/SQLite/Hive), services
- Depends on: Domain interfaces, external packages (Dio, Hive, SQLite)
- Used by: Presentation providers via Riverpod dependency injection
- Purpose: Shared infrastructure not tied to any single feature
- Location: `lib/core/`
- Contains: Engine (astro calculations), error types, utils, platform helpers, config, shared widgets
- Depends on: External packages only
- Used by: Any feature layer
- Purpose: Global data models and cross-feature repositories
- Location: `lib/data/`, `lib/hive/`
- Contains: Network repository, user model (freezed), Hive adapter registrations
- Used by: Multiple features

## Data Flow

### Weather Forecast Request (Primary Path)

### Astronomical Calculation Path

### App Startup / Routing

- Riverpod `AsyncNotifier`: async data fetching with loading/error/data states (`weatherProvider`, `initializationNotifierProvider`)
- Riverpod `StateNotifier`: synchronous state machines (`visibilityProvider`)
- Riverpod `Provider`: simple DI for services and repositories (e.g. `astronomyServiceProvider`)
- `@riverpod` code-gen annotations used in some newer providers (`.g.dart` files present)

## Key Abstractions

- Purpose: Interface for astronomical position calculations
- Examples: `lib/core/engine/interfaces/i_astro_engine.dart`
- Pattern: Interface implemented by `AstroEngine`, injected via `Provider`
- Purpose: Contract for weather data access (cache-first or direct)
- Examples: `lib/features/dashboard/domain/repositories/i_weather_repository.dart`
- Pattern: Implemented by `CachedWeatherRepository`, injected into `WeatherNotifier`
- Purpose: Functional error handling (success/failure union)
- Examples: `lib/core/engine/models/result.dart`
- Pattern: Used throughout engine layer; callers inspect `.isSuccess` / `.failure`
- Purpose: Sealed class encoding app launch outcomes (success, timeout, permission denied, service disabled)
- Examples: `lib/features/splash/domain/entities/launch_result.dart`
- Pattern: Router `switch` on `LaunchResult` to determine initial route

## Entry Points

- Location: `lib/main.dart`
- Triggers: App launch (mobile) or `lib/main_web.dart` (web)
- Responsibilities: Bootstrap all services, create `ProviderContainer`, run `MyApp`
- Location: `lib/core/platform/background_sync_handler.dart`
- Triggers: WorkManager scheduled task (background)
- Responsibilities: Prefetch weather data for saved locations while app is closed
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

### Presentation Providers Importing Data Layer Directly

## Error Handling

- `Result<T>` (success/failure) used by `AstroEngine` (`lib/core/engine/models/result.dart`)
- `Failure` sealed class hierarchy for typed errors: `CalculationFailure`, `WeatherFailure`, `LightPollutionFailure` (`lib/core/error/`, `lib/core/engine/error/`)
- Riverpod `AsyncNotifier` automatically wraps thrown exceptions as `AsyncError` state; UI watches and renders error widgets
- Silent fail with `debugPrint` used in non-critical paths (cache pruning, service init)

## Cross-Cutting Concerns

<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->

## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->

## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:

- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->

## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
