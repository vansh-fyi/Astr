#!/usr/bin/env python3
"""
Extended zones.db coverage test with random locations.
Identifies which VIIRS tiles are likely missing.
"""

import struct
import random
from pathlib import Path
import sys
from collections import defaultdict

def lat_lon_to_h3(lat: float, lon: float, resolution: int = 8) -> int:
    """Convert lat/lon to H3 index."""
    import h3
    return int(h3.latlng_to_cell(lat, lon, resolution), 16)

def get_viirs_tile(lat: float, lon: float) -> tuple:
    """
    Get VIIRS/MODIS tile indices (h, v) for a lat/lon.
    MODIS sinusoidal grid: 36 horizontal tiles (h0-h35), 18 vertical tiles (v0-v17)
    """
    # MODIS sinusoidal parameters
    R = 6371007.181  # Earth radius in meters
    
    # Tile size in meters (at equator)
    TILE_SIZE = 1111950.5196666666  # ~10 degrees at equator
    
    import math
    
    # Convert to sinusoidal x, y
    lat_rad = math.radians(lat)
    lon_rad = math.radians(lon)
    
    x = R * lon_rad * math.cos(lat_rad)
    y = R * lat_rad
    
    # Grid origin is at (-180, 90) in geographic, which is (-20015109, 10007555) in sinusoidal
    x_origin = -20015109.354
    y_origin = 10007554.677
    
    # Calculate tile indices
    h = int((x - x_origin) / TILE_SIZE)
    v = int((y_origin - y) / TILE_SIZE)
    
    return (h, v)

def binary_search_zones_db(db_path: Path, target_h3: int, f) -> dict | None:
    """Binary search for H3 index in zones.db (reuses file handle)."""
    HEADER_SIZE = 16
    RECORD_SIZE = 20
    
    # Read record count from header (cached)
    f.seek(8)
    record_count = struct.unpack('<Q', f.read(8))[0]
    
    left, right = 0, record_count - 1
    
    while left <= right:
        mid = (left + right) // 2
        offset = HEADER_SIZE + mid * RECORD_SIZE
        
        f.seek(offset)
        record = f.read(RECORD_SIZE)
        
        h3_index = struct.unpack('<Q', record[:8])[0]
        
        if h3_index == target_h3:
            bortle = struct.unpack('B', record[8:9])[0]
            return {'bortle': bortle}
        elif h3_index < target_h3:
            left = mid + 1
        else:
            right = mid - 1
    
    return None

def generate_random_locations(n: int) -> list:
    """Generate n random land locations (approximate)."""
    locations = []
    
    # Define land areas (rough bounding boxes)
    land_areas = [
        ("North America", 25, 55, -130, -65),
        ("South America", -55, 10, -80, -35),
        ("Europe", 35, 70, -10, 40),
        ("Africa", -35, 35, -20, 50),
        ("Asia", 10, 70, 60, 150),
        ("Oceania", -45, -10, 110, 180),
        ("Middle East", 15, 45, 30, 60),
        ("Central America", 5, 25, -120, -60),
    ]
    
    for _ in range(n):
        area = random.choice(land_areas)
        name, lat_min, lat_max, lon_min, lon_max = area
        lat = random.uniform(lat_min, lat_max)
        lon = random.uniform(lon_min, lon_max)
        locations.append((f"{name} Random", lat, lon))
    
    return locations

def main():
    db_path = Path(__file__).parent.parent / 'assets' / 'db' / 'zones.db'
    
    if not db_path.exists():
        print(f"❌ zones.db not found")
        sys.exit(1)
    
    print(f"Extended Coverage Test - 5 Iterations\n")
    print(f"{'='*70}\n")
    
    # Track missing tiles
    missing_tiles = defaultdict(list)
    found_tiles = set()
    total_found = 0
    total_tested = 0
    
    with open(db_path, 'rb') as f:
        for iteration in range(1, 6):
            print(f"Iteration {iteration}: Testing 50 random locations...")
            
            locations = generate_random_locations(50)
            iter_found = 0
            
            for name, lat, lon in locations:
                total_tested += 1
                h3_index = lat_lon_to_h3(lat, lon, 8)
                tile = get_viirs_tile(lat, lon)
                
                result = binary_search_zones_db(db_path, h3_index, f)
                
                if result:
                    iter_found += 1
                    total_found += 1
                    found_tiles.add(tile)
                else:
                    missing_tiles[tile].append((lat, lon))
            
            print(f"  Found: {iter_found}/50 ({100*iter_found/50:.0f}%)")
    
    print(f"\n{'='*70}")
    print(f"\nOVERALL: {total_found}/{total_tested} ({100*total_found/total_tested:.1f}%)")
    
    print(f"\n✅ Tiles with data ({len(found_tiles)}):")
    for tile in sorted(found_tiles)[:20]:
        print(f"   h{tile[0]:02d}v{tile[1]:02d}")
    if len(found_tiles) > 20:
        print(f"   ... and {len(found_tiles) - 20} more")
    
    print(f"\n❌ Tiles MISSING data ({len(missing_tiles)}):")
    sorted_missing = sorted(missing_tiles.items(), key=lambda x: -len(x[1]))
    for tile, locs in sorted_missing[:25]:
        print(f"   h{tile[0]:02d}v{tile[1]:02d} - {len(locs)} locations missing")
    
    # Identify the missing tile range
    if missing_tiles:
        h_vals = [t[0] for t in missing_tiles.keys()]
        v_vals = [t[1] for t in missing_tiles.keys()]
        print(f"\n⚠️  Missing tile range: h{min(h_vals)}-h{max(h_vals)}, v{min(v_vals)}-v{max(v_vals)}")

if __name__ == '__main__':
    main()
