#!/usr/bin/env python3
"""
Quick diagnostic: inspect what the VNL TIF file actually contains.
Samples pixel values at known locations and shows statistics.
"""
import os
os.environ['GDAL_CACHEMAX'] = '256'

import sys
import rasterio
import numpy as np
from pathlib import Path

def main():
    tif_path = sys.argv[1] if len(sys.argv) > 1 else "../VNL NPP 2024 Global Configuration Data.tif.gz"
    
    raster_path = tif_path
    if tif_path.endswith('.gz'):
        raster_path = f'/vsigzip/{Path(tif_path).absolute()}'
    
    with rasterio.open(raster_path) as src:
        print(f"File: {tif_path}")
        print(f"Size: {src.width}x{src.height}")
        print(f"CRS: {src.crs}")
        print(f"Bands: {src.count}")
        print(f"Dtype: {src.dtypes}")
        print(f"NoData: {src.nodata}")
        print(f"Transform: {src.transform}")
        
        # Sample known locations
        locations = [
            ("New York City", 40.7128, -74.0060),
            ("Dehradun", 30.3165, 78.0322),
            ("Hanle (Dark Sky)", 32.7795, 78.9641),
            ("Bhadraj Temple", 30.5167, 78.0333),
            ("Null Island (Ocean)", 0.0, 0.0),
            ("Mid Pacific Ocean", 0.0, -150.0),
            ("Sahara Desert", 25.0, 10.0),
            ("Amazon Rainforest", -3.0, -60.0),
            ("Antarctica", -80.0, 0.0),
            ("London", 51.5074, -0.1278),
            ("Tokyo", 35.6762, 139.6503),
        ]
        
        print(f"\n{'Location':<25} {'Row':>6} {'Col':>6} {'Raw Value':>12} {'Interpretation':>15}")
        print("-" * 70)
        
        for name, lat, lon in locations:
            try:
                row, col = src.index(lon, lat)
                if 0 <= row < src.height and 0 <= col < src.width:
                    window = rasterio.windows.Window(col, row, 1, 1)
                    val = src.read(1, window=window)[0, 0]
                    print(f"  {name:<23} {row:>6} {col:>6} {val:>12.6f} {'← radiance?' if val < 100 else '← too high!'}")
                else:
                    print(f"  {name:<23} OUT OF BOUNDS")
            except Exception as e:
                print(f"  {name:<23} ERROR: {e}")
        
        # Sample a strip to check value distribution
        print("\n--- Value Distribution (row 10000, all columns) ---")
        window = rasterio.windows.Window(0, 10000, src.width, 1)
        row_data = src.read(1, window=window).flatten()
        
        print(f"  Min: {row_data.min():.6f}")
        print(f"  Max: {row_data.max():.6f}")
        print(f"  Mean: {row_data.mean():.6f}")
        print(f"  Median: {np.median(row_data):.6f}")
        print(f"  Std: {row_data.std():.6f}")
        print(f"  Non-zero count: {np.count_nonzero(row_data):,} / {len(row_data):,}")
        print(f"  > 0.001: {(row_data > 0.001).sum():,}")
        print(f"  > 1.0: {(row_data > 1.0).sum():,}")
        print(f"  > 10.0: {(row_data > 10.0).sum():,}")
        print(f"  > 100.0: {(row_data > 100.0).sum():,}")
        
        # Check a few percentiles
        nonzero = row_data[row_data > 0]
        if len(nonzero) > 0:
            print(f"\n  Non-zero percentiles:")
            for p in [10, 25, 50, 75, 90, 95, 99]:
                print(f"    P{p}: {np.percentile(nonzero, p):.6f}")

if __name__ == '__main__':
    main()
