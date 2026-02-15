#!/usr/bin/env python3
"""
Apply atmospheric skyglow propagation to VNL radiance data.

Takes the existing zones_accumulator.db (from generate_zones_vnl.py) and
enhances it by adding scattered light from nearby urban areas. This accounts
for the "light dome" effect visible from dark sites near cities.

Model: Garstang-inspired atmospheric scatter with exponential decay.
  scatter(d) = fraction * exp(-d/scale) / (1 + (d/d0)^power)

Usage:
    pip install scipy  (one-time)
    python apply_skyglow.py --tif "../VNL NPP 2024 Global Masked Data.tif.gz"
"""

import os
os.environ['GDAL_CACHEMAX'] = '256'

import sys, argparse, struct, hashlib, math, gc, sqlite3
import numpy as np
from pathlib import Path
from tqdm import tqdm

for pkg in ['rasterio', 'h3', 'scipy']:
    try: __import__(pkg)
    except ImportError: print(f"Missing: {pkg}. Run: pip install {pkg}"); sys.exit(1)

import rasterio, rasterio.windows, h3
from scipy.signal import fftconvolve

# ============================================================================
# Configuration
# ============================================================================
H3_RESOLUTION = 8
DOWNSAMPLE = 12          # 15" × 12 = 3' ≈ 5.5 km/pixel
STRIP_HEIGHT = 200
REOPEN_INTERVAL = 25

# Scatter kernel parameters (Garstang-inspired)
SCATTER_FRACTION = 0.12  # 12% of upward light scatters horizontally
SCATTER_SCALE_KM = 20.0  # exponential decay length
SCATTER_POWER = 2.5      # power-law falloff
MAX_RADIUS_KM = 80.0     # truncation radius
D_REF_KM = 10.0          # reference distance for power law
PIXEL_KM = 5.55          # km per coarse pixel at equator

# Zone formula (must match generate_zones_vnl.py exactly)
# Calibrated thresholds from ground-truth SQM studies
ZONE_THRESHOLDS = [
    (125.0, 9), (50.0, 8), (20.0, 7), (9.0, 6),
    (3.0, 5), (1.0, 4), (0.50, 3), (0.25, 2),
]
ZONE2_RADIANCE = 0.25

def radiance_to_zone(r):
    if r <= 0: return 1
    for thresh, zone in ZONE_THRESHOLDS:
        if r >= thresh: return zone
    return 1 if r < ZONE2_RADIANCE else 2

def radiance_to_sqm(r):
    if r <= 0: return 22.0
    return max(16.0, min(22.0, 22.0 - 1.7 * math.log10(1.0 + 2.0 * r)))


# ============================================================================
# Scatter Kernel
# ============================================================================
def create_scatter_kernel():
    """Atmospheric scatter PSF. Center zeroed (no self-scatter)."""
    radius_px = int(MAX_RADIUS_KM / PIXEL_KM) + 1
    size = 2 * radius_px + 1
    kernel = np.zeros((size, size), dtype=np.float64)
    c = radius_px

    for y in range(size):
        for x in range(size):
            d = math.sqrt(((y - c) * PIXEL_KM)**2 + ((x - c) * PIXEL_KM)**2)
            if d < 0.5 or d > MAX_RADIUS_KM:
                continue
            kernel[y, x] = (SCATTER_FRACTION *
                            math.exp(-d / SCATTER_SCALE_KM) /
                            (1.0 + (d / D_REF_KM) ** SCATTER_POWER))
    return kernel.astype(np.float32)


