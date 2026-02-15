#!/usr/bin/env python3
"""
Generate zones.db from VIIRS Nighttime Lights (VNL) V2.2 Annual Average Data.

VERSION 4 — MEMORY-SAFE + RESUMABLE
  - Uses SQLite as a disk-based accumulator instead of a Python dict
  - Checkpoints progress so it can resume after interruption
  - Reopens the raster every N strips to flush GDAL vsigzip memory
  - Caps GDAL internal cache to 256 MB

Data Source: Colorado School of Mines / Earth Observation Group
URL: https://eogdata.mines.edu/products/vnl/

Usage:
    cd scripts && source .venv/bin/activate
    pip install rasterio h3 numpy tqdm
    python generate_zones_vnl.py --tif "../VNL NPP 2024 Global Configuration Data.tif.gz"

Output: assets/db/zones.db
"""

import struct
import hashlib
import os
import sys
import argparse
import math
import gc
import sqlite3
from pathlib import Path

# Cap GDAL's internal block cache BEFORE importing rasterio.
os.environ['GDAL_CACHEMAX'] = '256'

# Check dependencies
def check_dependencies():
    missing = []
    for pkg in ['rasterio', 'h3', 'numpy', 'tqdm']:
        try:
            __import__(pkg)
        except ImportError:
            missing.append(pkg)
    if missing:
        print(f"Missing: {', '.join(missing)}")
        print(f"Install: pip install {' '.join(missing)}")
        sys.exit(1)

check_dependencies()

import rasterio
import rasterio.windows
import h3
import numpy as np
from tqdm import tqdm


# ============================================================================
# Configuration
# ============================================================================

H3_RESOLUTION = 8
STRIP_HEIGHT = 200

# How many strips to process before closing/reopening the raster file
# to flush GDAL's vsigzip decompression buffers.
REOPEN_INTERVAL = 25

# ============================================================================
# Astr Zone Formula (v2.0 - Calibrated thresholds)
# Thresholds based on ground-truth SQM measurements correlated with VNL radiance
# References: Sánchez de Miguel et al. (2020), Falchi et al. (2016)
# ============================================================================

# VNL radiance thresholds (nW/cm²/sr) → Bortle zone
ZONE_THRESHOLDS = [
    (125.0, 9),   # Inner city (NYC, London centers)
    (50.0,  8),   # Dense urban
    (20.0,  7),   # Urban (Dehradun ~40 → Zone 7)
    (9.0,   6),   # Bright suburban
    (3.0,   5),   # Suburban
    (1.0,   4),   # Rural/suburban transition
    (0.50,  3),   # Rural sky
    (0.25,  2),   # Typical dark site
]
ZONE2_RADIANCE = 0.25  # Below this → Zone 1 (pristine)
MIN_RADIANCE = 0.1     # Pre-filter threshold (slightly below Zone 2 for safety)


def radiance_to_zone(radiance: float) -> int:
    if radiance <= 0:
        return 1
    for threshold, zone in ZONE_THRESHOLDS:
        if radiance >= threshold:
            return zone
    return 1 if radiance < ZONE2_RADIANCE else 2


def radiance_to_sqm(radiance: float) -> float:
    """Convert VNL radiance to Sky Quality Meter reading (mag/arcsec²)."""
    if radiance <= 0:
        return 22.0
    sqm = 22.0 - 1.7 * math.log10(1.0 + 2.0 * radiance)
    return max(16.0, min(22.0, sqm))


# ============================================================================
# SQLite Accumulator
# ============================================================================

def init_accumulator(db_path: Path):
    """Create/open the SQLite accumulator database."""
    conn = sqlite3.connect(str(db_path))
    conn.execute('PRAGMA journal_mode=WAL')
    conn.execute('PRAGMA synchronous=NORMAL')
    conn.execute('PRAGMA cache_size=-65536')  # 64 MB page cache
    conn.execute('''
        CREATE TABLE IF NOT EXISTS cells (
            h3 INTEGER PRIMARY KEY,
            radiance REAL NOT NULL
        )
    ''')
    conn.execute('''
        CREATE TABLE IF NOT EXISTS progress (
            strip_idx INTEGER PRIMARY KEY
        )
    ''')
    conn.commit()
    return conn


def get_completed_strips(conn):
    """Return set of strip indices already processed."""
    rows = conn.execute('SELECT strip_idx FROM progress').fetchall()
    return set(r[0] for r in rows)


def flush_batch(conn, batch, strip_idx):
    """Write a batch of (h3_int, radiance) pairs to SQLite, keeping MAX radiance."""
    if not batch:
        conn.execute('INSERT OR IGNORE INTO progress VALUES (?)', (strip_idx,))
        conn.commit()
        return

    # Use INSERT ... ON CONFLICT to keep max radiance
    conn.executemany('''
        INSERT INTO cells (h3, radiance) VALUES (?, ?)
        ON CONFLICT(h3) DO UPDATE SET radiance = MAX(radiance, excluded.radiance)
    ''', batch)
    conn.execute('INSERT OR IGNORE INTO progress VALUES (?)', (strip_idx,))
    conn.commit()


