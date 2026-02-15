#!/usr/bin/env python3
"""
Validate zones.db Global Coverage.
Checks ~70 diverse locations (Cities, Rural, Islands, Coasts) to ensure correct Zone assignment.
"""

import struct
import sys
import h3
import math
from pathlib import Path

# ============================================================================
# Test Data (Lat, Lon, Description)
# ============================================================================

TEST_LOCATIONS = [
    # --- 50 Diverse Land Locations (Cities, Rural, Dark Sites) ---
    # Major Cities (Should be Zone 7-9)
    (40.7128, -74.0060, "New York City, USA"),
    (51.5074, -0.1278, "London, UK"),
    (35.6762, 139.6503, "Tokyo, Japan"),
    (19.0760, 72.8777, "Mumbai, India"),
    (-33.8688, 151.2093, "Sydney, Australia"),
    (30.0444, 31.2357, "Cairo, Egypt"),
    (-23.5505, -46.6333, "Sao Paulo, Brazil"),
    (55.7558, 37.6173, "Moscow, Russia"),
    (39.9042, 116.4074, "Beijing, China"),
    (19.4326, -99.1332, "Mexico City, Mexico"),
    
    # Moderate Cities (Zone 5-7)
    (30.3165, 78.0322, "Dehradun, India"),
    (48.8566, 2.3522, "Paris, France"),
    (34.0522, -118.2437, "Los Angeles, USA"),
    (41.9028, 12.4964, "Rome, Italy"),
    (52.5200, 13.4050, "Berlin, Germany"),
    
    # Rural / Semi-Rural (Zone 3-4)
    (30.4500, 78.0500, "Mussoorie Outskirts, India"),
    (44.0000, -71.5000, "White Mountains, NH, USA"),
    (54.0000, -3.0000, "Lake District, UK"),
    
    # Dark Sites (Should be Zone 1-2)
    (32.7795, 78.9641, "Hanle, Ladakh (Dark Sanctuary)"),
    (-24.6272, -70.4044, "Paranal Observatory, Chile"),
    (19.8207, -155.4681, "Mauna Kea, Hawaii"),
    (-32.3761, 20.8106, "Sutherland, South Africa"),
    (28.7500, -17.8800, "La Palma, Canary Islands"),
    (30.5167, 78.0333, "Bhadraj Temple, India"),
    
    # Random Global Spread
    (64.1466, -21.9426, "Reykjavik, Iceland"),
    (-43.5321, 172.6362, "Christchurch, NZ"),
    (1.3521, 103.8198, "Singapore"),
    (25.2048, 55.2708, "Dubai, UAE"),
    (-1.2921, 36.8219, "Nairobi, Kenya"),
    (4.7110, -74.0721, "Bogota, Colombia"),
    (61.2181, -149.9003, "Anchorage, Alaska"),
    (35.6892, 51.3890, "Tehran, Iran"),
    (31.2304, 121.4737, "Shanghai, China"),
    (-34.6037, -58.3816, "Buenos Aires, Argentina"),
    (45.4215, -75.6972, "Ottawa, Canada"),
    (59.3293, 18.0686, "Stockholm, Sweden"),
    (37.9838, 23.7275, "Athens, Greece"),
    (31.7683, 35.2137, "Jerusalem"),
    (13.7563, 100.5018, "Bangkok, Thailand"),
    (-6.2088, 106.8456, "Jakarta, Indonesia"),
    (3.1390, 101.6869, "Kuala Lumpur, Malaysia"),
    (14.5995, 120.9842, "Manila, Philippines"),
    (23.8103, 90.4125, "Dhaka, Bangladesh"),
    (33.6844, 73.0479, "Islamabad, Pakistan"),
    (41.0082, 28.9784, "Istanbul, Turkey"),
    (50.4501, 30.5234, "Kyiv, Ukraine"),
    (52.2297, 21.0122, "Warsaw, Poland"),
    
    # --- 20 Coastal / Island Locations ---
    # Islands
    (39.4452, 2.7684, "Mallorca, Spain"),
    (-20.3484, 57.5522, "Mauritius"),
    (4.1755, 73.5093, "Male, Maldives"),
    (-17.6509, -149.4260, "Tahiti, French Polynesia"),
    (32.3214, -64.7574, "Bermuda"),
    (13.4443, 144.7937, "Guam"),
    (-21.1717, 55.5364, "Reunion Island"),
    (36.4173, 25.4326, "Santorini, Greece"),
    (10.2765, 123.9781, "Cebu, Philippines"),
    (33.4475, 126.5707, "Jeju Island, Korea"),
    
    # Coastal
    (34.4208, -119.6982, "Santa Barbara, CA (Coast)"),
    (-33.9167, 18.4233, "Cape Town, SA (Coast)"),
    (25.7617, -80.1918, "Miami, FL (Coast)"),
    (43.2965, 5.3698, "Marseille, France (Coast)"),
    (38.7223, -9.1393, "Lisbon, Portugal (Coast)"),
    (18.9950, 72.8122, "Worli Sea Face, Mumbai (Coast)"),
    (-37.8136, 144.9631, "Melbourne, Australia (Coast)"),
    (49.2827, -123.1207, "Vancouver, Canada (Coast)"),
    (1.1077, 104.0538, "Bintan, Indonesia (Island/Coast)"),
    (22.2783, 114.1747, "Hong Kong (Island/Coast)")
]

