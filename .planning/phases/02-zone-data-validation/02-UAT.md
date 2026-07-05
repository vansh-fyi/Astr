---
status: complete
phase: 02-zone-data-validation
source: 02-01-SUMMARY.md, 02-02-SUMMARY.md, 02-03-SUMMARY.md, 02-04-SUMMARY.md, 02-05-SUMMARY.md
started: 2026-07-04T00:00:00Z
updated: 2026-07-04T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. zones.db Binary Integrity
expected: assets/db/zones.db exists (716 MB), magic header is b'ASTR', version 1, 37,528,537 records, SHA-256 = 09cb4d9920c65fc70eebfa098223809e9b7dd451aecc01965d6aef54f7b83f08
result: pass
note: auto-verified

### 2. Zone Threshold Boundary Tests (ZONE-04)
expected: flutter test test/core/services/darkness_calculator_test.dart passes all 20 tests — 10 pre-existing getDarknessLabel/calculateDarkness tests + 10 new Zone SQM boundary verification tests
result: pass
note: auto-verified — all 20 passed

### 3. Validator Passes 22/25 Locations
expected: Running python scripts/validate_zones_db.py produces RESULTS: 22/25 PASS. Passing locations include all major cities (NYC, London, Tokyo, Paris), all dark sky sites (Death Valley, Atacama, Mauna Kea, Teide), and remote areas (Greenland Nuuk, Wellington, Anchorage). 3 accepted failures: Reykjavik (VNL over-brightness), Singapore (H3 cell placement), Ushuaia (VNL over-brightness)
result: pass
note: auto-verified via Plan 04 SUMMARY — SHA-256 confirmed same zones.db

### 4. Cloudflare D1 Record Count
expected: SELECT COUNT(*) FROM zones returns 37,528,537 — matching the local zones.db exactly. Old 47.9M record table was replaced.
result: pass

### 5. Cloudflare R2 zones.db Live
expected: R2 bucket astr-zones/zones.db holds the 715.8 MB file uploaded in Plan 05. The Worker endpoint responds to a zone lookup for New York (40.7128, -74.0060) with zone 9.
result: pass
note: D1 query for H3 613229551394226175 (882a107289fffff) returned zone=9, radiance=247.76

### 6. App Shows Correct Zone After Cache Clear
expected: On device/simulator, clear app data (or reinstall) to flush Hive zoneCache. Open the app at New York coordinates — it should fetch from Cloudflare and display Zone 9 (Very Poor / light-polluted sky). No crash, no Zone 1 fallback.
result: pass

## Summary

total: 6
passed: 6
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
