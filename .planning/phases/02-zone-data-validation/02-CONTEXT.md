# Phase 2: Zone Data Validation - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove that the Astr Zone values returned for any geographic location are demonstrably accurate — validated against the David Lorenz light pollution atlas (djlorenz.github.io), with inaccuracies documented and resolved by retuning the skyglow diffusion model and regenerating the zones database. Phase ends with corrected data live on Cloudflare. Zero UI work; pure data quality.

</domain>

<decisions>
## Implementation Decisions

### Reference Data & Terminology
- **D-01:** The reference source for validation is **djlorenz.github.io/astronomy/lp/** — the direct inspiration for Astr's zone system, using the same VNL NPP base data.
- **D-02:** Do NOT use Bortle scale terminology. Astr uses its **own 1-9 zone scale**, which is distinct from the Bortle Dark-Sky Scale. All validation, documentation, and code must refer to "Astr zones", not "Bortle classes".
- **D-03:** The Lorenz→Astr zone relationship must be **derived fresh** — no formal mapping exists yet. The researcher must pull Lorenz radiance values for the test city set, establish the expected Astr zone for each, then compare against what `zones_accumulator.db` returns.

### Validation Approach
- **D-04:** Validate against **local `zones_accumulator.db`** only (not the live Cloudflare API). The local binary is the source of truth uploaded to Cloudflare; if it's correct, the API is correct.
- **D-05:** **Extend the existing `scripts/validate_zones_db.py`** — add Lorenz reference value lookup and expected-vs-actual zone comparison to the existing script. Reuse the 25 test locations already there (cities + dark sky sites across multiple continents). Do not write a separate validation script.
- **D-06:** Validation workflow: (1) establish Lorenz→Astr zone relationship, (2) for each test city look up the Lorenz radiance, (3) derive expected Astr zone using the relationship, (4) compare to what `zones_accumulator.db` returns — both must match.

### Fix Strategy
- **D-07:** If inaccuracies are found, the fix path is **retune `apply_skyglow.py` scatter parameters** (`SCATTER_FRACTION`, `SCATTER_SCALE_KM`, `SCATTER_POWER`, `MAX_RADIUS_KM`) and regenerate `zones_accumulator.db`. This is the primary lever for zone accuracy.
- **D-08:** Phase 2 **includes the full Cloudflare deploy** — re-uploading corrected zone data to D1/R2 via the existing upload pipeline. Phase is not complete until production reflects the corrected values.

### Verification Artifact
- **D-09:** ZONE-04 ("diffusion output verifiable given known input") is satisfied by **Dart unit tests** in the Flutter app, specifically:
  - `DarknessCalculator.calculateDarkness()` tested with known inputs (baseMPSAS, moonPhase, moonAltitude) asserting correct effective MPSAS output
  - Zone threshold boundary tests: given known radiance values, assert the correct Astr zone (1-9) is assigned

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` §Zone Data Accuracy — ZONE-01 through ZONE-04 are the requirements for this phase. Read these to understand exactly what "done" means.
- `.planning/ROADMAP.md` §Phase 2 — Success criteria: 10+ diverse locations match reference, previously wrong zones corrected, diffusion verifiable via Dart unit tests.

### Project Context
- `.planning/PROJECT.md` §Zone system — Explains the Astr Zone system origin (David Lorenz / djlorenz.github.io), VNL NPP 2024 data, and skyglow diffusion rationale.
- `.planning/PROJECT.md` §Context — Codebase state and active data path.

### Zone Pipeline Scripts
- `scripts/apply_skyglow.py` — **THE CORE FILE.** Contains `ZONE_THRESHOLDS` (radiance→zone mapping), scatter model parameters (`SCATTER_FRACTION`, `SCATTER_SCALE_KM`, `SCATTER_POWER`), and the Garstang-inspired diffusion kernel. Tuning this script is the primary fix mechanism.
- `scripts/validate_zones_db.py` — Existing validation script with 25 test locations. Phase 2 extends this script to add Lorenz reference lookups and expected-vs-actual zone comparison.
- `scripts/validate_zones_extended.py` — Extended random-location sampling with VIIRS tile gap detection. Reference for understanding coverage gaps.
- `scripts/generate_zones_vnl.py` — Source-of-truth zone generation pipeline (runs before `apply_skyglow.py`).

### Active Zone Code (Flutter App)
- `lib/core/services/darkness_calculator.dart` — `DarknessCalculator` class. ZONE-04 Dart unit tests must cover `calculateDarkness()` and the MPSAS→quality label mapping.
- `lib/features/data_layer/services/remote_zone_service.dart` — Production zone fetch from Cloudflare Worker. Returns `ZoneData(bortleClass, ratio, sqm)`.
- `lib/features/data_layer/models/zone_data.dart` — `ZoneData` model: `bortleClass` (int 1-9), `ratio` (double), `sqm` (double). **Note:** field is named `bortleClass` in code but represents Astr zone, not Bortle — do not rename in Phase 2 (that is a Phase 3+ cleanup concern if at all).

### Cloudflare Infrastructure
- `cloudflare/wrangler.toml` — D1 database binding (`DB`, id: `d00b90d6-9117-4501-9ec8-5213d5ef334d`) and R2 bucket binding (`ZONE_BUCKET`, bucket: `astr-zones`). Re-upload uses these targets.
- `cloudflare/worker.js` — Worker that serves `/zone/{h3HexIndex}`. Read to understand response format before extending validation script.

### External Reference (must access during research)
- `https://djlorenz.github.io/astronomy/lp/` — David Lorenz Light Pollution Atlas. Researcher must extract radiance/SQM values for the 25 test locations and establish the Lorenz→Astr zone mapping relationship.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/validate_zones_db.py` — Contains working binary search against `zones_accumulator.db`, H3 lat/lon conversion, and 25 test locations. Extend rather than replace.
- `lib/core/services/darkness_calculator.dart` — Already written. Unit tests wrap this class directly — no mocking needed, it's pure math.
- `zones_accumulator.db` — 1.3GB local binary at repo root (not committed). This is the source of truth for all validation. Phase 1 added it to `.gitignore` and documented it in `archive/data-pipeline/README.md`.

### Established Patterns
- Zone data model: `bortleClass` (1-9), `ratio` (light pollution ratio), `sqm` (mag/arcsec²) — all three values stored per H3 cell in zones.db and served by the Cloudflare Worker.
- Binary zones.db format: 16-byte header (magic + record_count uint64), 20-byte records (8-byte H3 index uint64 + zone data). Sorted by H3 index for binary search.
- Dart unit tests follow `_test.dart` naming convention, mirror source paths, and use `flutter_test`. See existing tests in `test/` for patterns.
- Zone threshold formula is in `apply_skyglow.py` `ZONE_THRESHOLDS` list: `[(125.0, 9), (50.0, 8), ...]` mapping radiance to Astr zone 1-9.

### Integration Points
- Phase 2 does NOT touch the Flutter UI or provider layer — only `scripts/` (Python), `lib/core/services/darkness_calculator.dart` (Dart tests), and Cloudflare (re-upload).
- After re-upload, the Hive `zoneCache` box will serve stale data until cache expires. The app's cache TTL should be documented as a known limitation for testers during validation.

</code_context>

<specifics>
## Specific Ideas

- The user's mental model for validation: "Take New York → derive Lorenz→Astr zone relationship → calculate what we expect → compare to what our DB gives out. Both should match."
- The Lorenz→Astr zone relationship is NOT currently documented anywhere. The researcher must construct this mapping by visiting djlorenz.github.io and cross-referencing with `ZONE_THRESHOLDS` in `apply_skyglow.py`.
- Field naming note: `ZoneData.bortleClass` in code refers to Astr zone (1-9), not Bortle. This is a naming debt acknowledged but NOT to be fixed in Phase 2.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 2-Zone Data Validation*
*Context gathered: 2026-06-13*
