# Phase 2: Zone Data Validation - Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 4 (2 Python scripts, 1 Dart test file, 1 binary asset)
**Analogs found:** 3 / 4 (zones.db is generated, no analog)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scripts/validate_zones_db.py` | utility (validation script) | batch | self (existing file, EXTEND) | exact — file is its own analog |
| `scripts/apply_skyglow.py` | utility (data transform script) | batch / file-I/O | self (existing file, RETUNE params only) | exact — file is its own analog |
| `test/core/services/darkness_calculator_test.dart` | test | request-response (pure math) | `test/core/services/seeing_calculator_test.dart` | role-match |
| `assets/db/zones.db` | binary data asset | file-I/O | none — generated from `zones_accumulator.db` via `write_zones_db()` | no analog |

---

## Pattern Assignments

### `scripts/validate_zones_db.py` (utility, batch — EXTEND)

**Analog:** self — the existing script at `scripts/validate_zones_db.py`

**Current imports block** (lines 1-11):
```python
#!/usr/bin/env python3
"""
Validate zones.db coverage by checking specific test locations.
...
"""

import struct
from pathlib import Path
import sys
```
**Extension imports to add** — h3 is already used inside `lat_lon_to_h3()` via lazy import. No new top-level imports needed.

**Core pattern — TEST_LOCATIONS list** (lines 14-47):
```python
# Existing tuple shape: (name, lat, lon)
TEST_LOCATIONS = [
    ("New York, USA", 40.7128, -74.0060),
    ("London, UK", 51.5074, -0.1278),
    ...
    ("Ushuaia, Argentina", -54.8019, -68.3030),
]
```
Extension adds a 4th element — expected Astr zone — making each entry `(name, lat, lon, expected_zone)`. The existing 25 locations are kept exactly; only the tuple shape and the loop body change.

**Core pattern — binary search function** (lines 58-98):
```python
def binary_search_zones_db(db_path: Path, target_h3: int) -> dict | None:
    HEADER_SIZE = 16
    RECORD_SIZE = 20

    with open(db_path, 'rb') as f:
        header = f.read(HEADER_SIZE)
        magic = header[:8]
        record_count = struct.unpack('<Q', header[8:16])[0]

        left, right = 0, record_count - 1
        while left <= right:
            mid = (left + right) // 2
            offset = HEADER_SIZE + mid * RECORD_SIZE
            f.seek(offset)
            record = f.read(RECORD_SIZE)
            h3_index = struct.unpack('<Q', record[:8])[0]
            if h3_index == target_h3:
                bortle = struct.unpack('B', record[8:9])[0]
                ratio  = struct.unpack('<f', record[9:13])[0]
                sqm    = struct.unpack('<f', record[13:17])[0]
                return {'h3': hex(h3_index), 'bortle': bortle,
                        'ratio': round(ratio, 2), 'sqm': round(sqm, 2)}
            elif h3_index < target_h3:
                left = mid + 1
            else:
                right = mid - 1
    return None
```
Do NOT rewrite this function. The extension calls it unchanged and adds expected-zone comparison around the call site.

**H3 conversion pattern** (lines 49-56):
```python
def lat_lon_to_h3(lat: float, lon: float, resolution: int = 8) -> int:
    try:
        import h3
        return int(h3.latlng_to_cell(lat, lon, resolution), 16)
    except ImportError:
        print("Error: h3 library not installed. Run: pip install h3")
        sys.exit(1)
