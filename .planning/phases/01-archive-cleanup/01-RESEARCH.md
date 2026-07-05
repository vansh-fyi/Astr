# Phase 1: Archive & Cleanup - Research

**Researched:** 2026-06-13
**Domain:** Flutter/Dart codebase cleanup, dead code archiving, .gitignore hygiene
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Full `lib/` audit — walk every `lib/features/*` module looking for dead screens, unreachable providers, orphaned widgets, and unused services.
- **D-02:** Bar for "dead" is **unused + no future plan**. Unreachable from GoRouter AND not scheduled for a future phase → archive. Borderline items that will be rebuilt in Phase 3+ stay in place.
- **D-03:** Confirmed dead items to archive regardless of audit: `backend/` (MongoDB/Flask), `api/` (Python/Vercel serverless), `lib/features/planner/` (entire feature), and the duplicate forecast screen inside `planner/`.
- **D-04:** After each archive move, remove all dangling refs: imports, dead routes in `app_router.dart`, orphaned provider registrations. The active codebase must stay `flutter analyze`-clean after each move.
- **D-05:** `archive/backend/` for the MongoDB/Flask app.
- **D-06:** `archive/api/` for the Python/Vercel serverless function.
- **D-07:** `archive/data-pipeline/` for the zone generation pipeline scripts (`scripts/*.py`, `backend/*.py` duplicates, `scripts/*.sh`, `scripts/requirements.txt`, supporting data files). Documents them without moving `scripts/`.
- **D-08:** `archive/INDEX.md` maps every subfolder: what it contained, why archived, what replaced it.
- **D-09:** `scripts/` folder **stays in place** — contains both pipeline AND validation scripts needed by Phase 2.
- **D-10:** ARCH-04 requires a full reproduction guide in `archive/data-pipeline/README.md` covering environment setup, data sources, exact commands, expected outputs, skyglow diffusion parameters, and output format.
- **D-11:** `zones_accumulator.db` (1.3 GB) — add to `.gitignore`, keep locally. Document location and regeneration in `archive/data-pipeline/README.md`.
- **D-12:** `test_failures.log`, `GetStorage.bak`, `GetStorage.gs` — delete all and add patterns to `.gitignore`.

### Claude's Discretion

None — all decisions were locked during discussion.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ARCH-01 | Comprehensive dead code audit across entire codebase identifies all unused features, providers, widgets, screens, and backend code | See Dead Code Inventory section — full audit completed |
| ARCH-02 | MongoDB backend (`backend/` folder) moved to `archive/backend/` with README | See Archive Map — confirmed dead, no active references |
| ARCH-03 | Duplicate/unused forecast screens archived with reference documentation | See Forecast Screen Tangle section — 2 dead screens identified, router impact mapped |
| ARCH-04 | Skyglow diffusion data pipeline archived in `archive/data-pipeline/` with full documentation | See Data Pipeline Inventory section — current pipeline is VNL-based with skyglow; reproduction guide requirements documented |
| ARCH-05 | All other dead features, providers, widgets, services archived with per-folder README references | See Dead Code Inventory — config/theme legacy, common/ widgets, planner tests |
| ARCH-06 | `archive/INDEX.md` maps each subfolder to what it contains, why archived, what replaced it | See Archive Map section |
</phase_requirements>

---

## Summary

Phase 1 is a pure structural cleanup phase with zero UI work. The codebase accumulated dead code through multiple ideation cycles: a MongoDB/Flask backend replaced by Cloudflare Workers, a Python/Vercel serverless API, a `planner` feature that was never wired into the active router (except for one screen that was used), and a `forecast` feature that is only a stub. The active data path is entirely Cloudflare + Open-Meteo + Hive CE — everything else is dead.

The research reveals one critical nuance the CONTEXT.md decisions imply: `lib/features/planner/` is flagged as entirely dead, yet the router currently imports `lib/features/planner/presentation/pages/forecast_screen.dart` as the active `/forecast` route. This means archiving `planner/` requires updating the router import to point to `lib/features/forecast/presentation/forecast_screen.dart` — which currently contains only a stub. The stub must receive the working forecast screen content before planner is archived, or the router import must be updated to a newly-placed copy in `lib/features/forecast/`. This is the most critical sequencing constraint for the phase.

