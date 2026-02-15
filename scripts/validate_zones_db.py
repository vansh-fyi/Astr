#!/usr/bin/env python3
"""
Validate zones.db coverage by checking specific test locations.

This script reads the binary zones.db file and verifies that H3 indices
for major world cities are present in the database.
"""

import struct
from pathlib import Path
import sys

# Test locations: (name, lat, lon)
TEST_LOCATIONS = [
    # Major cities
    ("New York, USA", 40.7128, -74.0060),
    ("London, UK", 51.5074, -0.1278),
    ("Tokyo, Japan", 35.6762, 139.6503),
    ("Sydney, Australia", -33.8688, 151.2093),
    ("Paris, France", 48.8566, 2.3522),
    ("Berlin, Germany", 52.5200, 13.4050),
    ("Mumbai, India", 19.0760, 72.8777),
    ("São Paulo, Brazil", -23.5505, -46.6333),
    ("Cairo, Egypt", 30.0444, 31.2357),
    ("Cape Town, South Africa", -33.9249, 18.4241),
    
    # Dark sky locations
    ("Death Valley, USA", 36.5054, -117.0794),
    ("Atacama Desert, Chile", -24.5000, -69.2500),
    ("Teide, Canary Islands", 28.2916, -16.5094),
    ("Mauna Kea, Hawaii", 19.8208, -155.4681),
    ("Namib Desert, Namibia", -24.7500, 15.5000),
    
    # Remote areas
    ("Antarctica McMurdo", -77.8419, 166.6863),
    ("Greenland Nuuk", 64.1836, -51.7214),
    ("Sahara Desert", 23.4162, 25.6628),
    ("Gobi Desert, Mongolia", 42.5000, 103.5000),
    ("Outback, Australia", -25.0000, 134.0000),
    
    # Edge cases
    ("Reykjavik, Iceland", 64.1466, -21.9426),
    ("Singapore", 1.3521, 103.8198),
    ("Wellington, NZ", -41.2865, 174.7762),
    ("Anchorage, Alaska", 61.2181, -149.9003),
    ("Ushuaia, Argentina", -54.8019, -68.3030),
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
        print(f"❌ zones.db not found at: {db_path}")
        sys.exit(1)
    
    print(f"Validating zones.db: {db_path}")
    print(f"File size: {db_path.stat().st_size / (1024**3):.2f} GB")
    print(f"\nTesting {len(TEST_LOCATIONS)} locations...\n")
    
    found = 0
    not_found = []
    
    for name, lat, lon in TEST_LOCATIONS:
        h3_index = lat_lon_to_h3(lat, lon, 8)  # Resolution 8 to match zones.db
        result = binary_search_zones_db(db_path, h3_index)
        
        if result:
            found += 1
            print(f"✅ {name}: Bortle {result['bortle']}, SQM {result['sqm']}")
        else:
            not_found.append((name, lat, lon, hex(h3_index)))
            print(f"❌ {name}: NOT FOUND (H3: {hex(h3_index)})")
    
    print(f"\n{'='*60}")
    print(f"RESULTS: {found}/{len(TEST_LOCATIONS)} locations found ({100*found/len(TEST_LOCATIONS):.1f}%)")
    
    if not_found:
        print(f"\n⚠️  Missing locations ({len(not_found)}):")
        for name, lat, lon, h3 in not_found:
            print(f"   - {name} ({lat}, {lon})")
    else:
        print("\n✅ ALL LOCATIONS HAVE ZONE DATA!")
    
    return len(not_found) == 0

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
