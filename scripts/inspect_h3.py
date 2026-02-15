#!/usr/bin/env python3
"""
Dump sample H3 indices from zones.db to check resolution and format.
"""

import struct
from pathlib import Path
import h3

def main():
    db_path = Path(__file__).parent.parent / 'assets' / 'db' / 'zones.db'
    
    with open(db_path, 'rb') as f:
        # Read header
        header = f.read(16)
        magic = header[:8]
        record_count = struct.unpack('<Q', header[8:16])[0]
        
        print(f"Magic: {magic}")
        print(f"Record count: {record_count:,}\n")
        
        # Sample first 10 records
        print("First 10 records:")
        print("-" * 80)
        
        for i in range(10):
            f.seek(16 + i * 20)
            record = f.read(20)
            h3_int = struct.unpack('<Q', record[:8])[0]
            h3_hex = format(h3_int, 'x')
            
            # Get resolution
            try:
                res = h3.get_resolution(h3_hex)
                lat, lon = h3.cell_to_latlng(h3_hex)
                print(f"  {i}: {h3_hex} | Res: {res} | ({lat:.4f}, {lon:.4f})")
            except Exception as e:
                print(f"  {i}: {h3_hex} | Error: {e}")
        
        # Sample some records from the middle
        print(f"\nMiddle records (around record {record_count//2:,}):")
        print("-" * 80)
        
        for i in range(5):
            idx = record_count // 2 + i
            f.seek(16 + idx * 20)
            record = f.read(20)
            h3_int = struct.unpack('<Q', record[:8])[0]
            h3_hex = format(h3_int, 'x')
            
            try:
                res = h3.get_resolution(h3_hex)
                lat, lon = h3.cell_to_latlng(h3_hex)
                print(f"  {idx}: {h3_hex} | Res: {res} | ({lat:.4f}, {lon:.4f})")
            except Exception as e:
                print(f"  {idx}: {h3_hex} | Error: {e}")
        
        # Compare to expected indices for test locations
        print("\n\nExpected H3 indices for test locations (res 8):")
        print("-" * 80)
        
        test_locs = [
            ("Singapore", 1.3521, 103.8198),
            ("London", 51.5074, -0.1278),
            ("New York", 40.7128, -74.0060),
        ]
        
        for name, lat, lon in test_locs:
            cell = h3.latlng_to_cell(lat, lon, 8)
            cell_int = int(cell, 16)
            print(f"  {name}: {cell} (int: {cell_int})")
        
        # Check if New York index exists
        print("\n\nSearching for New York H3 index...")
        ny_cell = h3.latlng_to_cell(40.7128, -74.0060, 8)
        ny_int = int(ny_cell, 16)
        
        left, right = 0, record_count - 1
        while left <= right:
            mid = (left + right) // 2
            f.seek(16 + mid * 20)
            record = f.read(20)
            h3_index = struct.unpack('<Q', record[:8])[0]
            
            if h3_index == ny_int:
                bortle = struct.unpack('B', record[8:9])[0]
                print(f"  ✅ Found at record {mid}: Bortle {bortle}")
                break
            elif h3_index < ny_int:
                left = mid + 1
            else:
                right = mid - 1
        else:
            print(f"  ❌ Not found")

if __name__ == '__main__':
    main()