The data pipeline documentation task (ARCH-04) is substantial: the active pipeline is `scripts/generate_zones_vnl.py` + `scripts/apply_skyglow.py` (VNL NPP 2024 TIF-based, not the VIIRS HDF5 pipeline documented in `scripts/README.md`). The `scripts/README.md` documents a different, older pipeline architecture. `archive/data-pipeline/README.md` must accurately document the CURRENT VNL pipeline, not the VIIRS one.

**Primary recommendation:** Execute archive tasks in dependency order — data-pipeline docs first, then backend/api move, then planner/forecast screen migration, then gitignore fixes, then INDEX.md. Run `flutter analyze` after each Dart-touching step to verify zero new errors.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Archive folder creation | File system | — | OS-level directory operations, no Flutter involvement |
| Router import update | Frontend (Flutter) | — | GoRouter config in `lib/app/router/app_router.dart` owns all route-to-screen wiring |
| .gitignore hygiene | File system / git | — | Git-layer concern, no app code |
| Archive documentation | Documentation | — | Markdown authoring, no code execution |
| `flutter analyze` gate | Dart analyzer | — | Dart static analysis, validates the Flutter layer after each change |

---

## Dead Code Inventory

> Full audit result. Every item below was verified by tracing references in the active codebase. [VERIFIED: grep audit of lib/, router, and hive adapters]

### Confirmed Dead — Archive

| Item | Path | Reason Dead | Archive Destination |
|------|------|-------------|---------------------|
| MongoDB/Flask backend | `backend/` (entire folder) | Replaced by Cloudflare Workers + Open-Meteo. No `lib/` code references it. | `archive/backend/` |
| Python/Vercel API | `api/` (entire folder: `index.py`, `__init__.py`, `__pycache__/`, `test_api.py`, `test_bortle.py`, `test_bortle_isolated.py`, `test_process_data.py`) | Dead alongside Flask backend. Uses pymongo + Flask. | `archive/api/` |
| `lib/features/planner/` (except pages/forecast) | All files except `presentation/pages/forecast_screen.dart` and its dependencies | No route entry in GoRouter. Providers, domain entities, screens all unreachable. | `archive/planner/` (after migrating active forecast screen) |
| `lib/features/forecast/presentation/forecast_screen.dart` | `lib/features/forecast/presentation/forecast_screen.dart` | Stub class — contains placeholder text "Forecast Screen" only. Not imported by router (router imports planner version). | Replace with working content (migrate from planner) — do NOT archive as file, but the stub content is dead |
| `lib/features/planner/presentation/screens/forecast_screen.dart` | Orphaned duplicate | Not imported by router (router uses pages/ not screens/). Dead within the already-dead planner module. | Goes to archive as part of `archive/planner/` |
| `test/features/planner/` (all tests) | `test/features/planner/` | Tests for dead planner feature. | Archive alongside `archive/planner/` |
| `lib/config/theme/` | `theme_logic.dart`, `theme_ui_model.dart`, and generated `.g.dart`/`.freezed.dart` files | ThemeUiModel has a Hive adapter registered in `lib/hive/hive_adapters.dart` but is never read from or written to any Hive box in active code. No active code imports `config/theme/` except the hive adapter registration itself. | Archive (and clean up hive_adapters.dart to remove the spec) |

### Confirmed Dead — Delete (not archive)

| Item | Path | Action |
|------|------|--------|
| `test_failures.log` | `test_failures.log` | Delete |
| `test_failures_2.log` through `test_failures_6.log` | `test_failures_*.log` | Delete (6 files total) |
| `GetStorage.bak` | `GetStorage.bak` | Delete |
| `GetStorage.gs` | `GetStorage.gs` | Delete |

### Stays In Place (Not Dead)

