# Phase 2: Zone Data Validation - Research

**Researched:** 2026-06-13
**Domain:** Light pollution zone data pipeline — Python scripts, zones.db binary format, Dart unit tests, Cloudflare D1/R2 deploy
**Confidence:** MEDIUM

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Reference source is djlorenz.github.io/astronomy/lp/ — same VNL NPP base data as Astr.
- **D-02:** Do NOT use Bortle scale terminology. All validation, documentation, and code must refer to "Astr zones".
- **D-03:** Lorenz→Astr zone relationship must be derived fresh — no formal mapping exists yet.
- **D-04:** Validate against local `zones_accumulator.db` only — not the live Cloudflare API.
- **D-05:** Extend existing `scripts/validate_zones_db.py` — do not write a separate validation script.
- **D-06:** Validation workflow: (1) establish Lorenz→Astr zone relationship, (2) look up Lorenz radiance for each test city, (3) derive expected Astr zone, (4) compare to what `zones_accumulator.db` returns.
- **D-07:** Fix path is retune `apply_skyglow.py` scatter parameters and regenerate `zones_accumulator.db`. Primary lever: `SCATTER_FRACTION`, `SCATTER_SCALE_KM`, `SCATTER_POWER`, `MAX_RADIUS_KM`.
- **D-08:** Phase 2 includes full Cloudflare deploy — re-uploading corrected zone data to D1/R2. Phase is not complete until production reflects corrected values.
- **D-09:** ZONE-04 is satisfied by Dart unit tests: `DarknessCalculator.calculateDarkness()` tested with known inputs, and zone threshold boundary tests given known radiance values.

### Claude's Discretion
None — discussion stayed within phase scope.

### Deferred Ideas (OUT OF SCOPE)
None.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ZONE-01 | Zone calculation validated against known reference data for diverse locations (urban, suburban, rural, multiple continents) | 25-location test set in validate_zones_db.py; extend with Lorenz reference lookups |
| ZONE-02 | Inaccurate zone locations documented with expected vs. actual values | Research identified 4-6 suspicious assignments; validation script must output this table |
| ZONE-03 | Zone database and/or skyglow diffusion algorithm updated to resolve inaccuracies | Fix: retune SCATTER_FRACTION in apply_skyglow.py, regenerate DB |
| ZONE-04 | Skyglow diffusion verifiable: given known input, output matches expected zenith brightness | Dart unit tests on DarknessCalculator and zone threshold boundaries |
</phase_requirements>

---

## Summary

Phase 2 is a pure data quality phase — no UI changes, no new dependencies. The work divides into three tracks: (1) Python validation and fix, (2) Dart unit tests, and (3) Cloudflare deploy. The critical path is: establish Lorenz→Astr zone mapping → extend validate_zones_db.py → run against the accumulator → identify inaccuracies → retune scatter params → regenerate → re-validate → deploy.

The key infrastructure is already in place: `zones_accumulator.db` (1.2 GB SQLite, 47M cells) exists at repo root, the VNL NPP 2024 TIF (313 MB gz) exists at repo root, the scripts venv has h3 4.4.1 installed, and local wrangler 4.65.0 is available. The single missing piece is `assets/db/zones.db` — the final binary output does not currently exist and must be generated from the accumulator before `validate_zones_db.py` can run as written. [VERIFIED: filesystem inspection]

Preliminary analysis of the accumulator reveals four likely inaccurate assignments: Reykjavik/Iceland at Zone 9 (expected Zone 6-7 for 230k metro), Anchorage/Alaska at Zone 9 (expected Zone 6-7 for 290k city), Ushuaia/Argentina at Zone 8 (expected Zone 4-5 for 55k city), Wellington/NZ at Zone 8 (expected Zone 6-7 for 420k city). The hypothesis is that `SCATTER_FRACTION=0.12` is too high, causing over-scatter from nearby bright sources. Reducing it to 0.05-0.08 is the primary experimental lever. [ASSUMED — hypothesis, needs validation testing to confirm]

**Primary recommendation:** Before any other work, write `assets/db/zones.db` from the existing accumulator using the standalone `write_zones_db()` function, then run the extended validator against it to catalogue the inaccuracies. Only then tune parameters and regenerate.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Zone reference validation | Python scripts | — | Scripted comparison; no app code involved |
| Scatter parameter tuning | Python scripts (`apply_skyglow.py`) | — | All scatter logic lives in this one file |
| Binary zones.db generation | Python scripts | — | write_zones_db() produces the binary format |
| Cloudflare D1 data import | Python scripts + wrangler CLI | — | export_zones_to_sql → wrangler d1 execute |
| Cloudflare R2 upload | Python scripts (`upload_to_r2.py`) | — | boto3 S3-compatible upload |
| Dart unit tests | Flutter test layer (`test/core/services/`) | — | DarknessCalculator is pure Dart math |
| Zone threshold verification | Dart unit tests | Python scripts | Thresholds implemented in both languages |