# ============================================================================
# Phase 1: Downsample VNL raster to coarse grid
# ============================================================================
def downsample_raster(raster_path):
    with rasterio.open(raster_path) as src:
        h, w = src.height, src.width
        ch, cw = h // DOWNSAMPLE, w // DOWNSAMPLE
        coarse = np.zeros((ch, cw), dtype=np.float32)
        strip_h = DOWNSAMPLE * 20  # 20 coarse rows per read

        for i in tqdm(range(0, h, strip_h), desc="Downsampling"):
            rows = min(strip_h, h - i)
            usable = (rows // DOWNSAMPLE) * DOWNSAMPLE
            if usable == 0: continue

            data = src.read(1, window=rasterio.windows.Window(0, i, w, usable))
            data = np.maximum(data, 0)

            ny = usable // DOWNSAMPLE
            nx = w // DOWNSAMPLE
            block = data[:ny*DOWNSAMPLE, :nx*DOWNSAMPLE].reshape(ny, DOWNSAMPLE, nx, DOWNSAMPLE)
            cy = i // DOWNSAMPLE
            coarse[cy:cy+ny, :] = block.mean(axis=(1, 3))
            del data, block; gc.collect()

    print(f"  Coarse grid: {cw}×{ch}, non-zero: {np.count_nonzero(coarse):,}")
    return coarse


# ============================================================================
# Phase 3: Re-scan VNL with scatter enhancement → update accumulator
# ============================================================================
def enhanced_scan(raster_path, scattered, accum_path):
    """Re-scan VNL at full resolution. For each pixel, add interpolated scatter."""
    conn = sqlite3.connect(str(accum_path))
    conn.execute('PRAGMA journal_mode=WAL')
    conn.execute('PRAGMA synchronous=NORMAL')
    conn.execute('PRAGMA cache_size=-65536')

    # Reset progress so all strips are re-processed
    conn.execute('DELETE FROM progress')
    conn.commit()

    sc_h, sc_w = scattered.shape

    with rasterio.open(raster_path) as src:
        height, width = src.height, src.width
        transform = src.transform

    num_strips = (height + STRIP_HEIGHT - 1) // STRIP_HEIGHT
    src_handle = rasterio.open(raster_path)
    strips_since_open = 0
    total_new = 0
    total_enhanced = 0

    pbar = tqdm(total=num_strips, desc="Enhanced scan", unit="strip")

    for strip_idx in range(num_strips):
        if strips_since_open >= REOPEN_INTERVAL:
            src_handle.close(); gc.collect()
            src_handle = rasterio.open(raster_path)
            strips_since_open = 0

        start_row = strip_idx * STRIP_HEIGHT
        end_row = min(start_row + STRIP_HEIGHT, height)
        rows_in_strip = end_row - start_row

        window = rasterio.windows.Window(0, start_row, width, rows_in_strip)
        data = src_handle.read(1, window=window)
        data = np.maximum(data, 0)

        # Build scatter values for this strip via nearest-neighbor lookup
        scatter_strip = np.zeros_like(data)
        for lr in range(rows_in_strip):
            cy = min((start_row + lr) // DOWNSAMPLE, sc_h - 1)
            # Vectorized column mapping
            cx_arr = np.minimum(np.arange(width) // DOWNSAMPLE, sc_w - 1)
            scatter_strip[lr, :] = scattered[cy, cx_arr]

        # Enhanced radiance = direct + scatter
        enhanced = data + scatter_strip

        # Find pixels above Zone 2 threshold
        mask = enhanced >= ZONE2_RADIANCE
        rows_local, cols = np.where(mask)

        if len(rows_local) > 0:
            radiances = enhanced[rows_local, cols]
            rows_global = rows_local + start_row
            xs, ys = rasterio.transform.xy(transform, rows_global, cols)

            batch = []
            for i in range(len(radiances)):
                lat, lon, rad = ys[i], xs[i], float(radiances[i])
                if lat < -85 or lat > 85 or lon < -180 or lon > 180:
                    continue
                try:
                    h3_cell = h3.latlng_to_cell(lat, lon, H3_RESOLUTION)
                    h3_int = int(h3_cell, 16)
                    batch.append((h3_int, rad))
                except: continue

            if batch:
                conn.executemany('''
                    INSERT INTO cells (h3, radiance) VALUES (?, ?)
                    ON CONFLICT(h3) DO UPDATE SET radiance = MAX(radiance, excluded.radiance)
                ''', batch)
                total_enhanced += len(batch)

        conn.execute('INSERT OR IGNORE INTO progress VALUES (?)', (strip_idx,))
        conn.commit()

        del data, scatter_strip, enhanced
        strips_since_open += 1
        pbar.update(1)

        if (strip_idx + 1) % 10 == 0:
            count = conn.execute('SELECT COUNT(*) FROM cells').fetchone()[0]
            pbar.set_postfix(cells=f"{count:,}")
            gc.collect()

    src_handle.close()
    pbar.close()

    total = conn.execute('SELECT COUNT(*) FROM cells').fetchone()[0]
    print(f"\nEnhanced scan complete. Total cells: {total:,}")
    conn.close()
    return total


# ============================================================================
# Phase 4: Write zones.db from accumulator
# ============================================================================
def write_zones_db(accum_path, output_path):
    conn = sqlite3.connect(str(accum_path))
    total = conn.execute('SELECT COUNT(*) FROM cells').fetchone()[0]
    print(f"\nWriting {total:,} cells to {output_path}")

    written = 0
    skipped = 0

    with open(output_path, 'wb') as f:
        f.write(b'ASTR\x01\x00\x00\x00')
        count_pos = f.tell()
        f.write(struct.pack('<Q', 0))

        cursor = conn.execute('SELECT h3, radiance FROM cells ORDER BY h3')
        while True:
            rows = cursor.fetchmany(100_000)
            if not rows: break
            for h3_int, rad in rows:
                zone = radiance_to_zone(rad)
                if zone <= 1:
                    skipped += 1; continue
                sqm = radiance_to_sqm(rad)
                f.write(struct.pack('<Q', h3_int))
                f.write(struct.pack('B', zone))
                f.write(struct.pack('<f', rad))
                f.write(struct.pack('<f', sqm))
                f.write(b'\x00\x00\x00')
                written += 1

        f.seek(count_pos)
        f.write(struct.pack('<Q', written))

    sha = hashlib.sha256()
    with open(output_path, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''): sha.update(chunk)

    size_mb = output_path.stat().st_size / (1024**2)
    print(f"\n{'='*50}")
    print(f"SUCCESS!")
    print(f"  Records: {written:,} (skipped {skipped:,} Zone 1)")
    print(f"  Size: {size_mb:.1f} MB")
    print(f"  SHA-256: {sha.hexdigest()}")
    print(f"{'='*50}")

    # Quick validation
    print("\nValidation:")
    for name, lat, lon in [
        ("Bhadraj Temple", 30.5167, 78.0333),
        ("Dehradun", 30.3165, 78.0322),
        ("Hanle", 32.7795, 78.9641),
        ("New York City", 40.7128, -74.0060),
        ("Null Island", 0.0, 0.0),
    ]:
        h3_cell = h3.latlng_to_cell(lat, lon, H3_RESOLUTION)
        h3_int = int(h3_cell, 16)
        row = conn.execute('SELECT radiance FROM cells WHERE h3=?', (h3_int,)).fetchone()
        if row:
            z = radiance_to_zone(row[0])
            print(f"  {name}: Zone {z} (radiance={row[0]:.4f})")
        else:
            print(f"  {name}: Zone 1 (Implicit)")

    conn.close()


# ============================================================================
# Main
# ============================================================================
def main():
    global SCATTER_FRACTION, SCATTER_SCALE_KM

    parser = argparse.ArgumentParser(description='Apply skyglow propagation')
    parser.add_argument('--tif', required=True, help='Path to VNL average-masked TIF/GZ')
    parser.add_argument('--accum', help='Path to accumulator DB (default: next to TIF)')
    parser.add_argument('--fraction', type=float, default=SCATTER_FRACTION)
    parser.add_argument('--scale-km', type=float, default=SCATTER_SCALE_KM)
    args = parser.parse_args()

    SCATTER_FRACTION = args.fraction
    SCATTER_SCALE_KM = args.scale_km

    tif_path = Path(args.tif)
    raster_path = str(tif_path)
    if tif_path.suffix == '.gz':
        raster_path = f'/vsigzip/{tif_path.absolute()}'
        print(f"Using GZIP driver: {tif_path.name}")

    accum_path = Path(args.accum) if args.accum else tif_path.parent / 'zones_accumulator.db'
    output_path = Path(__file__).parent.parent / 'assets' / 'db' / 'zones.db'
    output_path.parent.mkdir(parents=True, exist_ok=True)

    if not accum_path.exists():
        print(f"Error: Accumulator not found: {accum_path}")
        print("Run generate_zones_vnl.py first.")
        sys.exit(1)

    print(f"Scatter params: fraction={SCATTER_FRACTION}, scale={SCATTER_SCALE_KM}km, "
          f"power={SCATTER_POWER}, max_radius={MAX_RADIUS_KM}km")

    # Phase 1: Downsample
    print("\n=== Phase 1: Downsample VNL raster ===")
    coarse = downsample_raster(raster_path)

    # Phase 2: Convolve
    print("\n=== Phase 2: Atmospheric scatter convolution ===")
    kernel = create_scatter_kernel()
    print(f"  Kernel: {kernel.shape[0]}×{kernel.shape[1]} pixels")
    scattered = fftconvolve(coarse, kernel, mode='same').astype(np.float32)
    scattered = np.maximum(scattered, 0)
    sig = scattered[scattered > ZONE2_RADIANCE]
    print(f"  Scatter: max={scattered.max():.4f} nW, "
          f"pixels above threshold={len(sig):,}")
    del coarse, kernel; gc.collect()

    # Phase 3: Enhanced scan
    print("\n=== Phase 3: Re-scan with scatter enhancement ===")
    enhanced_scan(raster_path, scattered, accum_path)

    # Phase 4: Write zones.db
    print("\n=== Phase 4: Write zones.db ===")
    write_zones_db(accum_path, output_path)

    print("\nNext steps:")
    print("  1. python validate_zones_db.py")
    print("  2. cd ../cloudflare && npx wrangler r2 object put astr-zones/zones.db --file ../assets/db/zones.db")

if __name__ == '__main__':
    main()