| Item | Path | Reason Active |
|------|------|---------------|
| `lib/features/planner/presentation/pages/forecast_screen.dart` | ACTIVE (currently) | Imported by router as `/forecast` route. MUST be migrated to `lib/features/forecast/` before archiving planner/ |
| `lib/features/planner/presentation/providers/planner_provider.dart` | ACTIVE (currently) | Imported by the active forecast_screen.dart. MUST be migrated or refactored before archiving |
| `cloudflare/` | DO NOT TOUCH | Active Cloudflare Worker serving zone data from R2/D1 |
| `scripts/` | DO NOT TOUCH | Contains both pipeline scripts AND validators needed for Phase 2 |
| `lib/features/dashboard/`, `astronomy/`, `data_layer/`, `profile/`, `splash/`, `context/`, `catalog/` | ACTIVE | All routed and referenced |
| `lib/common/link_card.dart`, `app_bar_gone.dart`, `grid_item.dart` | BORDERLINE | No active imports found — may be dead. Include in audit during planning; flag for archive if unimported. |

---

## The Forecast Screen Tangle (Critical Sequencing Issue)

This is the most important discovery from the codebase audit. Understanding it is essential for correct planning.

**Current state:**

```
lib/app/router/app_router.dart
  └─ imports ──> lib/features/planner/presentation/pages/forecast_screen.dart  [ACTIVE /forecast route]
                   └─ imports ──> lib/features/planner/presentation/providers/planner_provider.dart
                                    └─ imports ──> lib/features/planner/domain/entities/daily_forecast.dart
                                                   lib/features/planner/domain/logic/planner_logic.dart
                                                   lib/features/planner/data/repositories/planner_repository.dart

lib/features/forecast/presentation/forecast_screen.dart  [STUB — "Forecast Screen" text only, NOT routed]

lib/features/planner/presentation/screens/forecast_screen.dart  [DEAD — not routed, within dead planner/]
```

**Decision D-03 says:** Archive `lib/features/planner/` entirely.

**What this means for the plan:**

Step A: Before archiving `planner/`, the active `planner/pages/forecast_screen.dart` content AND `planner_provider.dart` must be moved into `lib/features/forecast/` (promotion, not copy-and-delete). [ASSUMED: this is the correct interpretation — the planner confirms "entire feature" archived, meaning the live forecast code must first be relocated to its proper home]

Step B: Update `lib/app/router/app_router.dart` to import from `lib/features/forecast/presentation/forecast_screen.dart` instead of `planner/pages/`.

Step C: Verify `flutter analyze` passes (zero errors).

Step D: Archive the now-empty `lib/features/planner/` folder.

**Alternative interpretation (lower-effort):** Archive the planner/screens/ dead screen only, leave planner/pages/ and planner_provider active-in-place, and archive the stub lib/features/forecast/. This contradicts D-03 ("entire feature") but produces a working result. The planner must choose; research recommends the full migration for codebase clarity.

---

## Data Pipeline Inventory

> This section informs ARCH-04 documentation requirements. [VERIFIED: grep audit + file content inspection]

### Active Pipeline (VNL NPP 2024 — Current Production)

The CURRENT production pipeline uses the Colorado School of Mines VNL (VIIRS Nighttime Lights) Annual Composite TIF, not the VIIRS HDF5 tiles pipeline documented in `scripts/README.md`. These are different pipelines.

**Active scripts in `scripts/` (must be documented in archive/data-pipeline/README.md):**

| Script | Purpose |
|--------|---------|
| `generate_zones_vnl.py` | Reads VNL NPP 2024 TIF.gz via rasterio, accumulates H3 index → radiance in SQLite (`zones_accumulator.db`), outputs binary `zones.db`. Memory-safe + resumable. |
| `apply_skyglow.py` | Takes `zones_accumulator.db`, applies Garstang-inspired atmospheric scatter (skyglow diffusion) with exponential decay model. Outputs enhanced `zones.db`. |
| `export_zones_to_sql.py` | Exports zone data to SQL format for Cloudflare D1 upload. |
| `upload_to_r2.py` | Uploads `zones.db` to Cloudflare R2. |
| `inspect_db.py`, `inspect_h3.py`, `debug_vnl_reading.py` | Development/debugging utilities. |
| `validate_zones_db.py`, `validate_zones_extended.py` | Validators — used by Phase 2. DO NOT MOVE. |
| `validate_global_coverage.py` | Validation utility. DO NOT MOVE. |
| `test_h3_int.py` | H3 integer conversion test. |
| `generate_city_db.dart` | Dart script for city database generation. |
| `run_etl_loop.sh` | Shell script to run full ETL pipeline. |
| `setup_d1.sh` | D1 setup script. |

