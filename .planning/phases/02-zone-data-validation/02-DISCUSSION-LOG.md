# Phase 2: Zone Data Validation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 2-Zone Data Validation
**Areas discussed:** Reference data source, Validation target, Fix strategy, Verification artifact

---

## Reference data source

| Option | Description | Selected |
|--------|-------------|----------|
| djlorenz.github.io | Direct inspiration for Astr's zone system, same VNL NPP base data | ✓ |
| lightpollutionmap.info | Popular map with SQM/Bortle overlays, different methodology | |
| Both djlorenz + lightpollutionmap.info | Cross-check both sources for more confidence | |

**User's choice:** djlorenz.github.io

**Notes:**
- User clarified that Astr uses its **own 1-9 zone scale**, NOT the Bortle Dark-Sky Scale. Terminology "Bortle" must not be used in validation or documentation.
- The Lorenz→Astr zone relationship does not currently exist as a formal document. Must be derived fresh during research.
- Validation mental model: derive the Lorenz→Astr zone mapping, then for each test city check that `zones_accumulator.db` output matches the expected zone derived from Lorenz data.
- Accuracy tolerance: "both should match" — exact match expected per the derived relationship.

---

## Validation target

| Option | Description | Selected |
|--------|-------------|----------|
| Local zones.db only | zones_accumulator.db is the source of truth; faster, offline | ✓ |
| Both local + live Cloudflare API | Local bulk + spot-check of live API | |
| Live Cloudflare API only | Full production stack test | |

**User's choice:** Local zones.db only

| Option | Description | Selected |
|--------|-------------|----------|
| Extend the existing script | Add Lorenz reference lookup to validate_zones_db.py, reuse 25 locations | ✓ |
| Write a new validation script | Separate concerns into a new accuracy validation script | |
| You decide | Let researcher determine | |

**User's choice:** Extend the existing script

**Notes:** The 25 test locations in `validate_zones_db.py` (major cities + dark sky sites across multiple continents) are sufficient for ZONE-01's "diverse set of at least 10 locations" requirement.

---

## Fix strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Retune apply_skyglow.py params + regenerate DB | Adjust SCATTER_FRACTION, SCATTER_SCALE_KM, SCATTER_POWER and rebuild | ✓ |
| Fix ZONE_THRESHOLDS radiance cutoffs | Recalibrate the radiance→zone mapping thresholds | |
| Both — researcher investigates | Let validation results determine which lever to pull | |

**User's choice:** Retune apply_skyglow.py params + regenerate DB

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — full deploy included in Phase 2 | Corrected data live on Cloudflare before phase is done | ✓ |
| No — deploy is manual | Phase 2 validates and documents; deploy is a separate step | |

**User's choice:** Yes — full deploy included in Phase 2

**Notes:** Phase is not complete until corrected zone data is live on Cloudflare D1/R2 and the production app receives correct values.

---

## Verification artifact

| Option | Description | Selected |
|--------|-------------|----------|
| Dart unit tests in the app | Tests in Flutter app run in CI, document algorithm as executable specs | ✓ |
| Python validation script only | Extended validate_zones_db.py serves as ZONE-04 verification | |
| Both Python + Dart unit tests | Belt-and-suspenders approach | |

**User's choice:** Dart unit tests in the app

| Option | Description | Selected |
|--------|-------------|----------|
| DarknessCalculator formula + zone thresholds | Test calculateDarkness() and threshold boundary mapping | ✓ |
| Full pipeline: radiance → zone output | Test entire pipeline from raw radiance through skyglow diffusion | |
| You decide | Let planner determine scope | |

**User's choice:** DarknessCalculator formula + zone thresholds

**Notes:** ZONE-04 is satisfied by Dart unit tests covering `DarknessCalculator.calculateDarkness()` with known inputs and zone threshold boundary assertions.

---

## Claude's Discretion

None — all key decisions were made by the user.

## Deferred Ideas

None — discussion stayed within phase scope.