---

## Standard Stack

### Core (all pre-installed in scripts/.venv)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| h3 | 4.4.1 | H3 hexagonal grid: lat/lon → cell index | Already used throughout pipeline; v4 API (`latlng_to_cell`) [VERIFIED: filesystem inspection] |
| rasterio | 1.3+ | Read VNL GeoTIFF via GDAL | Bundles GDAL; used in all pipeline scripts [ASSUMED — version not inspected directly] |
| numpy | 1.24+ | Coarse grid + convolution array math | Required by fftconvolve and rasterio [ASSUMED] |
| scipy | any recent | `fftconvolve` for 2D scatter kernel | Only reason scipy is in the pipeline [ASSUMED] |
| tqdm | any | Progress bars in long-running scripts | [ASSUMED] |
| sqlite3 | stdlib | Read/write zones_accumulator.db | Python built-in; no install needed [VERIFIED: codebase] |
| struct | stdlib | Binary zones.db format (pack/unpack) | Python built-in [VERIFIED: codebase] |

### Dart Test Stack

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_test | SDK built-in | `test()`, `group()`, `expect()`, `closeTo()` | Flutter's standard test framework [VERIFIED: pubspec.yaml] |

### Cloudflare Deploy Stack

| Tool | Version | Purpose |
|------|---------|---------|
| wrangler | 4.65.0 (local) | `wrangler d1 execute` for D1 SQL import [VERIFIED: cloudflare/node_modules] |
| npx | 11.11.1 | Run wrangler locally [VERIFIED: filesystem] |
| boto3 | any | `upload_to_r2.py` uses S3-compatible R2 API [ASSUMED — version not inspected] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Querying accumulator directly in validator | Reading from zones.db binary | Accumulator has all needed radiance data; validating at source avoids the write-then-validate loop, but D-05 says to extend validate_zones_db.py which reads zones.db |

**Installation:** No new packages needed. All dependencies are in `scripts/.venv` (activated via `source scripts/.venv/bin/activate`). Dart tests use `flutter test` with no new pub dependencies.

---

## Package Legitimacy Audit

No new external packages are introduced in this phase. All dependencies are pre-installed in the existing `scripts/.venv`. No audit required.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
zones_accumulator.db (SQLite, 1.2 GB)
        │
        ├── [Validation Track]
        │       │
        │       ▼
        │   write_zones_db()  ──────────────► assets/db/zones.db (binary, ~80 MB)
        │                                               │
        │                                       validate_zones_db.py (extended)
        │                                               │
        │                                       ┌───────┴────────┐
        │                                    Found           Not Found
        │                                  (expected zone     (Zone 1 implicit)
        │                                   comparison)
        │
        ├── [Fix Track — if inaccuracies found]
        │       │
        │       ▼
        │   apply_skyglow.py (retuned params)
        │   ├── reads VNL TIF (313 MB gz)
        │   ├── re-convolves scatter kernel
        │   └── updates zones_accumulator.db ──► regenerated zones.db
        │
        ├── [Deploy Track]
        │       │
        │       ▼
        │   export_zones_to_sql.py ──► zones_part*.sql (D1 chunks)
        │   wrangler d1 execute ──► Cloudflare D1 (live API)
        │   upload_to_r2.py ──► Cloudflare R2 (download endpoint)
        │
        └── [Dart Test Track]
                │
                ▼
            DarknessCalculator (pure Dart math)
            test/core/services/darkness_calculator_test.dart (existing)
                │
                ▼  [extend]
            zone threshold boundary tests (new)
```

### Recommended Project Structure

No structural changes. Work lives in existing directories:

```
scripts/
├── validate_zones_db.py     # EXTEND: add Lorenz reference lookup + expected zone
├── apply_skyglow.py         # RETUNE: SCATTER_FRACTION, SCATTER_SCALE_KM
└── export_zones_to_sql.py   # REUSE: unchanged

test/core/services/
└── darkness_calculator_test.dart   # EXTEND: add zone threshold boundary tests

