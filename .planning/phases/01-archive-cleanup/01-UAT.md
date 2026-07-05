---
status: complete
phase: 01-archive-cleanup
source: 01-01-SUMMARY.md, 01-02-SUMMARY.md, 01-03-SUMMARY.md, 01-04-SUMMARY.md, 01-05-SUMMARY.md, 01-06-SUMMARY.md
started: 2026-07-04T00:00:00Z
updated: 2026-07-04T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Archive Folder Structure
expected: archive/ contains exactly 6 subfolders: backend/, api/, data-pipeline/, planner/, config-theme/, common/ — plus INDEX.md at root
result: pass
note: auto-verified — all 6 subfolders present

### 2. Archive INDEX.md Coverage
expected: archive/INDEX.md documents all 6 subfolders with what it was, why archived, and what replaced it
result: pass
note: auto-verified — all 6 entries present with full what/why/replacement columns

### 3. No Dead Imports in lib/
expected: grep for "features/planner" or "config/theme" in lib/ returns 0 matches — no active code references archived directories
result: pass
note: auto-verified — 0 matches

### 4. Flutter Analyze Exits Clean
expected: flutter analyze lib/ reports 0 error-level diagnostics
result: pass
note: auto-verified — 847 issues total, 0 at error level

### 5. Pipeline Reproduction Guide Quality
expected: archive/data-pipeline/README.md contains all 4 pipeline steps (generate_zones_vnl.py, apply_skyglow.py, export_zones_to_sql.py, upload_to_r2.py), skyglow parameters (fraction, scale, d0, power, max_radius), binary zone format spec (16-byte header + 20-byte records), and a note about zones_accumulator.db
result: pass

### 6. Forecast Screen Loads in App
expected: Running the app and navigating to the Forecast screen shows a 7-day forecast list with segmented rating bars and real data. No crash, no blank screen.
result: pass

### 7. Test Suite Baseline
expected: flutter test runs with approximately 492 passing, 29 skipped, 6 failing — the 6 failures are pre-existing (weather_background_sync_service_test.dart and navigation_test.dart), none introduced by Phase 1
result: issue
reported: "504 passing, 29 skipped, 5 failing. 2 expected pre-existing failures present (weather_background_sync_service_test, navigation_test). 3 failures not documented in Phase 1 baseline: catalog_repository_impl_test (expected 8 planets, got 7), dashboard_header_test (2 widget tests — location name and 'Current Location' text not found)."
severity: minor

## Summary

total: 7
passed: 6
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "flutter test results match the Phase 1 documented baseline — 492 passing, 29 skipped, 6 failing (weather_background_sync_service_test and navigation_test only)"
  status: resolved
  reason: "User reported: 504 passing, 29 skipped, 5 failing. 3 failures not in baseline were diagnosed and fixed in commit 584bb47."
  severity: minor
  test: 7
  root_cause: "catalog_repository_impl_test: wrong expectation (8 vs actual 7 planets — Moon is satellite type). dashboard_header_test: DashboardHeader only rendered last-updated indicator, never implemented location name display from astrContextProvider (FR-13 half-implemented)."
  artifacts:
    - path: "lib/features/dashboard/presentation/widgets/dashboard_header.dart"
      issue: "astrContextProvider never watched; location name not rendered"
    - path: "test/features/catalog/data/repositories/catalog_repository_impl_test.dart"
      issue: "expect(objects.length, 8) wrong — Moon is CelestialType.satellite not planet"
  missing:
    - "Watch astrContextProvider in DashboardHeader and render location.name"
    - "Fix planet count expectation to 7"
  debug_session: "diagnosed inline — 584bb47"
