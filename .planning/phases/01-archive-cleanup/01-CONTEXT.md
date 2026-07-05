# Phase 1: Archive & Cleanup - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Clear all dead backends, legacy screens, and obsolete pipeline scripts from the active `lib/` tree — isolating them into `archive/` with clear documentation. The active codebase must compile cleanly with no dangling imports after each move. This phase has zero UI work; it is purely structural cleanup so Phase 3 (UI redesign) starts from a clean slate.

</domain>

<decisions>
## Implementation Decisions

### Dead Code Audit Scope
- **D-01:** Perform a **full lib/ audit** — walk every `lib/features/*` module (astronomy, catalog, context, dashboard, data_layer, forecast, planner, profile, splash) looking for dead screens, unreachable providers, orphaned widgets, and unused services.
- **D-02:** The bar for "dead" is **unused + no future plan**. Code that is unreachable from the active GoRouter AND not scheduled for a future phase goes to `archive/`. Borderline items that will be rebuilt in Phase 3+ (e.g. a catalog widget that's being redesigned) stay in place.
- **D-03:** Confirmed dead items to archive regardless of audit: `backend/` (MongoDB/Flask), `api/` (Python/Vercel serverless), `lib/features/planner/` (entire feature), and the duplicate forecast screen inside `planner/`.
- **D-04:** After each archive move, **remove all dangling refs**: imports, dead routes in `app_router.dart`, orphaned provider registrations. The active codebase must stay `flutter analyze`-clean after each move — not just free of compile errors.

### Archive Folder Structure
- **D-05:** `archive/backend/` for the MongoDB/Flask app (`backend/` folder contents).
- **D-06:** `archive/api/` for the Python/Vercel serverless function (`api/` folder contents — `index.py`, `requirements.txt`, `vercel.json`).
- **D-07:** `archive/data-pipeline/` for the zone generation pipeline scripts (`scripts/*.py`, `backend/*.py` duplicates, `scripts/*.sh`, `scripts/requirements.txt`, any supporting data files).
- **D-08:** `archive/INDEX.md` at the root maps every subfolder: what it contained, why it was archived, and what replaced it (ARCH-06).

### scripts/ Treatment
- **D-09:** The `scripts/` folder **stays in place** — it contains both pipeline scripts AND validation scripts (validate_zones_db.py, validate_zones_extended.py) that Phase 2 (Zone Data Validation) will need. Phase 1 does not touch `scripts/`. Pipeline scripts in `scripts/` are documented in `archive/data-pipeline/` but not moved.

### Data Pipeline Documentation
- **D-10:** ARCH-04 requires a **full reproduction guide** in `archive/data-pipeline/README.md` covering: environment setup (Python version, dependencies, GDAL), data sources (VNL NPP 2024 Global Masked Data TIF — where to obtain it), exact commands in order, expected intermediate outputs, skyglow diffusion parameters and tuning decisions, and final output format (SQLite schema + R2 upload). Enough for someone to actually rerun the pipeline from scratch.

### Root-Level Artifact Files
- **D-11:** `zones_accumulator.db` (1.3GB zone SQLite DB) — add to `.gitignore`, keep the file locally. Document its location and how to regenerate it in `archive/data-pipeline/README.md`. Phase 2 (Zone Data Validation) will use this local copy for validation.
- **D-12:** `test_failures.log`, `GetStorage.bak`, `GetStorage.gs` — **delete all three** and add their patterns to `.gitignore` so they can't be accidentally committed.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` §Archive & Cleanup — ARCH-01 through ARCH-06 are the requirements for this phase. Read these to understand exactly what "done" means.
- `.planning/ROADMAP.md` §Phase 1 — Success criteria and phase goal.

### Project Context
- `.planning/PROJECT.md` §Context — Describes the codebase state and which backends/architectures are dead vs. active. Critical for understanding what "active path" means.
- `.planning/PROJECT.md` §Out of Scope — MongoDB backend revival, web platform target are explicitly out of scope.

### Codebase Maps
- `.planning/codebase/STRUCTURE.md` — Directory layout and purpose of every folder. Reference when deciding where archived items live and what stays active.
- `.planning/codebase/ARCHITECTURE.md` — Active component map. Anything NOT in this map is a candidate for archiving.

</canonical_refs>

<code_context>
## Existing Code Insights

### Known Dead Items (Confirmed)
- `backend/` — MongoDB/Flask app with Python, pymongo, Flask 3.0.0, venv, requirements.txt. Replaced by Cloudflare + Open-Meteo.
- `api/` — Python/Vercel serverless function (`api/index.py`). Dead alongside the Flask backend.
- `lib/features/planner/` — Observation planning feature. Not in router, not referenced by active providers.
- Duplicate forecast screen inside `lib/features/planner/presentation/screens/forecast_screen.dart` (separate from the active `lib/features/forecast/`).
- `backend/*.py` — Pipeline script duplicates that also exist in `scripts/`.

### Active Path (Do Not Archive)
- `cloudflare/` — Active Cloudflare Worker serving zone data from R2/D1. DO NOT touch.
- `lib/features/dashboard/` — Active home dashboard. Stays.
- `lib/features/astronomy/` — Active astronomical calculations. Stays.
- `lib/features/data_layer/` — Active H3 zone lookup. Stays.
- `lib/features/forecast/` — Active forecast screen (minus the duplicate in planner/). Stays.
- `lib/features/profile/` — Active saved locations / settings. Stays.
- `lib/features/splash/` — Active init flow. Stays.
- `lib/features/context/` — Active geocoding + location context. Stays.
- `scripts/` — Stays in place; contains validators needed for Phase 2.

### Established Patterns
- GoRouter in `lib/app/router/app_router.dart` is the source of truth for reachable screens. If a screen has no route entry, it's unreachable.
- Riverpod providers wired in feature `index.dart` barrels — check barrel exports to identify dead providers.
- `flutter analyze` is the cleanup verification tool — phase must produce zero analyzer errors after archiving.

### Integration Points
- `.gitignore` needs new entries: `zones_accumulator.db`, `test_failures.log`, `GetStorage.bak`, `GetStorage.gs` (and `*.gs` / `*.bak` if appropriate).
- `archive/INDEX.md` is a new top-level file — doesn't conflict with anything existing.

</code_context>

<specifics>
## Specific Ideas

- `zones_accumulator.db` is 1.3GB and lives at the repo root — too large for git. Its location and regeneration steps must be documented in `archive/data-pipeline/README.md` so Phase 2 knows it exists and where to find it.
- The `backend/` folder contains script duplicates of `scripts/*.py` — the pipeline docs should note this and point to `scripts/` as the canonical source.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 1-Archive & Cleanup*
*Context gathered: 2026-06-13*