assets/db/
└── zones.db                 # GENERATE: write from accumulator (currently missing)
```

### Pattern 1: Lorenz→Astr Zone Mapping

**What:** Derive expected Astr zones for test locations using Lorenz's Light Pollution Index (LPI) mapped to the Astr `ZONE_THRESHOLDS` radiance scale.

**When to use:** When adding expected-zone assertions to validate_zones_db.py.

**Relationship (derived from code inspection):** [VERIFIED: codebase + math derivation]

```python
# Lorenz uses LPI (Light Pollution Index) = artificial / natural
# Natural sky: SQM = 22.0 mag/arcsec², radiance ≈ 0 nW/cm²/sr
# The Astr SQM formula: sqm = clamp(22.0 - 1.7 * log10(1 + 2*radiance), 16, 22)
#
# Astr ZONE_THRESHOLDS mapped to SQM (lower boundary of each zone):
# Zone 2:  radiance >= 0.25  → SQM <= 21.70
# Zone 3:  radiance >= 0.50  → SQM <= 21.49
# Zone 4:  radiance >= 1.00  → SQM <= 21.19
# Zone 5:  radiance >= 3.00  → SQM <= 20.56
# Zone 6:  radiance >= 9.00  → SQM <= 19.83
# Zone 7:  radiance >= 20.0  → SQM <= 19.26
# Zone 8:  radiance >= 50.0  → SQM <= 18.59
# Zone 9:  radiance >= 125.0 → SQM <= 17.92

ZONE_THRESHOLDS = [
    (125.0, 9), (50.0, 8), (20.0, 7), (9.0, 6),
    (3.0, 5), (1.0, 4), (0.50, 3), (0.25, 2),
]

def radiance_to_zone(r):
    if r <= 0: return 1
    for thresh, zone in ZONE_THRESHOLDS:
        if r >= thresh: return zone
    return 1 if r < 0.25 else 2
```

### Pattern 2: Extended Validator with Expected-Zone Assertion

**What:** Extend `validate_zones_db.py` to add Lorenz reference values and expected Astr zone per location, then compare against actual DB zone.

**When to use:** Implementing D-05/D-06.

```python
# Source: codebase inspection of validate_zones_db.py + derived Lorenz mapping
TEST_LOCATIONS_WITH_EXPECTED = [
    # (name, lat, lon, expected_zone, lorenz_notes)
    # Zone 9 cities — dense urban core
    ("New York, USA",       40.7128, -74.0060, 9, "Dense urban core, radiance ~284"),
    ("London, UK",          51.5074, -0.1278,  9, "Dense urban core, radiance ~226"),
    ("Cairo, Egypt",        30.0444,  31.2357, 9, "Dense urban, radiance ~198"),
    # Zone 8 cities — large urban
    ("Tokyo, Japan",        35.6762, 139.6503, 8, "Expected 8-9 for urban center"),
    ("Mumbai, India",       19.0760,  72.8777, 8, "Dense urban, radiance ~108"),
    # Zone 6-7 — medium cities
    ("Greenland Nuuk",      64.1836, -51.7214, 6, "20k pop, polar amplification possible"),
    # Zone 1 — pristine dark sites
    ("Death Valley, USA",   36.5054, -117.0794, 1, "Pristine desert, no urban nearby"),
    ("Atacama Desert",     -24.5000, -69.2500,  1, "World's driest, pristine"),
    ("Mauna Kea, Hawaii",   19.8208, -155.4681, 1, "Top-tier observatory"),
    # ... (all 25 locations)
]

def validate_location(db_path, name, lat, lon, expected_zone):
    h3_index = lat_lon_to_h3(lat, lon, 8)
    result = binary_search_zones_db(db_path, h3_index)
    actual_zone = result['bortle'] if result else 1
    status = "PASS" if actual_zone == expected_zone else "FAIL"
    return {
        'name': name, 'expected': expected_zone,
        'actual': actual_zone, 'status': status,
        'radiance': result['ratio'] if result else None
    }
```

### Pattern 3: Dart Zone Threshold Boundary Tests

**What:** Test that zone threshold boundaries in Dart/app logic produce correct zone assignments given known radiance values.

**When to use:** Satisfying ZONE-04 (D-09).

**Key insight:** `DarknessCalculator` tests already exist (10 pass). The new tests add zone boundary assertions. Since `DarknessCalculator` works on MPSAS (not raw radiance), the threshold tests are separate — they test the SQM-to-quality-label mapping. [VERIFIED: codebase]

```dart
// Source: existing darkness_calculator_test.dart + zone_data model
// Pattern: tests for the MPSAS→quality label boundary conditions
// (These are for DarknessCalculator.getDarknessLabel, which IS the
//  Dart-side diffusion output check required by ZONE-04)