**Key input:** `VNL NPP 2024 Global Masked Data.tif.gz` — at repo root (1+ GB, already gitignored).

**Key intermediate artifact:** `zones_accumulator.db` — at repo root (1.3 GB, currently NOT in .gitignore under its correct name; see gitignore issue below).

**Skyglow diffusion parameters (to document in README):**
From `apply_skyglow.py`: Garstang-inspired model: `scatter(d) = fraction * exp(-d/scale) / (1 + (d/d0)^power)`. Requires scipy. Parameters encoded in script.

### Dead/Archived Pipeline Scripts (in `backend/scripts/`)

| Script | Purpose | Status |
|--------|---------|--------|
| `backend/scripts/check_mongo_count.py` | Checks MongoDB record count | Dead — MongoDB backend is archived |
| `backend/scripts/download_nasa_data.py` | Downloads NASA data for old pipeline | Dead — superseded by VNL pipeline |
| `backend/scripts/process_nasa_data.py` | Processes NASA HDF5 data for old pipeline | Dead — superseded by VNL pipeline |

These go to `archive/data-pipeline/` as part of `archive/backend/`.

### Confusion Alert: scripts/README.md Documents the Wrong Pipeline

The `scripts/README.md` describes the VIIRS HDF5 / NASA LAADS DAAC pipeline (`generate_h3_db_v2.py`, `generate_h3_db.py`). These scripts are NOT in `scripts/` — they appear to have been superseded by the VNL pipeline. The `archive/data-pipeline/README.md` must document the CURRENT VNL-based pipeline from scratch, not repurpose the `scripts/README.md` content. [VERIFIED: file inspection of scripts/generate_zones_vnl.py and apply_skyglow.py]

---

## .gitignore Issues Found

> [VERIFIED: .gitignore content inspection + `ls -la` of root files]

| Issue | Current .gitignore Entry | Actual Filename | Fix Needed |
|-------|-------------------------|-----------------|------------|
| Wrong name for zone DB | `zone_accumulator.db` (no 's') | `zones_accumulator.db` (with 's') | Add `zones_accumulator.db` |
| test_failures logs | `test_output*.txt` (wrong pattern) | `test_failures.log`, `test_failures_2.log` ... `test_failures_6.log` | Add `test_failures*.log` |
| GetStorage files | Missing | `GetStorage.bak`, `GetStorage.gs` | Add `GetStorage.bak`, `GetStorage.gs` (or `*.bak`, `*.gs`) |
| archive/ already ignored | `archive/` | `archive/` already in .gitignore | No change needed — archive is already gitignored |

Note: `archive/` is already in `.gitignore` (line 128). This means all archive contents are pre-excluded from git tracking.

---

## Archive Map (for archive/INDEX.md)

| Archive Subfolder | Original Location | What It Was | Why Archived | What Replaced It |
|-------------------|-------------------|-------------|--------------|-----------------|
| `archive/backend/` | `backend/` | MongoDB/Flask API with pymongo, REST endpoints for light pollution data | Architecture replaced by Cloudflare Workers + R2/D1 + Open-Meteo | Cloudflare Worker in `cloudflare/` + Open-Meteo HTTP |
| `archive/api/` | `api/` | Python/Vercel serverless function (`index.py`) — MongoDB proxy | Dead alongside Flask backend; Vercel deployment replaced by Cloudflare edge | Cloudflare Worker |
| `archive/data-pipeline/` | `scripts/*.py` (pipeline scripts only), `backend/scripts/` | VNL + VIIRS data processing pipeline to generate `zones.db` | One-time run completed; output deployed to R2. Scripts preserved for reference/rerun. | Production `zones.db` in R2/D1; validators remain in `scripts/` for Phase 2 |
| `archive/planner/` | `lib/features/planner/` | Observation planning feature with 7-day forecast UI, planner logic | Feature was never fully launched; forecast UI migrated to `lib/features/forecast/` | `lib/features/forecast/presentation/forecast_screen.dart` (migrated content) |

