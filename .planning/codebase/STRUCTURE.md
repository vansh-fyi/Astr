# Codebase Structure

**Analysis Date:** 2026-06-13

## Directory Layout

```
Astr/
├── lib/                          # Flutter app source
│   ├── main.dart                 # App entry point
│   ├── main_mobile.dart          # Mobile platform init
│   ├── main_web.dart             # Web platform init
│   ├── my_app.dart               # Root widget (MaterialApp.router)
│   ├── app/                      # App-wide setup
│   │   ├── router/               # GoRouter config & nav shell
│   │   └── theme/                # AppTheme (dark only)
│   ├── common/                   # Shared UI widgets
│   ├── config/                   # Legacy config (theme)
│   ├── constants/                # App-wide string/color constants
│   ├── core/                     # Shared infrastructure
│   │   ├── config/               # API config (api_config.dart)
│   │   ├── data/                 # Shared data (network_repository)
│   │   ├── engine/               # Astronomical calculation engine
│   │   │   ├── algorithms/       # Meeus coordinate math, KD-tree
│   │   │   ├── database/         # SQLite DSO/Star catalog access
│   │   │   ├── interfaces/       # IAstroEngine interface
│   │   │   ├── isolates/         # Dart Isolate manager
│   │   │   └── models/           # Engine value types
│   │   ├── error/                # Failure sealed classes
│   │   ├── platform/             # Background sync, platform helpers
│   │   ├── providers/            # Global Riverpod providers
│   │   ├── services/             # Location, darkness, weather services
│   │   │   ├── qualitative/      # Seeing/darkness quality calc
│   │   │   └── weather/          # Weather service interface + impl
│   │   ├── utils/                # Bortle converter, timezone helper
│   │   └── widgets/              # Shared widgets (red-mode overlay)
│   ├── data/                     # Cross-feature data models
│   │   ├── enums/                # Shared enums
│   │   ├── models/               # Shared freezed models (user, network)
│   │   └── repository/           # Network repository (Dio-based)
│   ├── exceptions/               # Custom exception types
│   ├── features/                 # Feature modules (clean architecture)
│   │   ├── astronomy/            # Astronomical event calculations
│   │   ├── catalog/              # DSO/Star catalog browse & detail
│   │   ├── context/              # Geocoding & location context
│   │   ├── dashboard/            # Main home dashboard (weather, sky)
│   │   ├── data_layer/           # Shared zone/H3 grid data feature
│   │   ├── forecast/             # Multi-day weather forecast view
│   │   ├── planner/              # Observation planning
│   │   ├── profile/              # User settings & saved locations
│   │   └── splash/               # Splash screen & initialization flow
│   ├── hive/                     # Hive CE setup & adapter registration
│   └── utils/                    # App-level utilities (URL, extensions)
├── test/                         # Test suite
│   ├── app/                      # App-level tests
│   ├── astronomy/                # Astronomy calculation tests
│   ├── core/                     # Core service tests
│   ├── features/                 # Feature-level unit/widget tests
│   ├── helpers/                  # Test helpers/factories
│   └── navigation/               # Router/navigation tests
├── assets/                       # Static assets (fonts, images, locales)
├── android/                      # Android platform project
├── ios/                          # iOS platform project
├── web/                          # Web platform project
├── linux/ macos/ windows/        # Desktop platform projects
├── api/                          # Python Vercel serverless API (index.py)
├── cloudflare/                   # Cloudflare Worker proxy (optional)
├── backend/                      # Backend scripts/helpers
├── scripts/                      # Build/utility scripts
├── docs/                         # Project documentation
├── pubspec.yaml                  # Flutter dependency manifest
├── analysis_options.yaml         # Dart analysis config
└── build.sh                      # CI build script
```

## Directory Purposes

**`lib/features/`:**
- Purpose: All user-facing functionality, strictly feature-isolated
- Contains: One subdirectory per feature, each with `domain/`, `data/`, `presentation/`
- Key files: See per-feature breakdown below