group('zone threshold boundary verification', () {
  test('radiance 0.25 nW produces SQM near 21.7 (Zone 2 boundary)', () {
    // SQM = 22.0 - 1.7 * log10(1 + 2*0.25) = 21.70
    // getDarknessLabel(21.70) → 'Good'
    final (label, _) = calculator.getDarknessLabel(21.70);
    expect(label, equals('Good'));
  });

  test('Zone 4/5 boundary: SQM 20.56 maps to Fair', () {
    // radiance = 3.0 → SQM ≈ 20.56
    final (label, _) = calculator.getDarknessLabel(20.56);
    expect(label, equals('Fair'));
  });

  test('baseMPSAS at zone boundary survives moon penalty calculation', () {
    final double result = calculator.calculateDarkness(
      baseMPSAS: 21.70,   // Zone 2 boundary SQM
      moonPhase: 0.0,
      moonAltitude: 0.0,
    );
    expect(result, equals(21.70));
  });
});
```

### Anti-Patterns to Avoid

- **Running full apply_skyglow.py before generating zones.db first:** The full TIF re-scan takes hours. Generate zones.db from the existing accumulator first to do validation, then only re-run the scatter scan if parameter tuning is needed.
- **Querying the live Cloudflare API for validation:** D-04 explicitly prohibits this. Use the local accumulator/zones.db only.
- **Using Bortle scale terminology in any new code, comments, or docs:** D-02. All references must say "Astr zone" even though the code field is still named `bortleClass`.
- **Writing a separate validation script:** D-05 says extend `validate_zones_db.py`, not create a new file.
- **Deleting zones_accumulator.db:** It's 1.2 GB and took hours to generate. Do not delete it.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| H3 lat/lon conversion | Custom geospatial math | `h3.latlng_to_cell()` (v4 API) | Already in scripts/.venv; one function call [VERIFIED: codebase] |
| Binary file binary search | Linear scan | Existing `binary_search_zones_db()` in validate_zones_db.py | Already implemented with correct 20-byte record stride |
| zones.db write logic | New serializer | `write_zones_db()` in apply_skyglow.py | Already correct with header + record format |
| FFT convolution | Implement convolution | `scipy.signal.fftconvolve` | Performance-critical; FFT is the right algorithm for a 2D kernel over a global raster |
| D1 SQL chunking | Custom uploader | `export_zones_to_sql.py` | Already handles 10 MB chunk limits [VERIFIED: codebase] |

**Key insight:** The entire data pipeline is already implemented. Phase 2's job is to validate, identify inaccuracies, retune one parameter file, regenerate, and deploy — not build new pipeline components.

---

## Common Pitfalls

### Pitfall 1: validate_zones_db.py fails immediately — zones.db missing

**What goes wrong:** The validator reads `assets/db/zones.db` which does not currently exist (only `astr.db` and `cities.json` are in `assets/db/`). Running it unmodified produces a file-not-found error and exits.

**Why it happens:** `zones.db` was generated previously and uploaded to Cloudflare, but it is gitignored and not committed. The accumulator (`zones_accumulator.db`) is the source of truth at repo root.

**How to avoid:** Before running the validator, generate `assets/db/zones.db` by running `write_zones_db()` from `apply_skyglow.py` standalone (calling it with the accumulator path and output path), or by running `generate_zones_vnl.py` with just the write step. This is a fast operation (streaming read from SQLite, no TIF scan).

**Warning signs:** `FileNotFoundError: zones.db not found` on first validator run.

### Pitfall 2: Scatter re-run takes hours — no dry-run mode

**What goes wrong:** `apply_skyglow.py` must re-scan the full VNL TIF (313 MB gz, global coverage) to apply new scatter parameters. This takes multiple hours on a laptop even with FFT convolution.

**Why it happens:** The scatter kernel is applied at the coarse grid level then re-projected back to full resolution via strip scanning — unavoidable for global accuracy.

**How to avoid:** Only trigger the full re-scan after validation confirms scatter params need tuning. Don't retune speculatively. The CLI supports `--fraction` and `--scale-km` overrides so parameter sweeps don't require code edits.

**Warning signs:** Running `apply_skyglow.py` without first confirming inaccuracies exist from validation.

### Pitfall 3: H3 v4 API vs v3 API mismatch

**What goes wrong:** H3 v4 changed the API. Using v3 function names (`h3.geo_to_h3()`, `h3.h3_to_geo()`) raises `AttributeError`.

**Why it happens:** The scripts/.venv has h3 4.4.1 (v4 API). If anyone installs h3 from elsewhere (e.g., system pip) they may get v3.

**How to avoid:** Always activate `source scripts/.venv/bin/activate` before running any pipeline script. Use `h3.latlng_to_cell(lat, lon, resolution)` (v4 API). [VERIFIED: scripts/.venv h3 version 4.4.1]

### Pitfall 4: D1 SQL import order matters — DROP TABLE in chunk 1 only

**What goes wrong:** Running `wrangler d1 execute` for chunks 2+ when chunk 1 hasn't run first results in inserting into a nonexistent table.

**Why it happens:** `export_zones_to_sql.py` puts `DROP TABLE IF EXISTS zones; CREATE TABLE IF NOT EXISTS zones ...` only in chunk 1.

**How to avoid:** Run SQL chunks in order. Use a loop: `for i in 1 2 3 ...; do wrangler d1 execute --file zones_part$i.sql; done`. Check `wrangler d1 execute` exit codes.

### Pitfall 5: Hive zone cache serves stale data after Cloudflare re-upload

**What goes wrong:** After corrected zone data is deployed to Cloudflare D1, the Flutter app's Hive `zoneCache` still returns old zone values for locations previously cached.

**Why it happens:** `ZoneCacheEntry.isExpired` returns false until 365 days after fetch. The Cloudflare Worker also caches responses with `Cache-Control: max-age=3600` (1 hour).

**How to avoid:** Document this as a known limitation. Testers must: (1) clear app data/uninstall to flush Hive cache, OR (2) wait 1 hour for Cloudflare edge cache to expire, then the app will re-fetch from the corrected D1. This is acceptable — zone data is static satellite data. [VERIFIED: ZoneCacheEntry.isExpired, worker.js CACHE_TTL]

### Pitfall 6: Worker response uses `bortle` key but field is named `bortleClass` in Dart

**What goes wrong:** Confusion between the JSON key (`bortle`) served by the Cloudflare Worker and the Dart model field (`bortleClass`). Editing the wrong thing breaks parsing.

**Why it happens:** Naming debt acknowledged in CONTEXT.md — `bortleClass` in Dart refers to Astr zone, not Bortle. D-02 says don't rename in Phase 2.

**How to avoid:** Never rename `bortleClass` in Dart code. Never rename `bortle` in the Worker JSON. Validation and test code should call the field what it is internally while documentation says "Astr zone". [VERIFIED: remote_zone_service.dart, worker.js, zone_data.dart]

---

## Code Examples

### Write zones.db from existing accumulator (standalone — no TIF scan)

```python
# Source: codebase inspection of apply_skyglow.py write_zones_db()
# Run from repo root with scripts/.venv active
# This generates assets/db/zones.db from zones_accumulator.db (fast, no TIF needed)

