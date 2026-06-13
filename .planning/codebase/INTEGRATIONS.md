# External Integrations

**Analysis Date:** 2026-06-13

## APIs & External Services

**Weather:**
- Open-Meteo Forecast API - Hourly weather forecast (cloud cover, temperature, humidity, wind, weather code)
  - SDK/Client: `dio` via `OpenMeteoWeatherService` (`lib/features/dashboard/data/datasources/open_meteo_weather_service.dart`)
  - Base URL: `https://api.open-meteo.com/v1` (direct, keyless, no auth required)
  - Endpoint: `/forecast` with `hourly` params, up to 16 forecast days + 10 past days
  - Auth: None (open, non-commercial free tier)

**Geocoding (Forward):**
- Open-Meteo Geocoding API - Location name search
  - SDK/Client: `dio` via `GeocodingService` (`lib/features/context/data/datasources/geocoding_service.dart`)
  - Base URL: `https://geocoding-api.open-meteo.com/v1` (direct, keyless)
  - Endpoint: `/search` (name query → lat/lon list)
  - Auth: None

**Geocoding (Reverse):**
- OpenStreetMap Nominatim - Reverse geocoding (lat/lon → place name)
  - SDK/Client: `dio` with custom `User-Agent` header (`lib/features/context/data/datasources/geocoding_service.dart`)
  - URL: `https://nominatim.openstreetmap.org/reverse`
  - Auth: None (OSM public API; User-Agent header required by Nominatim policy)

**Light Pollution / Zone Data:**
- Astr Cloudflare Worker (self-hosted) - H3 zone light pollution lookups
  - SDK/Client: `http` package via `RemoteZoneService` (`lib/features/data_layer/services/remote_zone_service.dart`)
  - Base URL: `https://astr-zones.astr-vansh-fyi.workers.dev`
  - Endpoint: `/zone/{h3HexIndex}` → `{bortle, ratio, sqm}`
  - Auth: None (own worker)

**Cloudflare Proxy (Optional):**
- Astr Cloudflare Worker proxy for weather/geocoding (switched off by default)
  - Config: `ApiConfig.useProxy = false` (`lib/core/config/api_config.dart`)
  - Base URL: `https://astr-proxy.astr-vansh-fyi.workers.dev/api`
  - Endpoints: `/weather`, `/geocode`
  - Auth: None (own worker)

**Light Pollution (Backend - MPSAS):**
- Astr Python Backend API (self-hosted on Vercel) - Nearest MPSAS/Bortle from NASA data
  - Source: `backend/api/index.py`
  - Endpoints: `GET /api/light-pollution?lat=&lon=`, `GET /api/health`
  - Auth: None (public endpoint)

**Astronomy Calculations:**
- Swiss Ephemeris (embedded library) - Planet/star position calculations
  - SDK/Client: `sweph` ^3.2.1+2.10.3 (`lib/features/astronomy/data/repositories/astro_engine_impl.dart`)
  - Ephemeris files: `packages/sweph/assets/ephe/sepl_18.se1`, `semo_18.se1`, `seas_18.se1`
  - Auth: None (bundled binary data)

## Data Storage

**Databases:**

- Hive CE (local NoSQL) - Primary app cache
  - Client: `hive_ce` ^2.11.1 + `hive_ce_flutter`
  - Boxes used: `weatherCache` (WeatherCacheEntry), `zoneCache` (ZoneCacheEntry), `locations` (SavedLocation), `prefs` (String key-value)
  - Init: `lib/hive/hive.dart`, adapters in `lib/hive/hive_adapters.dart`

- SQLite (local relational) - Bundled star and DSO catalog
  - Client: `sqflite` ^2.4.1
  - Database file: `assets/db/` (bundled at build time)
  - Service: `lib/core/engine/database/database_service.dart`
  - Repositories: `lib/core/engine/database/star_repository.dart`, `lib/core/engine/database/dso_repository.dart`
  - Note: Web platform returns stub/failure — SQLite not supported on web

- MongoDB Atlas (cloud) - Light pollution MPSAS point data (backend only)
  - Client: `pymongo` 4.6.0 (`backend/api/index.py`)
  - Connection: `MONGODB_URI` env var (SRV URI format)
  - Database: `astr`, Collection: `light_pollution`
  - Geospatial index: 2dsphere for `$near` queries within 50km radius

- Cloudflare D1 (edge SQLite) - Zone lookups via Cloudflare Worker
  - Binding: `DB` (`cloudflare/wrangler.toml`, database_id: `d00b90d6-9117-4501-9ec8-5213d5ef334d`)
  - Accessed from `cloudflare/worker.js`

**File Storage:**
- Cloudflare R2 - Hosts `zones.db` binary for bulk download
  - Binding: `ZONE_BUCKET`, bucket: `astr-zones` (`cloudflare/wrangler.toml`)
  - Accessed from Cloudflare Worker

**Caching:**
- Hive CE boxes (local on-device) for weather and zone data caching
- `get_storage` for selected location persistence (`lib/features/context/presentation/providers/astr_context_provider.dart`)

## Authentication & Identity

**Auth Provider:**
- None - No user authentication system is present in the app
- The `lib/constants/endpoints.dart` references `reqres.in` (placeholder/testing only — not used in production flows)

## Analytics & Monitoring

**Session Recording / UX Analytics:**
- Microsoft Clarity - Session recording and heatmaps
  - SDK: `clarity_flutter` ^1.6.0
  - Init: `lib/main.dart` — wraps entire app in `ClarityWidget`
  - Project ID: `ujfp0i4u4p` (hardcoded in `lib/main.dart`)
  - Log level: `LogLevel.None` in release

**Error Tracking:**
- None (no Sentry, Crashlytics, or similar integrated)

**Logs:**
- `logger` ^2.5.0 for structured in-app logging
- `debugPrint` suppressed in release mode (`lib/main.dart`)
- Backend: `print(..., file=sys.stderr)` for server-side logging (visible in Vercel logs)

## Background Tasks

**Background Sync:**
- WorkManager (Android) / BGTaskScheduler (iOS) via `workmanager` ^0.9.0
  - Handler: `lib/core/platform/background_sync_handler.dart`
  - Task: Pre-fetches weather and zone data for saved locations

## CI/CD & Deployment

**Flutter Web App:**
- Hosting: Vercel
- Build: `build.sh` script, output: `build/web/`
- Config: `vercel.json` (root) — SPA rewrites, aggressive caching for `/assets/`

**Backend API:**
- Hosting: Vercel (Python serverless)
- Config: `backend/vercel.json` — routes all traffic to `api/index.py`

**Cloudflare Worker:**
- Platform: Cloudflare Workers
- Deploy: `wrangler deploy` from `cloudflare/`
- Config: `cloudflare/wrangler.toml`

## Webhooks & Callbacks

**Incoming:** None

**Outgoing:** None

## Environment Configuration

**Required env vars (backend):**
- `MONGODB_URI` - MongoDB Atlas connection string (SRV format)

**Flutter build-time env:**
- `API_KEY` - Injected via `--dart-define` (currently only used by placeholder `Endpoints` class; defaults to `reqres-free-v1`)

**Secrets location:**
- Backend: `.env` file (not committed; loaded by `python-dotenv`)
- Cloudflare secrets: managed via Wrangler / Cloudflare dashboard

---

*Integration audit: 2026-06-13*
