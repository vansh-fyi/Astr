---
phase: 02-zone-data-validation
plan: "01"
subsystem: zone-data-pipeline
tags: [python, zones, validation, binary-db, data-quality]
dependency_graph:
  requires: []
  provides: [assets/db/zones.db, validate_zones_db-expected-zones]
  affects: [02-02, 02-03]
tech_stack:
  added: []
  patterns: [binary-search, expected-zone-comparison, zone-mismatch-table]
key_files:
  created:
    - assets/db/zones.db
  modified:
    - scripts/validate_zones_db.py
decisions:
  - "D-02 enforced: no Bortle terminology in print output; internal dict key 'bortle' left unchanged"
  - "zones.db is gitignored (913 MB binary); generated from zones_accumulator.db on-demand"
  - "write_zones_db() called standalone (no TIF scan) — fast path per RESEARCH.md Pattern 1"
  - "Task 1 checkpoint pre-resolved: 25 expected Astr zones confirmed via Lorenz atlas manual lookup"
metrics:
  duration_minutes: 2
  completed_date: "2026-06-13"
  tasks_completed: 2
  files_changed: 2
---

# Phase 02 Plan 01: Generate zones.db and Extend Validator Summary

**One-liner:** Generated 913 MB zones.db from accumulator (47.9M records) and extended validate_zones_db.py with 25-location expected Astr zone comparison, revealing 11 mismatches for Plan 03 parameter tuning.

## What Was Built

### Task 1: Derive Lorenz→Astr expected zones (pre-resolved checkpoint)

The 25 expected Astr zones were confirmed by the developer via manual Lorenz Light Pollution Atlas lookup prior to this execution. The zones were embedded directly in Task 2.

### Task 2: Generate assets/db/zones.db and extend validator

**Step A — assets/db/zones.db generated:**
- Called `write_zones_db()` from `apply_skyglow.py` standalone (no TIF scan)
- Source: `zones_accumulator.db` at repo root (1.22 GB SQLite, 47,887,089 cells)
- Output: `assets/db/zones.db` (913.4 MB, 47,886,626 records; 463 Zone 1 skipped as implicit)
- Binary header: `b'ASTR\x01\x00\x00\x00'` confirmed
- SHA-256: `9136ed3e95c3e8a7564b3b87a5fd06e75c501334d752eabdefc2b1e73aa74347`

**Step B — scripts/validate_zones_db.py extended:**
- Added `ZONE_THRESHOLDS` constant and `radiance_to_zone()` function at module top (copied from apply_skyglow.py)
- Changed `TEST_LOCATIONS` to 4-tuples: `(name, lat, lon, expected_zone)` with expected Astr zones for all 25 locations
- Replaced `main()` loop body with PASS/FAIL comparison loop (per PATTERNS.md Pattern 2)
- Added `Mismatches (expected vs actual Astr zone):` table after RESULTS line
- All print strings use "Astr zone" — no "Bortle" in output (D-02)
- `binary_search_zones_db()` and `lat_lon_to_h3()` left UNCHANGED

## Validation Results

Running `python scripts/validate_zones_db.py` produced:

```
RESULTS: 14/25 PASS

Mismatches (expected vs actual Astr zone):
  Tokyo, Japan: expected 9, got 8, radiance=94.93
  Sydney, Australia: expected 8, got 9, radiance=157.39
  Paris, France: expected 9, got 8, radiance=120.76
  Mumbai, India: expected 9, got 8, radiance=107.94
  Cape Town, South Africa: expected 7, got 8, radiance=90.17
  Teide, Canary Islands: expected 3, got 4, radiance=1.92
  Greenland Nuuk: expected 5, got 6, radiance=16.15
  Reykjavik, Iceland: expected 7, got 9, radiance=132.6
  Singapore: expected 9, got 8, radiance=60.84
  Wellington, NZ: expected 7, got 8, radiance=60.74
  Ushuaia, Argentina: expected 7, got 8, radiance=107.33
```

14 of 25 locations match expected Astr zones. 11 mismatches identified — these drive the scatter parameter tuning in Plan 03.

**Notable patterns in mismatches:**
- Cities near zone 8/9 boundary (Tokyo 94.93, Paris 120.76, Mumbai 107.94) are just below the 125 nW threshold for Zone 9 — possible over-scatter from nearby sprawl
- Reykjavik at 132.6 nW (Zone 9 actual) is the largest deviation (expected Zone 7) — SCATTER_FRACTION=0.12 hypothesis confirmed
- Wellington and Ushuaia at ~60-107 nW (Zone 8 actual) instead of expected Zone 7 — similar over-scatter pattern
- Sydney getting Zone 9 (157.39 nW) instead of expected Zone 8 is a borderline case

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 2 | 5e080b0 | feat(02-01): generate zones.db and extend validator with expected Astr zones |

## Deviations from Plan

None - plan executed exactly as written. Task 1 checkpoint was pre-resolved by the orchestrator with confirmed expected zones.

## Known Stubs

None — all 25 locations produce real zone data from the binary database lookup.

## Threat Flags

None — no new network endpoints, auth paths, or trust boundary changes introduced. zones.db is a local generated binary file, gitignored and not committed to the repository.

## Self-Check: PASSED

- FOUND: assets/db/zones.db (913.4 MB, ASTR magic header confirmed, 47,886,626 records)
- FOUND: scripts/validate_zones_db.py (syntax valid, runs without exception)
- FOUND: commit 5e080b0
- Size check: 957,732,536 bytes > 50 MB PASS
- Magic header: b'ASTR\x01\x00\x00\x00' PASS
- 25 [OK]/[FAIL] lines in output PASS
- RESULTS: 14/25 PASS line present PASS
- Mismatches table present (11 mismatches) PASS
- No "Bortle" in output PASS
