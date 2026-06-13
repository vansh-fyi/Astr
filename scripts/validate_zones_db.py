#!/usr/bin/env python3
"""
Validate zones.db coverage by checking specific test locations.

This script reads the binary zones.db file and verifies that H3 indices
for major world cities are present in the database. Each location is compared
against an expected Astr zone derived from the Lorenz Light Pollution Atlas
(djlorenz.github.io/astronomy/lp/), cross-referenced with ZONE_THRESHOLDS.

Reference: .planning/phases/02-zone-data-validation/02-CONTEXT.md decisions D-01 through D-06
"""

import struct
from pathlib import Path
import sys

# Zone thresholds (copied from apply_skyglow.py ZONE_THRESHOLDS).
# Used for reference; expected_zone values in TEST_LOCATIONS were derived by
# manual lookup on the Lorenz Light Pollution Atlas and conversion via these thresholds.
# Zone 1 is implicit for cells not stored in zones.db (radiance < 0.25 nW/cm2/sr).
ZONE_THRESHOLDS = [
    (125.0, 9), (50.0, 8), (20.0, 7), (9.0, 6),
    (3.0, 5), (1.0, 4), (0.50, 3), (0.25, 2),
]

def radiance_to_zone(r: float) -> int:
    """Convert radiance (nW/cm2/sr) to Astr zone number (1-9)."""
    if r <= 0: return 1
    for thresh, zone in ZONE_THRESHOLDS:
        if r >= thresh: return zone
    return 1 if r < 0.25 else 2

# Test locations: (name, lat, lon, expected_zone)
# expected_zone derived from Lorenz Light Pollution Atlas (djlorenz.github.io/astronomy/lp/)
# cross-referenced with ZONE_THRESHOLDS radiance scale. D-02: Astr zone, not Bortle.
TEST_LOCATIONS = [
    # Major cities
    ("New York, USA", 40.7128, -74.0060, 9),
    ("London, UK", 51.5074, -0.1278, 9),
    ("Tokyo, Japan", 35.6762, 139.6503, 9),
    ("Sydney, Australia", -33.8688, 151.2093, 8),
    ("Paris, France", 48.8566, 2.3522, 9),
    ("Berlin, Germany", 52.5200, 13.4050, 8),
    ("Mumbai, India", 19.0760, 72.8777, 9),
    ("São Paulo, Brazil", -23.5505, -46.6333, 9),
    ("Cairo, Egypt", 30.0444, 31.2357, 9),
    ("Cape Town, South Africa", -33.9249, 18.4241, 7),

    # Dark sky locations
    ("Death Valley, USA", 36.5054, -117.0794, 1),
    ("Atacama Desert, Chile", -24.5000, -69.2500, 1),
    ("Teide, Canary Islands", 28.2916, -16.5094, 3),
    ("Mauna Kea, Hawaii", 19.8208, -155.4681, 1),
    ("Namib Desert, Namibia", -24.7500, 15.5000, 1),

    # Remote areas
    ("Antarctica McMurdo", -77.8419, 166.6863, 1),
    ("Greenland Nuuk", 64.1836, -51.7214, 5),
    ("Sahara Desert", 23.4162, 25.6628, 1),
    ("Gobi Desert, Mongolia", 42.5000, 103.5000, 1),
    ("Outback, Australia", -25.0000, 134.0000, 1),

    # Edge cases
    ("Reykjavik, Iceland", 64.1466, -21.9426, 7),
    ("Singapore", 1.3521, 103.8198, 9),
    ("Wellington, NZ", -41.2865, 174.7762, 7),
    ("Anchorage, Alaska", 61.2181, -149.9003, 9),
    ("Ushuaia, Argentina", -54.8019, -68.3030, 7),
]

def lat_lon_to_h3(lat: float, lon: float, resolution: int = 8) -> int:
    """Convert lat/lon to H3 index using h3 library."""
    try:
        import h3
        return int(h3.latlng_to_cell(lat, lon, resolution), 16)
    except ImportError:
        print("Error: h3 library not installed. Run: pip install h3")
        sys.exit(1)

def binary_search_zones_db(db_path: Path, target_h3: int) -> dict | None:
    """Binary search for H3 index in zones.db."""
    HEADER_SIZE = 16
    RECORD_SIZE = 20

    with open(db_path, 'rb') as f:
        # Read header
        header = f.read(HEADER_SIZE)
        magic = header[:8]
        record_count = struct.unpack('<Q', header[8:16])[0]

        print(f"  Database: {record_count:,} records")

        # Binary search
        left, right = 0, record_count - 1

        while left <= right:
            mid = (left + right) // 2
            offset = HEADER_SIZE + mid * RECORD_SIZE

            f.seek(offset)
            record = f.read(RECORD_SIZE)

            h3_index = struct.unpack('<Q', record[:8])[0]

            if h3_index == target_h3:
                bortle = struct.unpack('B', record[8:9])[0]
                ratio = struct.unpack('<f', record[9:13])[0]
                sqm = struct.unpack('<f', record[13:17])[0]
                return {
                    'h3': hex(h3_index),
                    'bortle': bortle,
                    'ratio': round(ratio, 2),
                    'sqm': round(sqm, 2)
                }
            elif h3_index < target_h3:
                left = mid + 1
            else:
                right = mid - 1

        return None

def main():
    db_path = Path(__file__).parent.parent / 'assets' / 'db' / 'zones.db'

    if not db_path.exists():
        print(f"zones.db not found at: {db_path}")
        sys.exit(1)

    print(f"Validating zones.db: {db_path}")
    print(f"File size: {db_path.stat().st_size / (1024**2):.1f} MB")
    print(f"\nTesting {len(TEST_LOCATIONS)} locations...\n")

    # Extended loop: compare actual Astr zone vs. expected Astr zone (D-05, D-06)
    results = []
    for name, lat, lon, expected_zone in TEST_LOCATIONS:
        h3_index = lat_lon_to_h3(lat, lon, 8)  # Resolution 8 to match zones.db
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

    # Summary
    failures = [r for r in results if r['status'] == 'FAIL']
    pass_count = len(results) - len(failures)
    print(f"\nRESULTS: {pass_count}/{len(results)} PASS")

    if failures:
        print("\nMismatches (expected vs actual Astr zone):")
        for r in failures:
            print(f"  {r['name']}: expected {r['expected']}, got {r['actual']}, "
                  f"radiance={r['radiance']}")

    return len(failures) == 0

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