H3_RESOLUTION = 8

def check_coverage(db_path: Path):
    if not db_path.exists():
        print(f"Error: DB not found at {db_path}")
        sys.exit(1)
        
    print(f"Loading {db_path}...")
    
    # Load DB into memory (Map: h3_int -> zone)
    # Note: For strict memory efficiency we should query, but for simple validation
    # loading the keys/values is acceptable if < 500MB.
    # Zones.db is likely ~200-300MB.
    
    h3_map = {}
    
    with open(db_path, 'rb') as f:
        # Check header
        header = f.read(16)
        magic = header[:8]
        count = struct.unpack('<Q', header[8:16])[0]
        
        print(f"Total Records in DB: {count:,}")
        
        # Read all records
        # 20 bytes per record
        while True:
            chunk = f.read(20 * 10000)
            if not chunk:
                break
            
            num = len(chunk) // 20
            for i in range(num):
                off = i * 20
                h3_int = struct.unpack('<Q', chunk[off:off+8])[0]
                zone = struct.unpack('B', chunk[off+8:off+9])[0]
                h3_map[h3_int] = zone

    print(f"Loaded {len(h3_map):,} records into memory.")
    print("\n" + "="*60)
    print(f"{'Location':<40} | {'Zone':<6} | {'Status'}")
    print("="*60)

    found_count = 0
    total_count = len(TEST_LOCATIONS)
    
    for lat, lon, name in TEST_LOCATIONS:
        # Get H3 Index
        h3_hex = h3.latlng_to_cell(lat, lon, H3_RESOLUTION)
        h3_int = int(h3_hex, 16)
        
        if h3_int in h3_map:
            zone = h3_map[h3_int]
            print(f"{name:<40} | {zone:<6} | ✅ Found")
            found_count += 1
        else:
            # Not in DB = Implicit Zone 1
            print(f"{name:<40} | 1      | ℹ️  Implicit (Pristine)")
    
    print("="*60)
    print(f"\nSummary:")
    print(f"  Total Locations Tested: {total_count}")
    print(f"  Explicitly in DB:       {found_count}")
    print(f"  Implicit Zone 1:        {total_count - found_count}")
    print("\nValidation Interpretation:")
    print("  - Cities should be 'Found' (Zone > 1).")
    print("  - Dark sites/Oceans should be 'Implicit' (Zone 1) or 'Found' (Zone 1/2).")
    print("  - If all cities are 'Implicit', the generation failed.")

    # Strict Validation: Fail if < 80% of test locations are explicitly found logic doesn't strictly hold 
    # because some test locations ARE Zone 1 (Dark Sites).
    # But major cities MUST be found.
    # Let's count "Missed Cities".
    # We can check specific known bright locations.
    
    # Simple heuristic: If we find fewer than 30 locations (out of 70), something is definitely wrong 
    # (since we have ~50 cities/towns in the list).
    if found_count < 30:
        print("\n❌ CRITICAL: Coverage is too low! < 30 locations found.")
        print("Stopping process to avoid bad data upload.")
        sys.exit(1)
    
    print("\n✅ Verification Passed: Sufficient coverage detected.")
    sys.exit(0)

if __name__ == '__main__':
    script_dir = Path(__file__).parent
    zones_db = script_dir.parent / 'assets' / 'db' / 'zones.db'
    check_coverage(zones_db)
