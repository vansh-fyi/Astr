# Archive Index

This directory preserves code and infrastructure from Astr's development and ideation cycles that is no longer part of the active production codebase. All items were archived during Phase 1 (2026-06-13).

**Active production code lives in:**
- `lib/` — Flutter/Dart app
- `cloudflare/` — Cloudflare Worker serving zone data from R2/D1
- `scripts/` — VNL NPP 2024 zone generation pipeline scripts

Nothing in this directory is imported by or required for the running app.

---

## Contents

| Folder | What it was | Replaced by |
|--------|-------------|-------------|
| `backend/` | MongoDB/Flask API server | Cloudflare Workers + R2/D1 |
| `api/` | Python/Vercel serverless function | Cloudflare Worker |
| `data-pipeline/` | Zone generation pipeline documentation | See `README.md` — scripts remain in `scripts/` |
| `planner/` | Observation planner feature | `lib/features/forecast/` |
| `config-theme/` | Theme state management with Hive | `lib/app/theme/app_theme.dart` |
| `common/` | Dead shared widgets | Not replaced — never used in production |

---

## archive/backend/

**What it contained:** A Flask 3.0.0 + pymongo 4.6.0 Python server (`backend/`) that proxied MongoDB Atlas queries for light pollution data. It exposed `/api/light-pollution` as a Vercel serverless function entry point.

**Why it was archived:** The MongoDB Atlas approach was replaced before shipping. The app now fetches zone data from a Cloudflare Worker backed by R2 + D1, which is faster, cheaper, and requires no database credentials at runtime.

**What replaced it:** `cloudflare/worker.js` — a Cloudflare Worker that serves pre-computed H3 zone data from R2 binary files and D1 SQLite. See `cloudflare/wrangler.toml` for deployment config.

---

## archive/api/

**What it contained:** A single Python/Vercel serverless function (`api/index.py`, ~175 lines) that connected to MongoDB Atlas via pymongo and served light pollution data through the Flask routing layer in `backend/`.

**Why it was archived:** This was the Vercel-hosted entry point for the Flask backend. When the backend was replaced by the Cloudflare Worker, the `api/` proxy became dead.

**What replaced it:** The Cloudflare Worker at `cloudflare/worker.js` serves the same data directly from R2/D1 with no Python runtime required.

---

## archive/data-pipeline/

**What it contained:** Documentation for the zone generation pipeline. The actual scripts remain in `scripts/` — this folder is documentation only.

**Why it was archived:** The pipeline is a one-time (or periodic) operation, not part of the running app. The documentation is preserved here so the pipeline can be reproduced without reading the scripts.

**What replaced it:** Nothing — this is preserved reference documentation. See `archive/data-pipeline/README.md` for the full VNL NPP 2024 reproduction guide.

**Important:** `zones_accumulator.db` (at repo root, ~1.3 GB) is the pipeline output. It is gitignored but must not be deleted — it is required for Phase 2 zone validation.

---

## archive/planner/

**What it contained:** `lib/features/planner/` — an observation planning feature (9 source files + 6 test files) that included:
- `DailyForecast` entity, `PlannerLogic`, `IForecastRepository`, `ForecastRepository` (domain + data layer)
- `ForecastScreen` (two versions: pages/ and screens/), `ForecastListItem` widget, `PlannerProvider`

**Why it was archived:** The feature was an early prototype of the forecast/conditions display that was never fully integrated into the active router. Its domain and data layers were migrated to `lib/features/forecast/` with Forecast-namespaced identifiers (Plans 01-03 and 01-04). The presentation layer was rebuilt from scratch in `lib/features/forecast/presentation/`.

**What replaced it:** `lib/features/forecast/` — the fully-integrated forecast feature with its own domain layer, data layer, provider, and screen. The screen is accessible via the bottom nav bar.

---

## archive/config-theme/

**What it contained:** `lib/config/theme/` — Hive-backed theme state management:
- `ThemeUiModel` (Freezed entity with Hive adapter) — persisted theme selection
- `ThemeLogic` (Riverpod notifier) — read/write theme state from Hive
- Generated files: `theme_logic.g.dart`, `theme_ui_model.freezed.dart`, `theme_ui_model.g.dart`

**Why it was archived:** The app uses `ThemeMode.dark` hardcoded (`lib/app/theme/app_theme.dart`) — dark-only mode is a design decision for astronomy use. The dynamic theme-switching logic and its Hive adapter were never wired to the UI and had zero references in the active codebase.

**What replaced it:** `lib/app/theme/app_theme.dart` — static dark theme definition. No dynamic theme-switching needed.

---

## archive/common/

**What it contained:** Three dead shared widgets from `lib/common/`:
- `link_card.dart` — A card widget with a URL launcher tap handler (`LinkCard`)
- `app_bar_gone.dart` — A transparent/hidden AppBar implementation (`AppBarGone`)
- `grid_item.dart` — A grid cell widget with tap handler (`GridItem`)

**Why it was archived:** All three widgets had zero usages across the entire codebase (confirmed via grep before archiving). They were created during early UI exploration but never integrated into any screen.

**What replaced it:** Nothing — these widgets were never used in production. The active UI uses dashboard-specific widgets in `lib/features/dashboard/presentation/widgets/`.

---

*Archived: 2026-06-13 | Phase: 01-archive-cleanup*
