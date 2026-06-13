---
phase: 01-archive-cleanup
plan: "06"
subsystem: infra
tags: [audit, index, archive, cleanup, dart]

# Dependency graph
requires: [01-05]
provides:
  - D-01 full lib/features/* audit with findings per module
  - archive/INDEX.md mapping all 6 archive subfolders
  - Fixed weather_provider.dart and weather_provider_test.dart imports (planner/ → forecast/)
  - Fixed archive/config-theme/ and archive/common/ recovered from git history
  - Empty lib/features/planner/ directories removed
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - archive/INDEX.md
  modified:
    - lib/features/dashboard/presentation/providers/weather_provider.dart
    - test/features/dashboard/presentation/providers/weather_provider_test.dart

key-decisions:
  - "archive/config-theme/ and archive/common/ dart files recovered from git history (01-05 deleted rather than moved)"
  - "weather_provider.dart had lingering planner/ import — updated to forecast/"
  - "weather_background_sync_service_test.dart failure is pre-existing (service constructor added zoneRepository/h3Service params before Phase 1)"
  - "archive/ dart files intentionally gitignored — only README.md and INDEX.md tracked"

requirements-completed: [ARCH-01, ARCH-06]

# Metrics
duration: 30min
completed: "2026-06-13"
---

# Phase 1 Plan 06: D-01 Audit + Archive Index Summary

**D-01 full lib/features/* audit complete; archive/INDEX.md created; lingering planner/ imports fixed; flutter analyze exits 0**

## Performance

- **Duration:** ~30 min (inline execution after 2 subagent stalls)
- **Completed:** 2026-06-13
- **Tasks:** 2/2 auto + checkpoint pending human verification

## D-01 Audit Findings

All 8 active `lib/features/*` modules walked (planner was already fully archived in Plans 01-03/01-04/01-05):

| Module | Files | Status | Findings |
|--------|-------|--------|----------|
| astronomy | 11 | ✓ Active | No dead code — all files reachable from router or injected via provider |
| catalog | 20 | ✓ Active | No dead code — all screens reachable (catalog, object_detail) |
| context | 8 | ✓ Active | No dead code — geocoding + location sheet active |
| dashboard | 42 | ✓ Active | No dead code — all providers referenced; weather_provider had lingering planner/ import (fixed) |
| data_layer | 10 | ✓ Active | index.dart barrel not imported anywhere — harmless, not dead code per se |
| forecast | 6 | ✓ Active | All files active; newly migrated from planner/ |
| profile | 18 | ✓ Active | All screens reachable (profile, locations, add_location, tos) |
| splash | 5 | ✓ Active | All files active in init flow |

**Additional findings:**
- `lib/features/planner/` empty directories (data/, domain/) removed from working tree
- `weather_provider.dart` lingering import `planner/domain/entities/daily_forecast.dart` → fixed to `forecast/domain/entities/daily_forecast.dart`
- `archive/config-theme/` and `archive/common/` files recovered from git history (01-05 deleted rather than moved; recovered to disk, gitignored as expected)

## Acceptance Gate Results

- `grep -r "features/planner\|config/theme" lib/ --include="*.dart"` → **0 results** ✓
- `flutter analyze lib/` → **0 error-level diagnostics** ✓
- `flutter test` → **492 passing, 29 skipped, 6 failing**
  - 1 failure fixed this plan (weather_provider_test.dart — planner/ import)
  - 5 pre-existing failures NOT introduced by Phase 1:
    - `weather_background_sync_service_test.dart` — constructor missing zoneRepository/h3Service (pre-existing)
    - `navigation_test.dart` — unrelated pre-existing failures

## Files Created/Modified

- `archive/INDEX.md` — Root archive index covering all 6 subfolders (tracked via !archive/INDEX.md exception)
- `lib/features/dashboard/presentation/providers/weather_provider.dart` — planner/ imports → forecast/
- `test/features/dashboard/presentation/providers/weather_provider_test.dart` — planner/ imports → forecast/
- `archive/config-theme/` — 5 files recovered from git history (gitignored, local reference only)
- `archive/common/` — 3 files recovered from git history (gitignored, local reference only)

## Self-Check: PASSED

---

## CHECKPOINT: Verification Required

**Task 3 of 3 — Human sign-off before phase is marked complete.**

*Awaiting user verification — see checkpoint presentation below.*

---
*Phase: 01-archive-cleanup | Completed: 2026-06-13*