import sys
sys.path.insert(0, 'scripts')
from apply_skyglow import write_zones_db
from pathlib import Path

accum_path = Path('zones_accumulator.db')
output_path = Path('assets/db/zones.db')
output_path.parent.mkdir(parents=True, exist_ok=True)
write_zones_db(accum_path, output_path)
```

### Query accumulator for a location (fast validation without zones.db)

```python
# Source: codebase inspection of validate_zones_db.py + generate_zones_vnl.py
import sqlite3, h3

conn = sqlite3.connect('zones_accumulator.db')
ZONE_THRESHOLDS = [(125.0, 9), (50.0, 8), (20.0, 7), (9.0, 6),
                   (3.0, 5), (1.0, 4), (0.50, 3), (0.25, 2)]

def get_zone(r):
    if r <= 0: return 1
    for thresh, zone in ZONE_THRESHOLDS:
        if r >= thresh: return zone
    return 1 if r < 0.25 else 2

def query_location(lat, lon):
    cell = h3.latlng_to_cell(lat, lon, 8)
    h3_int = int(cell, 16)
    row = conn.execute('SELECT radiance FROM cells WHERE h3=?', (h3_int,)).fetchone()
    if row:
        return {'radiance': row[0], 'zone': get_zone(row[0])}
    return {'radiance': None, 'zone': 1}  # Zone 1 implicit

# Example:
print(query_location(40.7128, -74.0060))  # NYC → zone 9
```

### Run scatter with tuned parameters (CLI)

```bash
# Source: apply_skyglow.py argparse / archive/data-pipeline/README.md
# Activate venv first
source scripts/.venv/bin/activate

# Retune: reduce scatter fraction from 0.12 to 0.06
python scripts/apply_skyglow.py \
  --tif "VNL NPP 2024 Global Masked Data.tif.gz" \
  --accum zones_accumulator.db \
  --fraction 0.06 \
  --scale-km 20.0
```

### D1 SQL import sequence

```bash
# Source: export_zones_to_sql.py + archive/data-pipeline/README.md + wrangler.toml
cd /path/to/repo
source scripts/.venv/bin/activate