```
Always use `h3.latlng_to_cell()` (v4 API). Never use `h3.geo_to_h3()` (v3, removed).

**Extension pattern — expected-zone comparison** (new loop body replacing lines 114-123):
```python
# Extended loop: compare actual vs. expected zone
results = []
for name, lat, lon, expected_zone in TEST_LOCATIONS:
    h3_index = lat_lon_to_h3(lat, lon, 8)
    result = binary_search_zones_db(db_path, h3_index)
    actual_zone = result['bortle'] if result else 1
    status = 'PASS' if actual_zone == expected_zone else 'FAIL'
    results.append({
        'name': name, 'expected': expected_zone,
        'actual': actual_zone, 'status': status,
        'radiance': result['ratio'] if result else None,
        'sqm': result['sqm'] if result else None,
    })
    icon = 'OK' if status == 'PASS' else 'FAIL'
    print(f"[{icon}] {name}: expected Astr zone {expected_zone}, "
          f"got {actual_zone} (radiance={results[-1]['radiance']})")

# Summary table
failures = [r for r in results if r['status'] == 'FAIL']
print(f"\nRESULTS: {len(results)-len(failures)}/{len(results)} PASS")
if failures:
    print("\nMismatches (expected vs actual Astr zone):")
    for r in failures:
        print(f"  {r['name']}: expected {r['expected']}, got {r['actual']}, "
              f"radiance={r['radiance']}")
```

**ZONE_THRESHOLDS constant** — copy from `apply_skyglow.py` (lines 50-53) and add `radiance_to_zone()` to the validator for deriving expected zones from Lorenz radiance values:
```python
ZONE_THRESHOLDS = [
    (125.0, 9), (50.0, 8), (20.0, 7), (9.0, 6),
    (3.0, 5),   (1.0, 4),  (0.50, 3), (0.25, 2),
]

def radiance_to_zone(r: float) -> int:
    if r <= 0: return 1
    for thresh, zone in ZONE_THRESHOLDS:
        if r >= thresh: return zone
    return 1 if r < 0.25 else 2
```

**Terminology constraint (D-02):** All new print strings and comments must say "Astr zone", not "Bortle". The dict key `result['bortle']` from `binary_search_zones_db()` is internal naming debt — do not rename in Phase 2.

---

### `scripts/apply_skyglow.py` (utility, batch/file-I/O — RETUNE parameters only)

**Analog:** self — the existing script at `scripts/apply_skyglow.py`

This file is NOT structurally changed. Only the scalar constants at lines 41-45 are tuned:

**Current scatter parameters** (lines 41-45):
```python
# Scatter kernel parameters (Garstang-inspired)
SCATTER_FRACTION = 0.12  # 12% of upward light scatters horizontally
SCATTER_SCALE_KM = 20.0  # exponential decay length
SCATTER_POWER = 2.5      # power-law falloff
MAX_RADIUS_KM = 80.0     # truncation radius
D_REF_KM = 10.0          # reference distance for power law
PIXEL_KM = 5.55          # km per coarse pixel at equator
```
Primary tuning levers: `SCATTER_FRACTION` (currently 0.12, hypothesis: reduce to 0.05-0.08) and `SCATTER_SCALE_KM`.

**CLI override pattern** (lines 292-300) — use CLI flags instead of code edits for parameter sweeps:
```python
parser.add_argument('--fraction', type=float, default=SCATTER_FRACTION)
parser.add_argument('--scale-km', type=float, default=SCATTER_SCALE_KM)
args = parser.parse_args()
SCATTER_FRACTION = args.fraction
SCATTER_SCALE_KM = args.scale_km
```
Invocation: `python scripts/apply_skyglow.py --tif "VNL NPP 2024 Global Masked Data.tif.gz" --fraction 0.06 --scale-km 20.0`

**write_zones_db() function** (lines 221-283) — call this standalone to generate `assets/db/zones.db` without the expensive TIF scan:
```python
def write_zones_db(accum_path, output_path):
    conn = sqlite3.connect(str(accum_path))
    total = conn.execute('SELECT COUNT(*) FROM cells').fetchone()[0]
    with open(output_path, 'wb') as f:
        f.write(b'ASTR\x01\x00\x00\x00')          # 8-byte magic
        count_pos = f.tell()
        f.write(struct.pack('<Q', 0))               # 8-byte record count placeholder
        cursor = conn.execute('SELECT h3, radiance FROM cells ORDER BY h3')
        while True:
            rows = cursor.fetchmany(100_000)
            if not rows: break
            for h3_int, rad in rows:
                zone = radiance_to_zone(rad)
                if zone <= 1: continue              # Zone 1 implicit — not stored
                sqm = radiance_to_sqm(rad)
                f.write(struct.pack('<Q', h3_int))  # 8 bytes
                f.write(struct.pack('B', zone))     # 1 byte
                f.write(struct.pack('<f', rad))     # 4 bytes
                f.write(struct.pack('<f', sqm))     # 4 bytes
                f.write(b'\x00\x00\x00')            # 3 bytes padding → 20-byte record
        f.seek(count_pos)
        f.write(struct.pack('<Q', written))