**`lib/core/`:**
- Purpose: Infrastructure shared across features — engine, config, platform adapters
- Contains: Astronomy engine, error types, shared services, global providers
- Key files: `lib/core/engine/astro_engine.dart`, `lib/core/config/api_config.dart`, `lib/core/platform/background_sync_handler.dart`

**`lib/hive/`:**
- Purpose: Centralised Hive CE initialisation and adapter registration
- Contains: `hive.dart` (init), `hive_adapters.dart`, generated registrar
- Key files: `lib/hive/hive.dart`

**`lib/app/`:**
- Purpose: App-level wiring — router and theme
- Contains: `app_router.dart` (GoRouter), `app_theme.dart` (dark theme only)
- Key files: `lib/app/router/app_router.dart`, `lib/app/theme/app_theme.dart`

**`lib/data/`:**
- Purpose: Cross-feature data models not owned by any single feature
- Contains: Freezed models, shared network repository
- Key files: `lib/data/models/user_model.dart`, `lib/data/repository/network_repository.dart`

**`test/`:**
- Purpose: Unit, widget and integration tests mirroring `lib/` structure
- Contains: Feature tests, helper factories, navigation tests

## Key File Locations

**Entry Points:**
- `lib/main.dart`: App bootstrap — Hive init, background sync, `runApp`
- `lib/main_mobile.dart`: Mobile-specific platform init (display mode)
- `lib/main_web.dart`: Web-specific platform init
- `lib/my_app.dart`: Root `ConsumerStatefulWidget` with `MaterialApp.router`

**Routing:**
- `lib/app/router/app_router.dart`: All routes defined here with GoRouter `StatefulShellRoute`
- `lib/app/router/scaffold_with_nav_bar.dart`: Bottom nav bar shell

**Configuration:**
- `lib/core/config/api_config.dart`: Weather and geocoding API URLs, proxy toggle
- `pubspec.yaml`: All Flutter/Dart dependencies

**Core Logic:**
- `lib/core/engine/astro_engine.dart`: Astronomical position calculations
- `lib/core/engine/isolates/engine_isolate_manager.dart`: Isolate pool for CPU work
- `lib/core/engine/algorithms/coordinate_transformations.dart`: Meeus math
- `lib/core/engine/database/dso_repository.dart`: Deep-sky object SQLite queries
- `lib/core/engine/database/star_repository.dart`: Star catalog SQLite queries

**State Management (Representative Providers):**
- `lib/features/dashboard/presentation/providers/weather_provider.dart`: Weather async state
- `lib/features/splash/presentation/providers/initialization_provider.dart`: Splash gate
- `lib/features/profile/presentation/providers/settings_provider.dart`: User settings (red mode)
- `lib/app/router/app_router.dart`: `goRouterProvider` (Riverpod-managed router)

**Persistence:**
- `lib/hive/hive.dart`: Hive CE box open/close lifecycle
- `lib/features/profile/data/datasources/location_database_service.dart`: SQLite location store
- `lib/features/dashboard/data/repositories/cached_weather_repository.dart`: Hive weather cache

**External I/O:**
- `lib/features/dashboard/data/datasources/open_meteo_weather_service.dart`: Weather HTTP
- `lib/features/context/data/datasources/geocoding_service.dart`: Geocoding HTTP
- `lib/features/data_layer/services/h3_service.dart`: H3 grid zone lookup

**Testing:**
- `test/features/`: Feature unit tests
- `test/helpers/`: Shared test factories and mocks
- `test/astronomy/`: Astronomy calculation accuracy tests

## Naming Conventions

**Files:**
- All Dart files use `snake_case.dart`
- Interfaces prefixed with `i_`: `i_weather_repository.dart`, `i_astro_engine.dart`
- Generated files suffixed with `.g.dart` (json_serializable, riverpod_annotation) or `.freezed.dart`
- Platform splits: `*_mobile.dart` / `*_web.dart` sibling files