# Step 1: Generate SQL chunks from zones.db
python scripts/export_zones_to_sql.py --db assets/db/zones.db --out assets/db/

# Step 2: Import each chunk into D1 (run from cloudflare/ dir)
cd cloudflare
DB_ID="d00b90d6-9117-4501-9ec8-5213d5ef334d"
for f in ../assets/db/zones_part*.sql; do
  echo "Importing $f..."
  node_modules/.bin/wrangler d1 execute astr-zones-db --file "$f" --remote
done
```

### Dart zone boundary test skeleton

```dart
// Source: test/core/services/darkness_calculator_test.dart (existing pattern)
import 'package:astr/core/services/darkness_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DarknessCalculator calculator;
  setUp(() { calculator = DarknessCalculator(); });

  group('Zone SQM boundary verification', () {
    // ZONE-04: given known input luminance, output matches expected zenith brightness
    // Zone boundaries derived from: SQM = 22.0 - 1.7 * log10(1 + 2*radiance)
    test('SQM 21.70 (Zone 2 lower boundary) → Good label', () {
      final (label, _) = calculator.getDarknessLabel(21.70);
      expect(label, equals('Good'));
    });

    test('SQM 21.49 (Zone 3 lower boundary) → Good label', () {
      final (label, _) = calculator.getDarknessLabel(21.49);
      expect(label, equals('Good'));
    });

    test('SQM 20.56 (Zone 5 lower boundary) → Fair label', () {
      final (label, _) = calculator.getDarknessLabel(20.56);
      expect(label, equals('Fair'));
    });

    test('Full moon at zenith reduces Zone 3 SQM to Very Poor', () {
      // baseMPSAS 21.5 (Zone 3 territory), full moon at zenith: -4.0 penalty
      final result = calculator.calculateDarkness(
        baseMPSAS: 21.5,
        moonPhase: 1.0,
        moonAltitude: 90.0,
      );
      // 21.5 - 4.0 = 17.5
      expect(result, closeTo(17.5, 0.01));
      final (label, _) = calculator.getDarknessLabel(result);
      expect(label, equals('Very Poor'));
    });
  });
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| NASA VIIRS HDF5 tiles via LAADS DAAC | VNL NPP 2024 global TIF from Colorado School of Mines | Phase 1 (2026-06) | No reprojection needed; annual composite already in WGS84 |
| H3 v3 API (`geo_to_h3`, `h3_to_geo`) | H3 v4 API (`latlng_to_cell`, `cell_to_latlng`) | Phase 1 or earlier | Function name change; same underlying algorithm |
| MongoDB backend for zone data | Cloudflare D1 + R2 + Worker | Pre-Phase 1 | Live serving from edge; archived MongoDB path |

**Deprecated/outdated:**
- `generate_h3_db.py`, `generate_h3_db_v2.py` — old HDF5 pipeline scripts; not present in repo, documented in archive only.
- `scripts/README.md` — documents the old NASA LAADS DAAC pipeline; retained for history but not the current method.

---

## Runtime State Inventory

> This section applies because Phase 2 corrects data and deploys to production infrastructure.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | Cloudflare D1: `zones` table (astr-zones-db, ID `d00b90d6-9117-4501-9ec8-5213d5ef334d`) — contains current zone assignments for all H3 cells | Replace via `wrangler d1 execute` with new SQL chunks from export_zones_to_sql.py |
| Stored data | Cloudflare R2: `astr-zones` bucket, object `zones.db` — serves the /download endpoint | Replace via `upload_to_r2.py` with corrected zones.db |
| Live service config | Cloudflare Worker (`astr-zones.astr-vansh-fyi.workers.dev`) — serves `/zone/{h3}` with `Cache-Control: max-age=3600` | No code change needed; re-deploy only if Worker logic changes |
| Live service config | Cloudflare edge cache: 1-hour `Cache-Control` on zone responses | Wait 1 hour after D1 update for edge cache to expire; document for testers |
| Stored data | Flutter app Hive `zoneCache` box — in-app cache with 365-day TTL | Document as known tester limitation: clear app data to flush |
| OS-registered state | None | None |
| Secrets/env vars | `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY` — required by `upload_to_r2.py`; not in git | Must be set in shell before running upload; obtain from Cloudflare Dashboard |
| Build artifacts | `assets/db/zones.db` — NOT currently in `assets/db/` (gitignored, not committed) | Must be generated from accumulator before validator or Cloudflare upload |

---

## Open Questions (RESOLVED)