# ============================================================================
# Strip processor
# ============================================================================

def process_strip(data_strip, transform, start_row):
    """Process a strip, returning list of (h3_int, radiance) tuples for Zone 2+ pixels."""
    if data_strip.max() <= MIN_RADIANCE:
        return [], 0

    rows_local, cols = np.where(data_strip > MIN_RADIANCE)
    if len(rows_local) == 0:
        return [], 0

    radiances = data_strip[rows_local, cols]

    # Pre-filter Zone 1
    bright_mask = radiances >= ZONE2_RADIANCE
    rows_local = rows_local[bright_mask]
    cols = cols[bright_mask]
    radiances = radiances[bright_mask]

    if len(radiances) == 0:
        return [], 0

    rows_global = rows_local + start_row
    xs, ys = rasterio.transform.xy(transform, rows_global, cols)

    results = []
    for i in range(len(radiances)):
        lon, lat, rad = xs[i], ys[i], float(radiances[i])
        if lat < -85 or lat > 85 or lon < -180 or lon > 180:
            continue
        try:
            h3_cell = h3.latlng_to_cell(lat, lon, H3_RESOLUTION)
            h3_int = int(h3_cell, 16)
            results.append((h3_int, rad))
        except Exception:
            continue

    return results, len(radiances)


# ============================================================================
# Main processing
# ============================================================================

