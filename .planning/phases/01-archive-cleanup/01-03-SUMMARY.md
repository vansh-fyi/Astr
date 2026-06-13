---
phase: 01-archive-cleanup
plan: "03"
subsystem: forecast
tags: [migration, forecast, domain-layer, planner, refactor, cleanup]

# Dependency graph
requires:
  - 01-01 (gitignore + backend archive)
  - 01-02 (api archive + pipeline docs)
provides:
  - lib/features/forecast/domain/entities/daily_forecast.dart
  - lib/features/forecast/domain/repositories/i_forecast_repository.dart
  - lib/features/forecast/domain/logic/forecast_logic.dart
  - lib/features/forecast/data/repositories/forecast_repository.dart
affects: [01-04, 01-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Migration pattern: copy planner domain files to forecast/ with Forecast-prefixed identifiers, preserve originals until full archive in Plan 05"
    - "Import depth invariant: lib/features/*/domain/logic/ and lib/features/*/data/repositories/ are equidistant from lib/ so cross-feature imports (../../../../) require no changes"

key-files:
  created:
    - lib/features/forecast/domain/entities/daily_forecast.dart
    - lib/features/forecast/domain/repositories/i_forecast_repository.dart
    - lib/features/forecast/domain/logic/forecast_logic.dart
    - lib/features/forecast/data/repositories/forecast_repository.dart
  modified: []

key-decisions:
  - "DailyForecast class name unchanged — already well-named entity; no rename needed"
  - "IPlannerRepository renamed to IForecastRepository; PlannerLogic to ForecastLogic; PlannerRepository to ForecastRepository"
  - "Planner originals preserved — still needed by active router/planner_provider until Plan 04 completes the presentation layer migration"
  - "info-level analyzer issues in new files are identical patterns to planner originals (always_specify_types on .cast<double>(), one_member_abstracts) — pre-existing pattern, not introduced by this plan"

requirements-completed: [ARCH-03, ARCH-05]

# Metrics
duration: 10min
completed: "2026-06-13"
---

# Phase 1 Plan 03: Forecast Domain Layer Migration Summary

**Planner domain entities, logic, and repository migrated to lib/features/forecast/ with Forecast-namespaced identifiers; flutter analyze confirms zero new errors**

## Performance

- **Duration:** ~10 min
- **Completed:** 2026-06-13T10:29:26Z
- **Tasks:** 2/2
- **Files created:** 4

## Accomplishments

- Created `lib/features/forecast/domain/entities/daily_forecast.dart` — verbatim copy from planner (class name unchanged; equatable-based value object)
- Created `lib/features/forecast/domain/repositories/i_forecast_repository.dart` — renamed from `IPlannerRepository` to `IForecastRepository`, updated `DailyForecast` import to new forecast location
- Created `lib/features/forecast/domain/logic/forecast_logic.dart` — renamed from `PlannerLogic` to `ForecastLogic`, all core cross-feature imports unchanged (same directory depth)
- Created `lib/features/forecast/data/repositories/forecast_repository.dart` — renamed from `PlannerRepository` to `ForecastRepository`, implements `IForecastRepository`, updated all intra-feature imports to reference new forecast/ paths
- `flutter analyze lib/features/forecast/` confirms 0 error-level diagnostics (5 info-level issues are identical patterns from the original planner source)
- `flutter analyze lib/` confirms 0 error-level diagnostics introduced by this plan (868 issues are all pre-existing)
- All four original planner domain/data files preserved for active router/provider until Plan 04

## Task Commits

1. **Task 1: Migrate DailyForecast entity and IForecastRepository to forecast/domain/** — `8416c17` (feat)
2. **Task 2: Migrate ForecastLogic and ForecastRepository to forecast/domain/ and forecast/data/** — `2e2a0a4` (feat)

## Files Created/Modified

- `lib/features/forecast/domain/entities/daily_forecast.dart` — `DailyForecast` entity (Equatable, 5 fields: date, cloudCoverAvg, moonIllumination, weatherCode, starRating; `isGoodNight` getter)
- `lib/features/forecast/domain/repositories/i_forecast_repository.dart` — `IForecastRepository` abstract class with single `get7DayForecast(GeoLocation, int)` method
- `lib/features/forecast/domain/logic/forecast_logic.dart` — `ForecastLogic` with `calculateStarRating()` using `QualitativeConditionService` + `BortleMpsasConverter`
- `lib/features/forecast/data/repositories/forecast_repository.dart` — `ForecastRepository implements IForecastRepository`, depends on `OpenMeteoWeatherService`, `IAstroEngine`, `ForecastLogic`

## Decisions Made

- Kept `DailyForecast` class name unchanged — it is a well-named domain entity that does not need a `Forecast` prefix since it already lives in the forecast feature namespace
- Renamed all `Planner*` identifiers to `Forecast*` in the migrated files for clean feature ownership
- Did not delete planner originals — they remain active via `planner_provider.dart` which is still imported by the router (this is the correct sequence; Plan 04 handles the presentation layer)

## Deviations from Plan

None — plan executed exactly as written. All four files created with correct identifiers, imports, and content. Flutter analyze confirms zero new errors.

## Known Stubs

None — the migrated files contain no stub patterns. All logic is fully functional (migrated from working planner source).

## Threat Flags

No new security-relevant surface introduced. This plan creates Dart domain/data layer files by migration — no network endpoints, no auth paths, no file access patterns, no schema changes.

## Self-Check: PASSED

- `lib/features/forecast/domain/entities/daily_forecast.dart` — FOUND
- `lib/features/forecast/domain/repositories/i_forecast_repository.dart` — FOUND
- `lib/features/forecast/domain/logic/forecast_logic.dart` — FOUND
- `lib/features/forecast/data/repositories/forecast_repository.dart` — FOUND
- Task 1 commit `8416c17` — FOUND
- Task 2 commit `2e2a0a4` — FOUND
- `grep -r "IPlannerRepository|PlannerLogic|PlannerRepository" lib/features/forecast/` — zero results (PASS)
- `flutter analyze lib/features/forecast/` — 0 errors (PASS)
- All four planner originals preserved (PASS)

---
*Phase: 01-archive-cleanup | Completed: 2026-06-13*