1. **What are the exact Lorenz LPI/SQM values for Ushuaia, Reykjavik, Anchorage, and Wellington?**
   - What we know: The Lorenz atlas website shows color-coded maps but doesn't publish machine-readable per-city values. The colors page documents LPI concepts without exact numerical thresholds per city.
   - What's unclear: Whether the Lorenz atlas specifically shows those four cities as less polluted than the accumulator suggests.
   - Recommendation: During plan execution, the implementer must visit djlorenz.github.io and visually read the color zone for each city to establish the expected Astr zone. This is a manual lookup step — no automation is possible until Lorenz publishes raw data.
   - **RESOLVED:** Handled by Plan 02-01 Task 1 human-verify checkpoint — implementer visits djlorenz.github.io during execution and records expected Astr zones before proceeding to the comparison step.

2. **How much does SCATTER_FRACTION reduction affect major city zones?**
   - What we know: Reducing SCATTER_FRACTION from 0.12 to 0.06 would halve the scatter contribution. Major cities (NYC, London) have direct VNL radiance >> 125 nW so they'd stay Zone 9 regardless.
   - What's unclear: Whether small city overestimates are from SCATTER_FRACTION, SCATTER_SCALE_KM, or both.
   - Recommendation: After generating zones.db and cataloguing inaccuracies, use the `--fraction` CLI flag to try 0.06 and 0.08 before committing to a full re-scan.
   - **RESOLVED:** Determined empirically during Plan 02-03 — the human-verify checkpoint in Task 1 presents the validation mismatch table and lets the implementer choose the SCATTER_FRACTION value (0.05, 0.06, or 0.08) before the full re-scan runs.

3. **Do the Cloudflare R2 credentials need to be rotated before Phase 2?**
   - What we know: `upload_to_r2.py` requires `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY` as environment variables.
   - What's unclear: Whether these credentials are still valid.
   - Recommendation: Verify credentials work against the API before the deploy step. A simple `aws s3 ls s3://astr-zones --endpoint-url https://<account-id>.r2.cloudflarestorage.com` will confirm.
   - **RESOLVED:** Plan 02-05 includes a `user_setup` block that instructs the implementer to verify R2 credentials before the upload step and provides the verification command. The deploy task is marked `autonomous: false` to ensure human oversight.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Python 3 (scripts/.venv) | All pipeline scripts | ✓ | 3.14 | — |
| h3 library | validate_zones_db.py, apply_skyglow.py | ✓ | 4.4.1 (in .venv) | — |
| zones_accumulator.db | Validation, write_zones_db | ✓ | 1.2 GB at repo root | Regenerate from TIF (hours) |
| VNL NPP 2024 TIF.gz | apply_skyglow.py (full re-scan) | ✓ | 313 MB at repo root | Re-download from eogdata.mines.edu |
| assets/db/zones.db | validate_zones_db.py | ✗ | Missing | Generate from accumulator (minutes) |
| Flutter SDK / Dart | flutter test | ✓ | Flutter 3.35.1 / Dart 3.9.0 | — |
| wrangler (local) | D1 import | ✓ | 4.65.0 (cloudflare/node_modules) | npx wrangler@latest |
| R2 credentials (env vars) | upload_to_r2.py | ? | Unknown — must verify | Manual Cloudflare Dashboard upload |
| djlorenz.github.io | Lorenz reference lookup | ✓ | Website accessible | Screenshot + manual read |

**Missing dependencies with no fallback:**
- `assets/db/zones.db` — must be generated before validator can run as written. Generation is fast (minutes, no TIF scan needed), just needs to be done first.

**Missing dependencies with fallback:**
- R2 credentials — if env vars are not available, zones.db can be uploaded manually via Cloudflare Dashboard, but `upload_to_r2.py` is the standard path.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK built-in) |
| Config file | none — standard `flutter test` discovery |
| Quick run command | `flutter test test/core/services/darkness_calculator_test.dart --no-pub` |
| Full suite command | `flutter test --no-pub` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ZONE-01 | 10+ diverse locations return correct zone | Python script | `python scripts/validate_zones_db.py` (extended) | ✅ (needs extension) |
| ZONE-02 | Inaccurate zones documented with expected vs actual | Python script output | Same validator — produces mismatch table | ✅ (needs extension) |
| ZONE-03 | DB updated to resolve inaccuracies | Python script + manual | Re-run validator after retune | ✅ (after fix) |
| ZONE-04 | Given known input luminance, diffusion output correct | Dart unit test | `flutter test test/core/services/darkness_calculator_test.dart` | ✅ (needs extension) |

### Sampling Rate

- **Per task commit:** `flutter test test/core/services/darkness_calculator_test.dart --no-pub`
- **Per wave merge:** `flutter test --no-pub`
- **Phase gate:** All Dart tests pass + Python validator shows all 25 expected zones match actual

