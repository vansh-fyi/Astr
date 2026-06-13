---
phase: 01-archive-cleanup
plan: "04"
subsystem: ui
tags: [flutter, riverpod, go_router, hive_ce, forecast, build_runner]

# Dependency graph
requires:
  - phase: 01-03
    provides: forecast domain layer (ForecastLogic, IForecastRepository, ForecastRepository, DailyForecast)
provides:
  - forecast presentation layer with ForecastScreen ConsumerStatefulWidget
  - forecastRepositoryProvider and forecastLogicProvider wired to forecast domain
  - app_router.dart pointing to features/forecast/ not planner/pages/
  - hive_adapters.dart cleaned of ThemeUiModel spec and import
  - hive_registrar.g.dart regenerated without ThemeUiModelAdapter
  - flutter analyze exits 0 — codebase clean and ready for Plan 05 archive deletions
affects:
  - 01-05 (can now safely archive lib/features/planner/ and lib/config/theme/)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - FutureProvider wrapping IForecastRepository.get7DayForecast with astrContextProvider + lightPollutionProvider
    - ConsumerStatefulWidget with SingleTickerProviderStateMixin for forecast screen
    - Hive CE adapter registry kept as comment-only file when no adapters are needed

key-files:
  created:
    - lib/features/forecast/presentation/providers/forecast_provider.dart
  modified:
    - lib/features/forecast/presentation/forecast_screen.dart
    - lib/app/router/app_router.dart
    - lib/hive/hive_adapters.dart
    - lib/hive/hive_registrar.g.dart
    - lib/hive/hive_adapters.g.yaml

key-decisions:
  - "Removed part 'hive_adapters.g.dart' directive because hive_ce_generator produces no .dart file when @GenerateAdapters list is empty"
  - "Manually updated lib/hive/hive_registrar.g.dart from the correctly-regenerated file (build_runner placed it at lib/ root instead of lib/hive/)"
  - "Kept hive_adapters.dart as a comment-only placeholder file for future adapter registrations"

patterns-established:
  - "forecast_provider.dart mirrors planner_provider.dart structure with Forecast-prefixed identifiers at identical directory depth"

requirements-completed:
  - ARCH-03
  - ARCH-05

# Metrics
duration: 25min
completed: 2026-06-13
---

# Phase 01 Plan 04: Forecast Presentation Layer & Hive Cleanup Summary

**Working ForecastScreen with forecastListProvider wired to forecast domain, router updated from planner/pages/ to forecast/presentation/, and ThemeUiModelAdapter removed from Hive CE registry**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-06-13T~10:30Z
- **Completed:** 2026-06-13T~10:55Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Created `lib/features/forecast/presentation/providers/forecast_provider.dart` with ForecastLogic, IForecastRepository, forecastRepositoryProvider, and forecastListProvider
- Replaced stub `forecast_screen.dart` with full ConsumerStatefulWidget (7-day forecast list with segmented rating bars) migrated from planner/pages/
- Updated `app_router.dart` line 9 import from `planner/presentation/pages/` to `forecast/presentation/`
- Removed ThemeUiModel import and AdapterSpec from `hive_adapters.dart`; regenerated hive_registrar.g.dart without ThemeUiModelAdapter
- `flutter analyze lib/` exits 0 with zero error-level diagnostics — codebase ready for Plan 05 archive deletions

## Task Commits

Each task was committed atomically:

1. **Task 1: Create forecast_provider.dart and replace forecast_screen.dart stub** - `fe5116e` (feat)
2. **Task 2: Update router import, clean hive_adapters, run build_runner and flutter analyze** - `5f1a8c8` (feat)

## Files Created/Modified
- `lib/features/forecast/presentation/providers/forecast_provider.dart` — NEW: ForecastLogic + IForecastRepository providers + forecastListProvider FutureProvider
- `lib/features/forecast/presentation/forecast_screen.dart` — MODIFIED: stub replaced with full ConsumerStatefulWidget from planner/pages/forecast_screen.dart
- `lib/app/router/app_router.dart` — MODIFIED: import updated from planner/pages/ to forecast/presentation/
- `lib/hive/hive_adapters.dart` — MODIFIED: ThemeUiModel removed, now a comment-only placeholder file
- `lib/hive/hive_registrar.g.dart` — MODIFIED: ThemeUiModelAdapter registration removed
- `lib/hive/hive_adapters.g.dart` — DELETED: build_runner produces no file when @GenerateAdapters list is empty
- `lib/hive/hive_adapters.g.yaml` — MODIFIED: ThemeUiModel type entry removed by build_runner