def process_vnl(tif_path: Path, output_path: Path):
    """Process VNL GeoTIFF to zones.db using SQLite accumulator."""

    raster_path = str(tif_path)
    if tif_path.suffix == '.gz':
        raster_path = f'/vsigzip/{tif_path.absolute()}'
        print(f"Using GZIP driver for: {tif_path.name}")

    # SQLite accumulator lives next to the script
    accum_path = tif_path.parent / 'zones_accumulator.db'

    conn = init_accumulator(accum_path)
    completed = get_completed_strips(conn)

    # Get raster dimensions
    with rasterio.open(raster_path) as src:
        height = src.height
        width = src.width
        transform = src.transform

    num_strips = (height + STRIP_HEIGHT - 1) // STRIP_HEIGHT
    remaining = num_strips - len(completed)

    print(f"\nImage: {width}x{height} pixels")
    print(f"H3 Resolution: {H3_RESOLUTION} (~461m cells)")
    print(f"Strip height: {STRIP_HEIGHT} rows (~{width * STRIP_HEIGHT * 4 / 1024**2:.0f} MB/strip)")
    print(f"Total strips: {num_strips}")
    print(f"Already done: {len(completed)}")
    print(f"Remaining: {remaining}")
    print(f"GDAL cache: {os.environ.get('GDAL_CACHEMAX', 'default')} MB")
    print(f"Raster reopen interval: every {REOPEN_INTERVAL} strips")
    print(f"Accumulator: {accum_path}")

    if remaining == 0:
        print("\nAll strips already processed! Skipping to write phase.")
    else:
        total_pixels = 0
        strips_since_open = 0
        src = rasterio.open(raster_path)

        pbar = tqdm(total=num_strips, desc="Processing", unit="strip",
                    initial=len(completed))

        for strip_idx in range(num_strips):
            if strip_idx in completed:
                continue

            # Reopen file periodically to flush GDAL vsigzip buffers
            if strips_since_open >= REOPEN_INTERVAL:
                src.close()
                gc.collect()
                src = rasterio.open(raster_path)
                strips_since_open = 0

            start_row = strip_idx * STRIP_HEIGHT
            end_row = min(start_row + STRIP_HEIGHT, height)

            window = rasterio.windows.Window(
                col_off=0, row_off=start_row,
                width=width, height=end_row - start_row,
            )

            data = src.read(1, window=window)
            results, px = process_strip(data, transform, start_row)
            total_pixels += px
            del data

            # Flush to SQLite
            flush_batch(conn, results, strip_idx)
            del results

            strips_since_open += 1
            pbar.update(1)

            if (strip_idx + 1) % 5 == 0:
                cell_count = conn.execute('SELECT COUNT(*) FROM cells').fetchone()[0]
                pbar.set_postfix(cells=f"{cell_count:,}", px=f"{total_pixels:,}")
                gc.collect()

        src.close()
        pbar.close()
        print(f"\nScanning complete. Lit pixels examined: {total_pixels:,}")

    # ------------------------------------------------------------------
    # Count records
    # ------------------------------------------------------------------
    total_cells = conn.execute('SELECT COUNT(*) FROM cells').fetchone()[0]
    print(f"Total unique H3 cells in accumulator: {total_cells:,}")

    # ------------------------------------------------------------------
    # Write binary zones.db from SQLite
    # ------------------------------------------------------------------
    print(f"\nWriting: {output_path}")

    written = 0
    skipped_zone1 = 0

    with open(output_path, 'wb') as f:
        # Header
        f.write(b'ASTR\x01\x00\x00\x00')
        count_offset = f.tell()
        f.write(struct.pack('<Q', 0))  # placeholder

        # Stream sorted records from SQLite (no need to load all into memory)
        cursor = conn.execute('SELECT h3, radiance FROM cells ORDER BY h3')

        batch_size = 100_000
        while True:
            rows = cursor.fetchmany(batch_size)
            if not rows:
                break

            for h3_int, radiance in rows:
                zone = radiance_to_zone(radiance)
                if zone <= 1:
                    skipped_zone1 += 1
                    continue

                sqm = radiance_to_sqm(radiance)
                record = struct.pack('<Q', h3_int)
                record += struct.pack('B', zone)
                record += struct.pack('<f', radiance)
                record += struct.pack('<f', sqm)
                record += b'\x00\x00\x00'
                f.write(record)
                written += 1

        # Patch header with actual count
        f.seek(count_offset)
        f.write(struct.pack('<Q', written))

    # SHA-256
    sha256 = hashlib.sha256()
    with open(output_path, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            sha256.update(chunk)

    file_hash = sha256.hexdigest()
    size_mb = output_path.stat().st_size / (1024**2)

    print(f"\n{'='*50}")
    print(f"SUCCESS!")
    print(f"  File: {output_path}")
    print(f"  Records (Zone 2+): {written:,}")
    print(f"  Skipped (Zone 1):  {skipped_zone1:,}")
    print(f"  Size: {size_mb:.1f} MB")
    print(f"  SHA-256: {file_hash}")
    print(f"{'='*50}")

    # Quick validation
    print("\nQuick validation:")
    test_locations = [
        ("Bhadraj Temple", 30.5167, 78.0333),
        ("Dehradun", 30.3165, 78.0322),
        ("Hanle", 32.7795, 78.9641),
        ("New York City", 40.7128, -74.0060),
        ("Null Island (Ocean)", 0.0, 0.0),
    ]

    for name, lat, lon in test_locations:
        h3_cell = h3.latlng_to_cell(lat, lon, H3_RESOLUTION)
        h3_int = int(h3_cell, 16)
        row = conn.execute(
            'SELECT radiance FROM cells WHERE h3 = ?', (h3_int,)
        ).fetchone()
        if row:
            zone = radiance_to_zone(row[0])
            print(f"  {name}: Zone {zone} (Stored)")
        else:
            print(f"  {name}: Zone 1 (Implicit/Pristine)")

    conn.close()

    print(f"\nAccumulator kept at: {accum_path}")
    print("  (Delete it after verifying zones.db is correct)")

    print("\nNext steps:")
    print("  1. python validate_zones_db.py")
    print("  2. cd ../cloudflare && npx wrangler r2 object put astr-zones/zones.db --file ../assets/db/zones.db")

    return file_hash


def main():
    parser = argparse.ArgumentParser(description='Generate zones.db from VNL')
    parser.add_argument('--skip-download', action='store_true')
    parser.add_argument('--tif', type=str, help='Path to VNL TIF/TIF.GZ')
    parser.add_argument('--reset', action='store_true',
                        help='Delete accumulator and start fresh')
    args = parser.parse_args()

    script_dir = Path(__file__).parent
    data_dir = script_dir / 'data'
    data_dir.mkdir(exist_ok=True)

    output_path = script_dir.parent / 'assets' / 'db' / 'zones.db'
    output_path.parent.mkdir(parents=True, exist_ok=True)

    if args.tif:
        tif_path = Path(args.tif)
    else:
        tif_path = data_dir / 'vnl_average.tif'
        gz_path = data_dir / 'vnl_average.tif.gz'
        if not tif_path.exists() and gz_path.exists():
            tif_path = gz_path

    if not tif_path.exists():
        print(f"Error: TIF not found: {tif_path}")
        print("Please place the VNL data file in scripts/data/ or use --tif argument.")
        sys.exit(1)

    if args.reset:
        accum = tif_path.parent / 'zones_accumulator.db'
        if accum.exists():
            os.remove(accum)
            print(f"Deleted accumulator: {accum}")
            # Also remove WAL/SHM files
            for suffix in ['-wal', '-shm']:
                p = accum.with_suffix(accum.suffix + suffix)
                if p.exists():
                    os.remove(p)

    process_vnl(tif_path, output_path)


if __name__ == '__main__':
    main()
