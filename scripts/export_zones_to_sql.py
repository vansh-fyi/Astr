#!/usr/bin/env python3
"""
Export zones.db to SQL files for Cloudflare D1.
Splits output into chunks to stay within D1 upload limits (100MB).
"""

import struct
import os
import sys
import argparse
from pathlib import Path
from tqdm import tqdm

# D1 Limit for 'wrangler d1 execute' is roughly 100MB uncompressed SQL.
# We target 10MB chunks for reliable remote imports.
MAX_CHUNK_SIZE = 10 * 1024 * 1024  

def export_to_sql(db_path: Path, output_dir: Path):
    if not db_path.exists():
        print(f"Error: Database not found: {db_path}")
        sys.exit(1)

    print(f"Exporting {db_path} to SQL...")
    output_dir.mkdir(parents=True, exist_ok=True)

    # Base filename for chunks
    base_name = output_dir / "zones_part"
    
    current_chunk = 1
    current_size = 0
    record_count = 0
    
    # Open first chunk
    f_sql = open(f"{base_name}{current_chunk}.sql", 'w')
    f_sql.write("-- Cloudflare D1 Import - Part 1\n")
    f_sql.write("DROP TABLE IF EXISTS zones;\n")
    f_sql.write("CREATE TABLE IF NOT EXISTS zones (h3 INTEGER PRIMARY KEY, zone INTEGER, radiance REAL, sqm REAL);\n")
    
    # We buffer INSERTs: "INSERT INTO zones VALUES (...), (...), ...;"
    # A single statement can be up to 1MB, but let's keep it smaller for safety.
    batch_size = 1000
    batch = []
    
    def flush_batch():
        nonlocal current_size, current_chunk, f_sql
        if not batch:
            return
            
        # Create insert statement
        values = ",".join(batch)
        stmt = f"INSERT INTO zones (h3, zone, radiance, sqm) VALUES {values};\n"
        
        # Check if adding this would exceed chunk size
        stmt_len = len(stmt)
        if current_size + stmt_len > MAX_CHUNK_SIZE:
            f_sql.close()
            current_chunk += 1
            f_sql = open(f"{base_name}{current_chunk}.sql", 'w')
            f_sql.write(f"-- Cloudflare D1 Import - Part {current_chunk}\n")
            current_size = 0
            
        f_sql.write(stmt)
        current_size += stmt_len
        batch.clear()

    with open(db_path, 'rb') as f:
        # Read Header
        header = f.read(16)
        if len(header) < 16:
            print("Error: File too short")
            sys.exit(1)
            
        magic = header[:8]
        count = struct.unpack('<Q', header[8:16])[0]
        
        print(f"Total records: {count:,}")
        
        # 20 bytes per record
        # Format: <Q (h3), B (zone), <f (radiance), <f (sqm), 3x (pad)
        
        pbar = tqdm(total=count, desc="Converting")
        
        while True:
            chunk = f.read(20 * 10000) # Read 10k records at a time
            if not chunk:
                break
                
            num_in_chunk = len(chunk) // 20
            
            for i in range(num_in_chunk):
                offset = i * 20
                record_bytes = chunk[offset:offset+20]
                
                h3_int = struct.unpack('<Q', record_bytes[:8])[0]
                zone = struct.unpack('B', record_bytes[8:9])[0]
                radiance = struct.unpack('<f', record_bytes[9:13])[0]
                sqm = struct.unpack('<f', record_bytes[13:17])[0]
                
                # Format string for SQL
                # Use replace to handle potential float weirdness, though struct.unpack gives standard floats
                batch.append(f"({h3_int}, {zone}, {radiance:.6f}, {sqm:.2f})")
                
                if len(batch) >= batch_size:
                    flush_batch()
            
            pbar.update(num_in_chunk)
            
        # Flush remaining
        flush_batch()
        pbar.close()
        
    f_sql.close()
    print(f"\nSuccess! Created {current_chunk} SQL files in {output_dir}")

def main():
    script_dir = Path(__file__).parent
    assets_dir = script_dir.parent / 'assets' / 'db'
    
    parser = argparse.ArgumentParser(description='Convert zones.db to SQL')
    parser.add_argument('--db', type=str, default=str(assets_dir / 'zones.db'))
    parser.add_argument('--out', type=str, default=str(assets_dir))
    
    args = parser.parse_args()
    
    export_to_sql(Path(args.db), Path(args.out))

if __name__ == '__main__':
    main()