---

## Architecture Patterns

### Archive Folder Layout

```
archive/
├── INDEX.md                    # Root index — maps all subfolders
├── backend/                    # MongoDB/Flask app
│   ├── README.md               # What it was, why archived, what replaced it
│   └── [contents of backend/]
├── api/                        # Python/Vercel serverless
│   ├── README.md               # What it was, why archived
│   └── [contents of api/]
├── data-pipeline/              # Pipeline scripts + docs
│   ├── README.md               # Full reproduction guide (ARCH-04)
│   ├── [pipeline scripts from backend/scripts/ - MongoDB-era]
│   └── [copy of scripts that are pipeline-only, not validators]
└── planner/                    # Dead planner feature
    ├── README.md               # What it was, why archived
    └── [contents of lib/features/planner/ after forecast migration]
```

### archive/data-pipeline/README.md Must Cover (ARCH-04)

Per decision D-10, the reproduction guide must include:

1. **Environment setup:** Python version (3.x), required packages (`rasterio`, `h3>=4.0.0`, `numpy`, `scipy`, `gdal` via rasterio), venv setup commands
2. **Data source:** VNL NPP 2024 Global Masked Data TIF — Colorado School of Mines / Earth Observation Group at `https://eogdata.mines.edu/products/vnl/`. File: `VNL NPP 2024 Global Masked Data.tif.gz` (large, gitignored). Note difference from NASA VIIRS HDF5 pipeline (different source).
3. **Exact commands in order:**
   - Step 1: `python scripts/generate_zones_vnl.py --tif "VNL NPP 2024 Global Masked Data.tif.gz"` → produces `zones_accumulator.db`
   - Step 2: `python scripts/apply_skyglow.py --tif "VNL NPP 2024 Global Masked Data.tif.gz"` → produces enhanced `zones.db`
   - Step 3: `python scripts/export_zones_to_sql.py` → SQL for D1
   - Step 4: `python scripts/upload_to_r2.py` → deploys to R2
4. **Expected intermediate outputs:** `zones_accumulator.db` (~1.3 GB SQLite at repo root), `assets/db/zones.db` (binary ~80 MB)
5. **Skyglow diffusion parameters:** Garstang model parameters in `apply_skyglow.py`
6. **Final output format:** Binary `zones.db` — 16-byte header (`ASTR` magic + version + record count) + 20-byte records (H3 index + Bortle + light_pollution_ratio + SQM + reserved)
7. **SHA-256 hash update:** After regeneration, update `BinaryReaderService.expectedZonesDbHash` in the Flutter app
8. **`zones_accumulator.db` location:** Repo root (gitignored); DO NOT delete — Phase 2 uses it for validation
9. **Note about `scripts/README.md`:** That file documents the older VIIRS HDF5 / NASA LAADS DAAC pipeline, which is a different approach. The VNL pipeline is the current production method.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Archive folder documentation | Custom format | Standard `README.md` in each archive subfolder + `INDEX.md` at root |
| Dart static analysis | Manual import hunting | `flutter analyze --no-pub` — the source of truth for dangling imports |
| File moves | Dart-aware tool | Simple `mv` + update import strings — Dart does not have a refactoring-safe move tool; imports must be manually updated |

**Key insight:** This phase produces no runnable code — it moves files and writes documentation. The verification tool is `flutter analyze`, not a test suite.

---

## Common Pitfalls

### Pitfall 1: Archiving planner/ before migrating the active forecast screen

**What goes wrong:** The router imports `lib/features/planner/presentation/pages/forecast_screen.dart`. If this file is moved/deleted before the router import is updated, `flutter analyze` immediately produces an unresolved-import error on `app_router.dart`.

**Why it happens:** `lib/features/planner/` is flagged "entirely dead" in D-03, but one screen in it is currently active (wired into the live router).

**How to avoid:** Migrate `planner/pages/forecast_screen.dart` and `planner_provider.dart` (+ domain entities it depends on) to `lib/features/forecast/` FIRST. Update router import. Run `flutter analyze`. Only then archive `planner/`.