```
Binary format: 16-byte header (8-byte magic `ASTR\x01\x00\x00\x00` + 8-byte uint64 record count), then N × 20-byte records sorted by H3 index.

---

### `test/core/services/darkness_calculator_test.dart` (test — EXTEND)

**Analog:** `test/core/services/seeing_calculator_test.dart` (role-match: both are pure-math calculator tests with no mocking)

Also directly analogs with `test/core/services/darkness_calculator_test.dart` (exact match — file is extended, not replaced).

**Existing file header pattern** (lines 1-7 of darkness_calculator_test.dart):
```dart
import 'package:astr/core/services/darkness_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for DarknessCalculator
/// Validates r^6 Darkness Model (MPSAS)
/// Reference: docs/calculations.md
void main() {
```
Extension adds a new top-level `group()` inside the existing `main()`. No new imports needed — `flutter_test` covers everything.

**setUp pattern** (lines 9-11 of darkness_calculator_test.dart):
```dart
late DarknessCalculator calculator;

setUp(() {
  calculator = DarknessCalculator();
});
```
The new `group()` block reuses the same `calculator` variable established by `setUp`. Do not add a second `setUp` or a nested `setUp`.

**Existing test structure — core pattern** (lines 14-65, darkness_calculator_test.dart):
```dart
group('DarknessCalculator', () {
  test('should return base MPSAS when moon is below horizon', () {
    final double result = calculator.calculateDarkness(
      baseMPSAS: 21.5,
      moonPhase: 1,
      moonAltitude: -10,
    );
    expect(result, 21.5);
  });

  test('should apply max penalty for Full Moon at Zenith', () {
    final double result = calculator.calculateDarkness(
      baseMPSAS: 22,
      moonPhase: 1,
      moonAltitude: 90,
    );
    // Penalty = 4.0 * 1.0 * sin(90) = 4.0 → 22.0 - 4.0 = 18.0
    expect(result, closeTo(18.0, 0.01));
  });
});
```

**getDarknessLabel test pattern** (lines 67-92, darkness_calculator_test.dart):
```dart
group('getDarknessLabel', () {
  test('should return Excellent for >= 21.5', () {
    expect(calculator.getDarknessLabel(21.5).$1, 'Excellent');
    expect(calculator.getDarknessLabel(22).$1, 'Excellent');
  });

  test('should return Good for 21.0 - 21.49', () {
    expect(calculator.getDarknessLabel(21).$1, 'Good');
    expect(calculator.getDarknessLabel(21.4).$1, 'Good');
  });
  // ...
});
```
Tuple access via `.$1` for the label string. `.$2` is the color int — use it only if testing color values.

**New group to append — zone threshold boundary tests** (ZONE-04):
```dart
group('Zone SQM boundary verification (ZONE-04)', () {
  // SQM boundaries derived from: SQM = 22.0 - 1.7 * log10(1 + 2*radiance)
  // See apply_skyglow.py ZONE_THRESHOLDS for the radiance→zone mapping.

  test('SQM 21.70 (Zone 2 lower boundary, radiance=0.25) returns Good label', () {
    final (String label, _) = calculator.getDarknessLabel(21.70);
    expect(label, equals('Good'));
  });

  test('SQM 21.49 (Zone 3 lower boundary, radiance=0.50) returns Good label', () {
    final (String label, _) = calculator.getDarknessLabel(21.49);
    expect(label, equals('Good'));
  });

  test('SQM 21.19 (Zone 4 lower boundary, radiance=1.0) returns Good label', () {
    final (String label, _) = calculator.getDarknessLabel(21.19);
    expect(label, equals('Good'));
  });

  test('SQM 20.56 (Zone 5 lower boundary, radiance=3.0) returns Fair label', () {
    final (String label, _) = calculator.getDarknessLabel(20.56);
    expect(label, equals('Fair'));
  });

  test('SQM 19.83 (Zone 6 lower boundary, radiance=9.0) returns Poor label', () {
    final (String label, _) = calculator.getDarknessLabel(19.83);
    expect(label, equals('Poor'));
  });

  test('SQM 19.26 (Zone 7 lower boundary, radiance=20.0) returns Poor label', () {
    final (String label, _) = calculator.getDarknessLabel(19.26);
    expect(label, equals('Poor'));
  });

  test('SQM 18.59 (Zone 8 lower boundary, radiance=50.0) returns Very Poor label', () {
    final (String label, _) = calculator.getDarknessLabel(18.59);
    expect(label, equals('Very Poor'));
  });

  test('SQM 17.92 (Zone 9 lower boundary, radiance=125.0) returns Very Poor label', () {
    final (String label, _) = calculator.getDarknessLabel(17.92);
    expect(label, equals('Very Poor'));
  });

  test('Zone 2 boundary SQM (21.70) survives zero-moon calculateDarkness unchanged', () {
    final double result = calculator.calculateDarkness(
      baseMPSAS: 21.70,
      moonPhase: 0.0,
      moonAltitude: 0.0,
    );
    expect(result, closeTo(21.70, 0.001));
  });

  test('Full moon at zenith reduces Zone 3 baseMPSAS (21.49) to Very Poor', () {
    // baseMPSAS 21.49 − 4.0 penalty = 17.49 → Very Poor
    final double result = calculator.calculateDarkness(
      baseMPSAS: 21.49,
      moonPhase: 1.0,
      moonAltitude: 90.0,
    );
    expect(result, closeTo(17.49, 0.01));
    final (String label, _) = calculator.getDarknessLabel(result);
    expect(label, equals('Very Poor'));
  });
});
```

**Key getDarknessLabel thresholds** (from `darkness_calculator.dart` lines 49-60):
```
>= 21.5  → Excellent
>= 21.0  → Good      (covers Zone 2 boundary 21.70 and Zone 3 boundary 21.49 and Zone 4 boundary 21.19)
>= 20.0  → Fair      (covers Zone 5 boundary 20.56)
>= 19.0  → Poor      (covers Zone 6 boundary 19.83 and Zone 7 boundary 19.26)
< 19.0   → Very Poor (covers Zone 8 boundary 18.59 and Zone 9 boundary 17.92)
```

**closeTo matcher pattern** (from seeing_calculator_test.dart and darkness_calculator_test.dart):
```dart
expect(result, closeTo(18.0, 0.01));   // for calculateDarkness() floating-point results
expect(label, equals('Good'));          // for getDarknessLabel() string results
```

---

### `assets/db/zones.db` (binary asset — GENERATE)

**No analog.** This is a generated binary file, not handwritten code.

**Generation command** (run from repo root with `scripts/.venv` active):
```python
# Standalone — no TIF scan needed, reads from zones_accumulator.db directly
import sys
sys.path.insert(0, 'scripts')
from apply_skyglow import write_zones_db
from pathlib import Path

write_zones_db(
    accum_path=Path('zones_accumulator.db'),
    output_path=Path('assets/db/zones.db'),
)
```

**Binary format** (from `apply_skyglow.py` `write_zones_db()` and `validate_zones_db.py` `binary_search_zones_db()`):
- Header: 16 bytes — `b'ASTR\x01\x00\x00\x00'` (8 bytes) + uint64 record count little-endian (8 bytes)
- Records: 20 bytes each, sorted ascending by H3 index (uint64)
  - Bytes 0-7: H3 index (uint64 little-endian)
  - Byte 8: Astr zone (uint8, 2-9; Zone 1 not stored — implicit for missing cells)
  - Bytes 9-12: radiance float32 little-endian
  - Bytes 13-16: SQM float32 little-endian
  - Bytes 17-19: padding `\x00\x00\x00`

---

## Shared Patterns

### Python script module-guard pattern
**Source:** `scripts/validate_zones_db.py` (lines 137-139), `scripts/apply_skyglow.py` (lines 289+)
**Apply to:** Any new Python helper or standalone invocation
```python
if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
```

### H3 v4 API
**Source:** `scripts/validate_zones_db.py` (line 53), `scripts/apply_skyglow.py` (line 185)
**Apply to:** Any code that converts lat/lon to H3 cells
```python
# v4 API — always use this form
h3_cell = h3.latlng_to_cell(lat, lon, resolution)   # returns hex string
h3_int  = int(h3_cell, 16)                           # convert to int for DB lookup
```
Never use `h3.geo_to_h3()` (v3, not installed).

### Zone radiance formula
**Source:** `scripts/apply_skyglow.py` (lines 50-60)
**Apply to:** `validate_zones_db.py` extension, any helper that maps radiance to zone
```python
ZONE_THRESHOLDS = [
    (125.0, 9), (50.0, 8), (20.0, 7), (9.0, 6),
    (3.0, 5),   (1.0, 4),  (0.50, 3), (0.25, 2),
]

def radiance_to_zone(r: float) -> int:
    if r <= 0: return 1
    for thresh, zone in ZONE_THRESHOLDS:
        if r >= thresh: return zone
    return 1 if r < 0.25 else 2

def radiance_to_sqm(r: float) -> float:
    if r <= 0: return 22.0
    return max(16.0, min(22.0, 22.0 - 1.7 * math.log10(1.0 + 2.0 * r)))
```

### Dart test file structure
**Source:** `test/core/services/darkness_calculator_test.dart` (lines 1-13)
**Apply to:** Any new Dart test group added to this file
```dart
import 'package:astr/core/services/darkness_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DarknessCalculator calculator;

  setUp(() {
    calculator = DarknessCalculator();
  });

  group('GroupName', () {
    test('description', () {
      // arrange
      // act
      // assert
    });
  });
}
```
Test subject variable is named descriptively (here `calculator`), not `sut`. File-level doc comment with `///` names the class under test and references spec IDs where applicable.

### Dart tuple destructuring pattern
**Source:** `test/core/services/darkness_calculator_test.dart` (lines 69-75)
**Apply to:** Any test calling `getDarknessLabel()`
```dart
// Method returns (String, int) — access via positional record syntax
final (String label, _) = calculator.getDarknessLabel(mpsas);
// OR via $1/$2 accessors:
expect(calculator.getDarknessLabel(21.5).$1, 'Excellent');
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `assets/db/zones.db` | binary data asset | file-I/O | Generated binary output; no code to pattern-match against — use `write_zones_db()` in `apply_skyglow.py` |

---

## Metadata

**Analog search scope:** `scripts/`, `test/core/services/`, `lib/core/services/`
**Files read:** `scripts/validate_zones_db.py`, `scripts/apply_skyglow.py` (lines 1-300), `lib/core/services/darkness_calculator.dart`, `test/core/services/darkness_calculator_test.dart`, `test/core/services/seeing_calculator_test.dart`
**Pattern extraction date:** 2026-06-13
