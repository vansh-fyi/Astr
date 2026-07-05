---
phase: 2
slug: zone-data-validation
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-13
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Dart unit tests) + Python scripts (validation scripts) |
| **Config file** | `analysis_options.yaml` (Flutter), `scripts/.venv` (Python) |
| **Quick run command** | `flutter test test/core/services/darkness_calculator_test.dart` |
| **Full suite command** | `flutter test && source scripts/.venv/bin/activate && python scripts/validate_zones_db.py` |
| **Estimated runtime** | ~30 seconds (Dart) + ~2 minutes (Python validator) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/core/services/darkness_calculator_test.dart`
- **After every plan wave:** Run full suite (Dart + Python validator)
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~30 seconds (Dart quick run)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | ZONE-01, ZONE-02 | — | N/A | manual script | `python scripts/validate_zones_db.py` | ✅ | ⬜ pending |
| 02-02-01 | 02 | 1 | ZONE-04 | — | N/A | unit | `flutter test test/core/services/darkness_calculator_test.dart` | ✅ | ⬜ pending |
| 02-03-01 | 03 | 2 | ZONE-03 | — | N/A | manual script | `python scripts/apply_skyglow.py && python scripts/validate_zones_db.py` | ✅ | ⬜ pending |
| 02-04-01 | 04 | 3 | ZONE-01, ZONE-02 | — | N/A | manual script | `python scripts/validate_zones_db.py` | ✅ | ⬜ pending |
| 02-05-01 | 05 | 4 | ZONE-03 | — | N/A | manual | `npx wrangler d1 execute` + `python upload_to_r2.py` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

- `test/core/services/darkness_calculator_test.dart` — existing, 10 tests pass. Extend with zone threshold boundary assertions.
- `scripts/.venv` — all Python dependencies pre-installed (h3, rasterio, numpy, scipy, sqlite3, struct).
- No new packages or test stubs required before Wave 1.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Lorenz reference lookup for test cities | ZONE-01/02 | djlorenz.github.io has no machine-readable API — values must be read manually from the color-zone atlas | Visit djlorenz.github.io, look up each test city, record LPI/radiance estimate, map to expected Astr zone using ZONE_THRESHOLDS |
| Cloudflare D1/R2 deploy confirmation | ZONE-03 | Production API access; can't automate in CI | Run `npx wrangler d1 execute` + `python upload_to_r2.py`, then query live API endpoint to confirm corrected zone |
| App zone values after Cloudflare update | ZONE-03 | Requires device + cache clear | Clear Hive `zoneCache` box (app data clear) and verify app shows corrected zones for flagged cities |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none needed — existing infra sufficient)
- [x] No watch-mode flags
- [x] Feedback latency < 30s (Dart quick run)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-13