**Warning signs:** Any `flutter analyze` error mentioning `app_router.dart` after a planner/ move.

### Pitfall 2: Documenting the wrong pipeline in archive/data-pipeline/README.md

**What goes wrong:** `scripts/README.md` describes the VIIRS HDF5 pipeline (NASA LAADS DAAC, `generate_h3_db_v2.py`). If the researcher copies from that file, the reproduction guide documents a pipeline that was superseded and whose scripts may not even be present.

**Why it happens:** `scripts/README.md` is the most prominent documentation but refers to an older approach.

**How to avoid:** Base `archive/data-pipeline/README.md` entirely on the actual scripts in `scripts/`: `generate_zones_vnl.py`, `apply_skyglow.py`, `export_zones_to_sql.py`, `upload_to_r2.py`. Read the docstrings in those files for accurate parameter info.

**Warning signs:** README mentions NASA LAADS DAAC, `generate_h3_db_v2.py`, or MODIS sinusoidal projection — these are VIIRS pipeline concepts, not VNL.

### Pitfall 3: zones_accumulator.db gitignore mismatch

**What goes wrong:** The `.gitignore` has `zone_accumulator.db` (no 's'). The actual file is `zones_accumulator.db` (with 's'). It is currently untracked in git status (`??`) — if added accidentally, 1.3 GB gets committed.

**How to avoid:** Add the correct pattern `zones_accumulator.db` to `.gitignore` explicitly in an early task.

**Warning signs:** `git status` shows `zones_accumulator.db` as untracked (not ignored).

### Pitfall 4: ThemeUiModel Hive adapter causes regeneration issue

**What goes wrong:** `lib/config/theme/theme_ui_model.dart` is referenced in `lib/hive/hive_adapters.dart` via `@GenerateAdapters`. Archiving `config/theme/` without updating `hive_adapters.dart` breaks `build_runner` generation.

**How to avoid:** Remove the `AdapterSpec<ThemeUiModel>()` from `lib/hive/hive_adapters.dart` and delete the `import '../config/theme/theme_ui_model.dart'` line before (or immediately after) archiving `config/theme/`. Run `flutter analyze` to confirm clean.

**Warning signs:** `flutter analyze` shows "Target of URI doesn't exist: '../config/theme/theme_ui_model.dart'" in `lib/hive/hive_adapters.dart`.

### Pitfall 5: archive/ is gitignored — all archive content is excluded from git

**What goes wrong:** The `.gitignore` already contains `archive/` (line 128). This means archive documentation (README, INDEX.md) will never be committed to git.

**Why it matters:** ARCH-06 wants the index document committed. The archive content being gitignored is intentional (it can be large), but the documentation inside archive/ is NOT large and should be committed.

**How to avoid:** Add a `!archive/*.md` and `!archive/**/*.md` exception to `.gitignore` so README files inside archive/ are tracked by git. OR: move the documentation intent to `docs/archive/` which is not gitignored. The planner must decide; this is an explicit constraint to resolve.

**Warning signs:** `git status` shows `archive/INDEX.md` as ignored after creating it.

---

## Code Examples

### Checking analyze output (verification command)

```bash
# Run after each archive step that touches Dart files
flutter analyze --no-pub 2>&1 | grep -E "^   error|^   warning" | head -20
# Exit code 0 + zero error/warning lines = clean
```
[ASSUMED: `--no-pub` flag is correct for skipping pub get before analyzing]

### Updating a router import (pattern)

```dart
// Before (dead import to be removed):
import '../../features/planner/presentation/pages/forecast_screen.dart';

// After (migrated location):
import '../../features/forecast/presentation/forecast_screen.dart';
```
[VERIFIED: app_router.dart content — exact import string confirmed]

### Removing a Hive adapter spec

```dart
// lib/hive/hive_adapters.dart — remove ThemeUiModel entry:

// REMOVE this import:
// import '../config/theme/theme_ui_model.dart';

@GenerateAdapters(firstTypeId: 0,[
  // AdapterSpec<ThemeUiModel>(),   // REMOVE this line
])
part 'hive_adapters.g.dart';
```
[VERIFIED: hive_adapters.dart content inspection]