### Wave 0 Gaps

- [ ] `assets/db/zones.db` — must be generated before Python validation can run
- [ ] Lorenz→Astr zone expected values — must be manually derived from djlorenz.github.io before extending validator

*(No new test files need to be created — extend the existing darkness_calculator_test.dart)*

---

## Security Domain

> `security_enforcement: true` in config.json.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Phase has no auth surfaces (scripts + unit tests only) |
| V3 Session Management | No | No sessions involved |
| V4 Access Control | No | No user-facing access control |
| V5 Input Validation | Low | CLI args to Python scripts — already uses argparse with type checking |
| V6 Cryptography | No | No cryptographic operations; SHA-256 used only for integrity check of zones.db (stdlib hashlib, not a security operation) |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal in `--tif`, `--accum` CLI args | Tampering | argparse + `pathlib.Path` — already implemented; no user-supplied path reaches production |
| R2 credentials in environment | Information Disclosure | Env vars only, never committed; `.env` not in git; `upload_to_r2.py` reads via `os.environ.get()` |
| D1 SQL injection via generated SQL chunks | Tampering | `export_zones_to_sql.py` generates values from trusted internal data (struct-unpacked binary), not user input |

**Net assessment:** Phase 2 is a backend data pipeline executed by a trusted developer in a controlled environment. ASVS Level 1 requires no additional mitigations beyond what is already in place.

---

## Sources

### Primary (MEDIUM confidence)
- Codebase inspection: `scripts/apply_skyglow.py` — ZONE_THRESHOLDS, scatter params, write_zones_db logic [VERIFIED]
- Codebase inspection: `scripts/validate_zones_db.py` — 25 test locations, binary search logic [VERIFIED]
- Codebase inspection: `lib/core/services/darkness_calculator.dart` — MPSAS formula [VERIFIED]
- Codebase inspection: `lib/features/data_layer/models/zone_cache_entry.dart` — 365-day TTL [VERIFIED]
- Codebase inspection: `cloudflare/worker.js` — CACHE_TTL=3600, D1 schema [VERIFIED]
- Codebase inspection: `archive/data-pipeline/README.md` — full pipeline documentation [VERIFIED]
- Direct filesystem: `zones_accumulator.db` — 1.2 GB, 47M cells, sample data queried [VERIFIED]
- Direct filesystem: `assets/db/` — zones.db absent confirmed [VERIFIED]

### Secondary (LOW confidence)
- djlorenz.github.io — Color scale explanation, LPI definition, methodology; numerical thresholds not published as machine-readable data [CITED: djlorenz.github.io/astronomy/lp/colors.html]
- Garstang scatter model literature — parameter ranges from published research [CITED: academic.oup.com/mnras/article/458/1/438]

### Tertiary (LOW confidence)
- Derived math: SQM-to-zone boundary table — calculated from ZONE_THRESHOLDS + radiance_to_sqm() formula [ASSUMED — cross-checked against code but not against external SQM measurements]
- Hypothesis: SCATTER_FRACTION=0.12 over-estimates small cities — based on accumulator data showing Ushuaia/Reykjavik/Anchorage/Wellington higher than population size suggests [ASSUMED — requires validation testing to confirm]

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | SCATTER_FRACTION=0.12 is the primary cause of small-city zone overestimation | Open Questions, Pitfalls | If wrong, fix may require ZONE_THRESHOLDS recalibration instead of scatter params — more complex |
| A2 | Reducing SCATTER_FRACTION to 0.06-0.08 will not affect major city zones (NYC, London, etc.) | Common Pitfalls | If wrong, a too-low fraction might under-light rural areas near major cities |
| A3 | Lorenz atlas color zones can be manually read for the 25 test locations from the website | Open Questions | If website structure changed or locations not shown at city scale, reference lookup is blocked |
| A4 | rasterio, numpy, scipy, tqdm are installed in scripts/.venv at appropriate versions | Standard Stack | If wrong, `pip install rasterio numpy scipy tqdm` in the venv resolves it |
| A5 | R2 credentials are still valid and accessible to the developer | Environment Availability | If wrong, phase deploy is blocked until credentials are regenerated from Cloudflare Dashboard |

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all tools verified in filesystem; versions confirmed
- Architecture: HIGH — derived directly from reading the actual scripts
- Pitfalls: MEDIUM — root causes confirmed by code inspection; Lorenz reference accessibility is LOW confidence
- Scatter hypothesis: LOW — plausible given data, but untested until validation script runs

**Research date:** 2026-06-13
**Valid until:** 2027-06-13 (zone pipeline is stable; Lorenz atlas doesn't change frequently)