**Directories:**
- Feature directories use `snake_case`
- Each feature strictly contains `domain/`, `data/`, `presentation/` subdirectories
- Domain sub-dirs: `entities/`, `repositories/`, `services/`, `logic/`
- Data sub-dirs: `datasources/`, `repositories/`, `models/`, `services/`
- Presentation sub-dirs: `screens/`, `widgets/`, `providers/`, `pages/`

**Classes:**
- Widgets: `PascalCase` ending in `Screen`, `Page`, `Widget`, `Card`, or descriptive noun
- Providers: `PascalCase` ending in `Provider` or `Notifier`; provider instances in `camelCase`
- Repositories: `PascalCase` ending in `Repository` (interface) or `RepositoryImpl` (concrete)
- Services: `PascalCase` ending in `Service`
- Entities/models: `PascalCase` noun (e.g. `Weather`, `UserLocation`, `CelestialObject`)

## Where to Add New Code

**New Feature:**
- Create `lib/features/<feature_name>/` with three layers:
  - `domain/entities/`, `domain/repositories/`, `domain/services/`
  - `data/datasources/`, `data/repositories/`
  - `presentation/screens/`, `presentation/widgets/`, `presentation/providers/`
- Register routes in `lib/app/router/app_router.dart`
- Tests: `test/features/<feature_name>/`

**New Screen within Existing Feature:**
- Implementation: `lib/features/<feature>/presentation/screens/<name>_screen.dart`
- Add route: `lib/app/router/app_router.dart`
- Widget tests: `test/features/<feature>/`

**New Riverpod Provider:**
- Place inside `lib/features/<feature>/presentation/providers/<name>_provider.dart`
- Prefer `@riverpod` code-gen annotation with `AsyncNotifier` for async data
- Use `Provider` for simple service injection

**New Domain Repository:**
- Interface: `lib/features/<feature>/domain/repositories/i_<name>_repository.dart`
- Implementation: `lib/features/<feature>/data/repositories/<name>_repository_impl.dart`
- Wire via a Riverpod `Provider` in the data layer

**New External API Call:**
- Datasource class: `lib/features/<feature>/data/datasources/<name>_service.dart`
- URL config: Add to `lib/core/config/api_config.dart`
- Use Dio from `lib/data/repository/network_repository.dart` for HTTP

**Shared Utilities:**
- Pure Dart utils: `lib/core/utils/<name>.dart`
- Shared widgets: `lib/core/widgets/<name>.dart`
- Shared UI components: `lib/common/<name>.dart`

**New Hive Model:**
- Adapter: `lib/hive/hive_adapters.dart` (register new type)
- Re-run: `dart run build_runner build` to regenerate `hive_adapters.g.dart`

## Special Directories

**`lib/hive/`:**
- Purpose: Hive CE adapter registration; call `initHive()` once at app start
- Generated: Partially (`.g.dart`, `.g.yaml` files)
- Committed: Yes (including generated files)

**`api/`:**
- Purpose: Python Vercel serverless function (`index.py`) — lightweight backend proxy
- Generated: No
- Committed: Yes

**`cloudflare/`:**
- Purpose: Cloudflare Worker proxy for API key protection (toggled via `ApiConfig.useProxy`)
- Generated: No
- Committed: Yes

**`build/`:**
- Purpose: Flutter build output
- Generated: Yes
- Committed: No (in `.gitignore`)

**`.agent/`:**
- Purpose: GSD agent skills, scripts, and workflow definitions
- Generated: No (managed by GSD tooling)
- Committed: Yes

**`.planning/`:**
- Purpose: Planning documents, codebase maps, milestone plans
- Generated: By GSD agent commands
- Committed: Yes

---

*Structure analysis: 2026-06-13*
