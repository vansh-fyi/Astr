# Technology Stack

**Analysis Date:** 2026-06-13

## Languages

**Primary:**
- Dart 3.x (SDK `>=3.0.5 <4.0.0`) - Flutter mobile/web app (`lib/`)
- Python 3.x - Backend API (`backend/api/index.py`)

**Secondary:**
- JavaScript / TypeScript - Cloudflare Worker (`cloudflare/worker.js`)

## Runtime

**Mobile/Desktop:**
- Flutter SDK (multi-platform: Android, iOS, Web, Linux, macOS, Windows)

**Backend API:**
- Python (Vercel serverless via `@vercel/python`)

**Edge Worker:**
- Cloudflare Workers runtime (`cloudflare/wrangler.toml`, compatibility_date 2024-12-01)

## Package Manager

**Flutter:**
- `pub` (Dart package manager)
- Lockfile: `pubspec.lock` (present)

**Backend:**
- `pip` with `requirements.txt`
- Virtual env: `venv/`

**Cloudflare Worker:**
- `npm` (lockfile: `cloudflare/package-lock.json`)

## Frameworks

**Core Flutter:**
- Flutter (multi-platform) - Primary app framework

**State Management:**
- `flutter_riverpod` ^2.6.1 + `riverpod_annotation` ^2.6.1 - Reactive state management

**Navigation:**
- `go_router` ^16.2.4 - Declarative routing

**Networking (Flutter):**
- `dio` ^5.8.0+1 - Primary HTTP client for weather/geocoding API calls
- `http` ^1.6.0 - Used in `RemoteZoneService` for Cloudflare Worker calls

**Backend:**
- Flask 3.0.0 - Python web framework for `/api/light-pollution` endpoint

**Edge Worker:**
- Cloudflare Workers (Wrangler ^4.0.0) - Serves zone data from R2/D1

**Testing:**
- `flutter_test` (SDK built-in) - Unit and widget tests
- `riverpod_test` ^0.1.9 - Riverpod provider testing
- `mockito` ^5.4.6 + `mocktail` ^1.0.4 - Mocking
- `sqflite_common_ffi` ^2.3.0 - SQLite testing on desktop/CI
- Vitest ^4.0.18 - Cloudflare Worker tests

**Build/Dev:**
- `build_runner` ^2.4.15 - Code generation runner
- `json_serializable` ^6.9.4 - JSON serialization codegen
- `riverpod_generator` ^2.6.4 - Riverpod provider codegen
- `freezed` ^3.0.6 - Immutable data class codegen
- `hive_ce_generator` ^1.9.1 - Hive type adapter codegen
- `custom_lint` ^0.7.5 + `riverpod_lint` ^2.6.4 - Custom lint rules

## Key Dependencies

**Critical:**
- `sweph` ^3.2.1+2.10.3 - Swiss Ephemeris bindings for astronomical calculations (planet/star positions)
- `h3_flutter` ^0.7.1 - Uber H3 geospatial indexing for light pollution zone lookups
- `geolocator` ^14.0.2 - Device GPS location with permission handling
- `hive_ce` ^2.11.1 + `hive_ce_flutter` ^2.3.0 - Primary local cache (weather, zones, locations, prefs)
- `sqflite` ^2.4.1 - Local SQLite for bundled star/DSO catalog (`assets/db/`)
- `workmanager` ^0.9.0 - Background sync scheduling (Android WorkManager / iOS BGTaskScheduler)
- `fpdart` ^1.1.0 - Functional programming types (`Either`, `Option`) for error handling

**UI/Animation:**
- `rive` ^0.13.20 - Rive animations
- `flutter_animate` ^4.5.2 - Animation helpers
- `lottie` ^3.1.0 - Lottie animations
- `flex_color_scheme` ^8.0.2 - Theming
- `google_fonts` ^6.2.1 - Google Fonts
- `flutter_svg` ^2.0.10 - SVG rendering for constellation/celestial icons
- `gap` ^3.0.1 - Spacing widget

**Localization:**
- `easy_localization` ^3.0.7 - i18n (English + Turkish supported)
- `intl` ^0.20.2 - Date/number formatting

**Utilities:**
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

**Backend Python:**
- `pymongo` 4.6.0 - MongoDB client
- `python-dotenv` 1.0.0 - Environment variable loading
- `dnspython` 2.6.1 - DNS resolution for MongoDB SRV URIs

## Configuration

**Environment:**
- Flutter: Build-time environment injection via `--dart-define=API_KEY=...`
- Backend: `.env` file loaded via `python-dotenv` (not committed)
- Required backend env var: `MONGODB_URI`

**Build:**
- `build.sh` - Flutter web build script invoked by Vercel
- `analysis_options.yaml` - Dart analyzer config
- `lint_rules.yaml` - Custom lint rule definitions
- `devtools_options.yaml` - Flutter DevTools settings

**Code Generation:**
- Run `flutter pub run build_runner build` to regenerate `.g.dart` and `.freezed.dart` files

## Platform Requirements

**Development:**
- Flutter SDK (Dart >=3.0.5)
- Android Studio / Xcode for native targets
- Node.js + Wrangler CLI for Cloudflare Worker development
- Python 3.x + pip for backend development

**Production:**
- Flutter app: Android (minSdk 21), iOS, Web
- Backend API: Vercel (Python serverless)
- Web app: Vercel (Flutter web, custom `build.sh`)
- Zone data: Cloudflare Workers + R2 + D1

---

*Stack analysis: 2026-06-13*