---

## Runtime State Inventory

> Included because this is a rename/refactor/move phase.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | `zones_accumulator.db` at repo root (1.3 GB SQLite) — contains zone accumulation data from VNL pipeline run | No migration needed — document its location in `archive/data-pipeline/README.md`; add to `.gitignore` |
| Stored data | Hive CE boxes in app's local storage — `ThemeUiModelAdapter` registered but no box actively uses ThemeUiModel | Remove adapter registration from `hive_adapters.dart`; no data migration needed (no box data exists for this type) |
| Live service config | `cloudflare/` Cloudflare Worker — NOT touched in this phase | None |
| OS-registered state | None found — no WorkManager tasks, launchd plists, or systemd units reference archived items | None |
| Secrets/env vars | `backend/.env` contains `MONGODB_URI` and `NASA_EARTHDATA_APP_KEY` — these go to archive with the backend | Archive with backend; no active code references them |
| Build artifacts | `lib/config/theme/*.g.dart`, `*.freezed.dart` (generated) — will become stale after archiving config/theme/ | Delete generated files alongside source when archiving |

---

## Validation Architecture

> nyquist_validation is enabled (not explicitly false in config.json).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (built-in SDK) |
| Config file | None (standard Flutter test runner) |
| Quick run command | `flutter test test/` |
| Full suite command | `flutter test test/ --coverage` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Notes |
|--------|----------|-----------|-------|
| ARCH-01 | Dead code audit complete | manual | No automated test for audit completeness |
| ARCH-02 | backend/ archived, no references remain | static analysis | `flutter analyze` + `grep -r "backend" lib/` |
| ARCH-03 | Duplicate forecast screens archived, router imports correct | static analysis | `flutter analyze --no-pub` must pass; router import grep |
| ARCH-04 | Pipeline README exists and covers required topics | manual | Human review of `archive/data-pipeline/README.md` |
| ARCH-05 | All dead features archived, no dangling imports | static analysis | `flutter analyze --no-pub` zero errors |
| ARCH-06 | `archive/INDEX.md` exists and covers all subfolders | manual | Human review |

**Primary verification:** `flutter analyze --no-pub` must produce zero errors after all archive moves. Existing info-level analyzer issues (1932 found) are pre-existing and acceptable; new errors from this phase are not.

### Wave 0 Gaps

None — this phase creates no new testable code. The verification gate is `flutter analyze`, not a test suite.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `flutter analyze` | ARCH-02, ARCH-03, ARCH-05 verification | Yes | Flutter 3.x (confirmed: runs in 5.7s) | None — required |
| `git` | .gitignore updates, file tracking | Yes | (standard) | None |
| `mv` / file system | Archive moves | Yes | macOS | None |

No missing dependencies.

---

## Security Domain

> security_enforcement is enabled (config.json has `"security_enforcement": true`).

### Applicable ASVS Categories

| ASVS Category | Applies | Rationale |
|---------------|---------|-----------|
| V2 Authentication | No | Phase moves files; no auth code added |
| V3 Session Management | No | No session code added |
| V4 Access Control | No | No ACL changes |
| V5 Input Validation | No | No new input processing |
| V6 Cryptography | No | No crypto code added |

### Security Considerations Specific to This Phase

- **backend/.env** contains `MONGODB_URI` and `NASA_EARTHDATA_APP_KEY`. When archiving `backend/`, this file moves with it. Verify it is listed in `backend/.gitignore` (it is — confirmed `backend/.gitignore` exists). The archive is also gitignored. No credential exposure risk. [VERIFIED: backend/.gitignore exists and archive/ is in root .gitignore]
- **zones_accumulator.db** contains zone/light-pollution data only, no PII or credentials. Safe to keep locally untracked.

---

## Open Questions

