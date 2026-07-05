---
phase: 02-zone-data-validation
plan: 02
subsystem: testing
tags: [flutter, dart, flutter_test, darkness_calculator, zone_thresholds, ZONE-04]

# Dependency graph
requires:
  - phase: 02-zone-data-validation
    provides: DarknessCalculator implementation with getDarknessLabel thresholds and calculateDarkness signature
provides:
  - 10 new zone threshold boundary tests in group 'Zone SQM boundary verification (ZONE-04)'
  - ZONE-04 requirement satisfied: Dart-side diffusion output verifiable given known input luminance
affects:
  - phase: 02-zone-data-validation (plans 03+)

# Tech tracking
tech-stack:
  added: []
  patterns: [tuple destructuring pattern for getDarknessLabel testing via final (String label, _) = calculator.getDarknessLabel(sqm), closeTo() matcher for floating-point calculateDarkness assertions]

key-files:
  created: []
  modified:
    - test/core/services/darkness_calculator_test.dart

key-decisions:
  - "Zone 2 lower boundary SQM 21.70 maps to 'Excellent' (not 'Good') because 21.70 >= 21.5 threshold — plan comment was incorrect; implementation is authoritative"
  - "10 tests added (not 9) to cover all 8 zone boundary labels plus 2 calculateDarkness integration tests"

patterns-established:
  - "Tuple destructuring pattern: final (String label, _) = calculator.getDarknessLabel(sqm); expect(label, equals('X'));"
  - "closeTo() for floating-point calculateDarkness results, equals() for getDarknessLabel string labels"

requirements-completed: [ZONE-04]

# Metrics
duration: 5min
completed: 2026-06-13
---

# Phase 2 Plan 02: Zone Threshold Boundary Tests Summary

**10 ZONE-04 boundary tests added to darkness_calculator_test.dart covering all 8 Astr zone SQM thresholds via getDarknessLabel and calculateDarkness, with all 20 tests passing**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-06-13T00:00:00Z
- **Completed:** 2026-06-13T00:05:00Z
- **Tasks:** 1 (TDD task: RED + GREEN in one pass — no production code changes needed)
- **Files modified:** 1

## Accomplishments
- Added group 'Zone SQM boundary verification (ZONE-04)' with 10 new tests to `test/core/services/darkness_calculator_test.dart`
- All 8 zone SQM boundary values (21.70, 21.49, 21.19, 20.56, 19.83, 19.26, 18.59, 17.92) covered with getDarknessLabel assertions
- Zero-moon calculateDarkness pass-through test at Zone 2 boundary SQM (21.70) confirms no penalty applied
- Full-moon at zenith test confirms Zone 3 baseMPSAS (21.49) reduces to 17.49 → 'Very Poor' label
- All 20 tests pass (10 pre-existing + 10 new)
- `darkness_calculator.dart` not modified — production code unchanged

## Task Commits

1. **Task 1: RED + GREEN — zone threshold boundary tests** - `4dae7af` (test)

**Plan metadata:** (see final commit below)

## Files Created/Modified
- `test/core/services/darkness_calculator_test.dart` — Added group 'Zone SQM boundary verification (ZONE-04)' with 10 tests after the existing 'getDarknessLabel' group

## Decisions Made
- Zone 2 lower boundary SQM 21.70 was assigned 'Excellent' (not 'Good') because 21.70 >= 21.5 satisfies the Excellent threshold in `getDarknessLabel`. The plan's `<behavior>` section comment incorrectly stated it should map to 'Good'. The task action explicitly states "adjust the test's expected value to match the actual getDarknessLabel boundary in the implementation." This deviation is documented here per plan instructions.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Threshold Mismatch] Corrected Zone 2 SQM label from 'Good' to 'Excellent'**
- **Found during:** Task 1 (analysis of getDarknessLabel thresholds before writing tests)
- **Issue:** Plan `<behavior>` and PATTERNS.md showed `getDarknessLabel(21.70)` → 'Good', but `darkness_calculator.dart` line 49 is `if (mpsas >= 21.5) return ('Excellent', ...)`. Since 21.70 >= 21.5, the correct label is 'Excellent'. The PATTERNS.md test would have failed at the GREEN phase.
- **Fix:** Test for Zone 2 boundary SQM (21.70) asserts `equals('Excellent')` instead of `equals('Good')`. Added explanatory comment in the test group.
- **Files modified:** test/core/services/darkness_calculator_test.dart
- **Verification:** `flutter test test/core/services/darkness_calculator_test.dart --no-pub` exits 0, +20 all passed
- **Committed in:** 4dae7af (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug in plan's expected value, not in production code)
**Impact on plan:** Test expectation corrected to match authoritative implementation. No scope creep. Production code unchanged.

## Issues Encountered
- Plan behavior block and PATTERNS.md both stated Zone 2 SQM 21.70 → 'Good', but the actual threshold boundary in `darkness_calculator.dart` (>= 21.5 → 'Excellent') means 21.70 maps to 'Excellent'. Reconciled per plan task action: "adjust the test's expected value to match the actual getDarknessLabel boundary in the implementation."

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- ZONE-04 Dart-side verification tests are complete and passing
- All zone SQM boundaries (Zones 2-9) have corresponding getDarknessLabel test coverage
- calculateDarkness() zero-moon and full-moon integration scenarios are covered
- Ready for subsequent plans in phase 02-zone-data-validation

## Known Stubs
None.

## Threat Flags
None — pure test file addition; no new network endpoints, auth paths, file access patterns, or schema changes.

## Self-Check: PASSED
- `test/core/services/darkness_calculator_test.dart` confirmed modified with 'Zone SQM boundary verification (ZONE-04)' group
- commit `4dae7af` exists and is the HEAD commit
- All 20 tests pass (`+20: All tests passed!`)

---
*Phase: 02-zone-data-validation*
*Completed: 2026-06-13*