## Decisions Made
- **part directive removal:** The `part 'hive_adapters.g.dart'` directive was removed from `hive_adapters.dart` because hive_ce_generator does not generate a `.dart` file when the `@GenerateAdapters` list contains no adapter types. Keeping the directive would cause `uri_has_not_been_generated` analyzer error.
- **hive_registrar.g.dart path correction:** build_runner generated a new `lib/hive_registrar.g.dart` at the `lib/` root level instead of `lib/hive/`. Since `hive_init_mobile.dart` and `hive_init_web.dart` import `hive_registrar.g.dart` relative to `lib/hive/`, the newly-generated file was at the wrong path. Applied the content to the correct `lib/hive/hive_registrar.g.dart` and deleted the misplaced file.
- **hive_adapters.dart as placeholder:** Kept the file as a comment-only placeholder documenting how to re-add adapters in the future.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed hive_adapters.dart part directive causing uri_has_not_been_generated error**
- **Found during:** Task 2 (Update router import, clean hive_adapters)
- **Issue:** PATTERNS.md target state retained `part 'hive_adapters.g.dart'` directive, but with an empty `@GenerateAdapters` list the hive_ce_generator produces no `.dart` file, causing `uri_has_not_been_generated` analyzer error
- **Fix:** Removed `part 'hive_adapters.g.dart'` directive and `@GenerateAdapters` annotation; `hive_adapters.dart` is now a comment-only placeholder
- **Files modified:** lib/hive/hive_adapters.dart
- **Verification:** `flutter analyze lib/` shows 0 error-level diagnostics
- **Committed in:** 5f1a8c8 (Task 2 commit)

**2. [Rule 1 - Bug] Fixed hive_registrar.g.dart placed at wrong path by build_runner**
- **Found during:** Task 2 (build_runner regeneration)
- **Issue:** build_runner regenerated `hive_registrar.g.dart` at `lib/hive_registrar.g.dart` (lib/ root) but existing imports resolve it relative to `lib/hive/`. The OLD `lib/hive/hive_registrar.g.dart` still contained ThemeUiModelAdapter.
- **Fix:** Applied the correctly-generated content (without ThemeUiModelAdapter) to `lib/hive/hive_registrar.g.dart`; deleted the misplaced `lib/hive_registrar.g.dart`
- **Files modified:** lib/hive/hive_registrar.g.dart
- **Verification:** `flutter analyze lib/` shows 0 error-level diagnostics; hive_registrar.g.dart has 0 occurrences of ThemeUiModelAdapter
- **Committed in:** 5f1a8c8 (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 - Bug)
**Impact on plan:** Both auto-fixes required for `flutter analyze` exit-0 gate. No scope creep.

## Issues Encountered
- build_runner with hive_ce_generator changed its output path for `hive_registrar.g.dart` from `lib/hive/` to `lib/` root — required manual path correction to match existing import references

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `lib/app/router/app_router.dart` imports from `lib/features/forecast/presentation/forecast_screen.dart` only — zero planner references remain
- `lib/features/planner/` is now safe to archive (no active code imports it)
- `lib/config/theme/` is now safe to archive (hive_adapters.dart no longer references it)
- `flutter analyze lib/` exits 0 — Plan 05 can proceed with archive deletions

## Known Stubs
None — the ForecastScreen widget is fully functional (7-day forecast list with real data from forecastListProvider).

## Threat Flags
None — no new security-relevant surface introduced. Router import change verified by flutter analyze gate (T-04-02 mitigated).

## Self-Check: PASSED
- `lib/features/forecast/presentation/providers/forecast_provider.dart` exists: FOUND
- `lib/features/forecast/presentation/forecast_screen.dart` contains ForecastScreen ConsumerStatefulWidget: FOUND
- `lib/app/router/app_router.dart` imports features/forecast: FOUND (1 occurrence)
- `lib/hive/hive_adapters.dart` has no ThemeUiModel or theme_ui_model: CONFIRMED (0 occurrences)
- `lib/hive/hive_registrar.g.dart` has no ThemeUiModelAdapter: CONFIRMED (0 occurrences)
- Task 1 commit fe5116e: FOUND
- Task 2 commit 5f1a8c8: FOUND

---
*Phase: 01-archive-cleanup*
*Completed: 2026-06-13*