1. **archive/ gitignore exception for documentation files**
   - What we know: `archive/` is already gitignored (line 128 of .gitignore). All archive content is excluded from git.
   - What's unclear: Should `archive/INDEX.md` and `archive/*/README.md` be committed to git as reference documentation? ARCH-06 implies the index is important, suggesting it should be visible.
   - Recommendation: Add `.gitignore` exceptions: `!archive/INDEX.md` and `!archive/**/README.md`. This allows documentation to be committed while keeping large files (code, data) excluded. The planner must decide and include this as a task.

2. **lib/config/theme/ — is ThemeUiModel used anywhere via Hive at runtime?**
   - What we know: `hive_adapters.dart` registers `ThemeUiModelAdapter`. No active code was found that reads/writes a `ThemeUiModel` to a Hive box.
   - What's unclear: Could there be a legacy Hive box on user devices with ThemeUiModel data? If so, removing the adapter could cause a Hive type adapter crash on upgrade.
   - Recommendation: Since there's no active code writing ThemeUiModel to Hive, this is safe to remove. The adapter type ID (0) can be reclaimed. Note: Hive type IDs are only relevant if data was persisted — since the model was never actively used, no user devices should have persisted ThemeUiModel data. [ASSUMED: confirmed by grep showing no box reads/writes]

3. **lib/common/ widgets — are they used anywhere?**
   - What we know: `link_card.dart`, `app_bar_gone.dart`, `grid_item.dart` — no imports found via grep.
   - What's unclear: These might be used in test code or via dynamic import patterns.
   - Recommendation: Run `grep -r "LinkCard\|AppBarGone\|GridItem\|link_card\|app_bar_gone\|grid_item" lib/ test/` during planning. If zero results, add to ARCH-05 archive list.

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| MongoDB/Flask backend for zone data | Cloudflare Workers + R2/D1 | Backend/ is completely dead |
| Python/Vercel API proxy | Direct Cloudflare edge serving | api/ is completely dead |
| VIIRS HDF5 pipeline (NASA LAADS DAAC) | VNL NPP 2024 TIF pipeline (Colorado Mines EOG) | scripts/README.md documents old pipeline; archive/data-pipeline/README.md must document new |
| `planner` feature for forecast UI | Active forecast screen in planner/pages/ (to be migrated to forecast/) | planner/ is dead except for the screen being migrated |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `lib/features/planner/pages/forecast_screen.dart` content + dependencies should migrate to `lib/features/forecast/` before archiving planner | Forecast Screen Tangle | If wrong, router breaks (but flutter analyze catches it immediately) |
| A2 | ThemeUiModel has never been written to a Hive box in any released version — safe to remove without data migration | Dead Code Inventory | Low risk — no active code writes it; worst case is a handled Hive exception on old installs |
| A3 | `lib/common/` widgets (link_card, app_bar_gone, grid_item) are truly unused | Dead Code Inventory / Open Questions | If wrong, archiving them breaks an active screen — but flutter analyze catches it |
| A4 | `flutter analyze --no-pub` is the correct verify command | Code Examples | Minor — `--no-pub` just skips pub get; analyzer still runs |

---

## Sources

### Primary (HIGH confidence)

- Direct codebase inspection via grep and file reads — all findings verified against actual source files
- `lib/app/router/app_router.dart` — confirmed which screens are routed vs. dead
- `lib/hive/hive_adapters.dart` — confirmed ThemeUiModel registration
- `scripts/generate_zones_vnl.py`, `scripts/apply_skyglow.py` — confirmed VNL pipeline is the active one
- `.gitignore` line 128 — confirmed `archive/` is pre-excluded from git

### Secondary (MEDIUM confidence)

- `scripts/README.md` — describes VIIRS HDF5 pipeline (older approach, documents superseded methodology)

### Tertiary (LOW confidence)

- None

---

## Metadata

**Confidence breakdown:**
- Dead code inventory: HIGH — verified by grep + router tracing
- Archive structure: HIGH — directly matches CONTEXT.md decisions
- Data pipeline facts: HIGH — read from actual script docstrings
- Forecast screen tangle: HIGH — verified by reading both router and planner imports
- .gitignore gaps: HIGH — verified by reading .gitignore + `ls -la` of root files

**Research date:** 2026-06-13
**Valid until:** Stable — this is a point-in-time audit of a static codebase. Valid until Phase 1 work begins modifying the codebase.
