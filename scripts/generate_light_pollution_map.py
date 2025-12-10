#!/usr/bin/env python3
"""
Converts World Atlas 2015 TIFF to optimized Bortle-classified PNG map.

Input: World_Atlas_2015.tif (floating-point brightness in mcd/m²)
Output: light_pollution_bortle_map.png (indexed color, ~10-15MB)

Brightness → MPSAS → Bortle conversion based on:
- Falchi et al. (2016) World Atlas data
- Standard astronomical MPSAS to Bortle scale mapping
"""

import numpy as np
from PIL import Image
import sys

try:
    from osgeo import gdal
except ImportError:
    print("ERROR: GDAL not installed. Install with:")
    print("  pip install gdal")
    print("  OR: brew install gdal && pip install gdal")
    sys.exit(1)


def brightness_to_mpsas(brightness_ratio):
    """
    Convert artificial sky brightness to MPSAS.

    The World Atlas 2015 TIFF contains brightness RATIOS (not absolute values):
    - Value represents ratio of artificial light to natural sky brightness
    - 0 = no artificial light (pristine sky, MPSAS = 21.58)
    - 0.1 = 10% additional light
    - 1.0 = 100% additional (double the natural brightness)
    - 10.0 = 10x natural brightness (very polluted)

    Formula from Falchi et al. (2016):
    MPSAS = 21.58 - 2.5 * log10(ratio + 1)

    Where 21.58 is the natural zenith sky brightness in MPSAS.
    """
    # Avoid log(0) - treat negative/zero as pristine
    brightness_safe = np.maximum(brightness_ratio, 0.0)

    # Calculate MPSAS
    # pristine sky (ratio=0): 21.58 - 2.5*log10(1) = 21.58
    # ratio=1 (2x natural): 21.58 - 2.5*log10(2) = 20.83
    # ratio=10: 21.58 - 2.5*log10(11) = 18.98
    # ratio=100: 21.58 - 2.5*log10(101) = 16.57
    mpsas = 21.58 - 2.5 * np.log10(brightness_safe + 1.0)

    return mpsas


def mpsas_to_bortle(mpsas):
    """
    Convert MPSAS to Bortle scale (1-9).

    Based on standard Bortle scale definitions:
    - Bortle 1: MPSAS >= 21.7  (Excellent dark sky)
    - Bortle 2: MPSAS >= 21.5  (Typical dark sky)
    - Bortle 3: MPSAS >= 21.3  (Rural sky)
    - Bortle 4: MPSAS >= 20.4  (Rural/suburban transition)
    - Bortle 5: MPSAS >= 19.1  (Suburban sky)
    - Bortle 6: MPSAS >= 18.5  (Bright suburban)
    - Bortle 7: MPSAS >= 18.0  (Suburban/urban transition)
    - Bortle 8: MPSAS >= 17.0  (City sky)
    - Bortle 9: MPSAS < 17.0   (Inner city)
    """
    bortle = np.zeros_like(mpsas, dtype=np.uint8)

    bortle[mpsas >= 21.7] = 1
    bortle[(mpsas >= 21.5) & (mpsas < 21.7)] = 2
    bortle[(mpsas >= 21.3) & (mpsas < 21.5)] = 3
    bortle[(mpsas >= 20.4) & (mpsas < 21.3)] = 4
    bortle[(mpsas >= 19.1) & (mpsas < 20.4)] = 5
    bortle[(mpsas >= 18.5) & (mpsas < 19.1)] = 6
    bortle[(mpsas >= 18.0) & (mpsas < 18.5)] = 7
    bortle[(mpsas >= 17.0) & (mpsas < 18.0)] = 8
    bortle[mpsas < 17.0] = 9

    return bortle


def get_bortle_color_palette():
    """
    Returns a 16-color palette for Bortle scale visualization.

    Colors based on standard Light Pollution Atlas scheme:
    - Dark blue → Blue: Bortle 1-2 (dark sky)
    - Green: Bortle 3-4 (rural)
    - Yellow/Olive: Bortle 5-6 (suburban)
    - Orange/Red: Bortle 7-8 (urban)
    - Pink/White: Bortle 9 (inner city)
    """
    palette = [
        (0, 0, 0),          # 0: Black (no data/water)
        (20, 47, 114),      # 1: Dark blue (Bortle 1)
        (33, 84, 216),      # 2: Blue (Bortle 2)
        (15, 87, 20),       # 3: Dark green (Bortle 3)
        (31, 161, 42),      # 4: Green (Bortle 4)
        (110, 100, 30),     # 5: Olive (Bortle 5)
        (184, 166, 37),     # 6: Yellow (Bortle 6)
        (191, 100, 30),     # 7: Dark orange (Bortle 7)
        (253, 150, 80),     # 8: Orange (Bortle 8)
        (251, 90, 73),      # 9: Red/salmon (Bortle 9)
        (34, 34, 34),       # 10-15: Reserved/unused
        (66, 66, 66),
        (251, 153, 138),
        (255, 255, 255),
        (128, 128, 128),
        (255, 0, 255),
    ]

    # Flatten to PIL format: [R1, G1, B1, R2, G2, B2, ...]
    flat_palette = []
    for rgb in palette:
        flat_palette.extend(rgb)

    return flat_palette


def process_world_atlas(input_tif, output_png, target_width=21600):
    """
    Process World Atlas TIFF to Bortle-classified PNG.

    Args:
        input_tif: Path to World_Atlas_2015.tif
        output_png: Path to output PNG
        target_width: Target width in pixels (height calculated to maintain aspect)
    """
    print(f"Opening {input_tif}...")
    dataset = gdal.Open(input_tif, gdal.GA_ReadOnly)

    if dataset is None:
        print(f"ERROR: Could not open {input_tif}")
        sys.exit(1)

    # Get original dimensions
    orig_width = dataset.RasterXSize
    orig_height = dataset.RasterYSize

    print(f"Original dimensions: {orig_width}x{orig_height}")
    print(f"Target width: {target_width}")

    # Calculate target height maintaining aspect ratio
    target_height = int(orig_height * (target_width / orig_width))

    print(f"Target dimensions: {target_width}x{target_height}")
    print(f"Reading and resampling raster data...")

    # Read band 1 (brightness data in mcd/m²)
    band = dataset.GetRasterBand(1)

    # Read with resampling for smaller output
    brightness_data = band.ReadAsArray(
        xoff=0, yoff=0,
        win_xsize=orig_width, win_ysize=orig_height,
        buf_xsize=target_width, buf_ysize=target_height,
        resample_alg=gdal.GRA_Average  # Use averaging for downsampling
    )

    print(f"Data shape: {brightness_data.shape}")
    print(f"Data type: {brightness_data.dtype}")
    print(f"Brightness range: {brightness_data.min():.6f} - {brightness_data.max():.6f} mcd/m²")

    # Convert brightness to MPSAS
    print("Converting brightness to MPSAS...")
    mpsas_data = brightness_to_mpsas(brightness_data)

    print(f"MPSAS range: {mpsas_data.min():.2f} - {mpsas_data.max():.2f}")

    # Convert MPSAS to Bortle scale
    print("Converting MPSAS to Bortle scale...")
    bortle_data = mpsas_to_bortle(mpsas_data)

    print(f"Bortle range: {bortle_data.min()} - {bortle_data.max()}")

    # Count pixels per Bortle class
    print("\nBortle class distribution:")
    for i in range(1, 10):
        count = np.sum(bortle_data == i)
        percentage = 100 * count / bortle_data.size
        print(f"  Bortle {i}: {count:,} pixels ({percentage:.2f}%)")

    # Create indexed color image
    print("\nCreating indexed color PNG...")
    img = Image.fromarray(bortle_data, mode='P')

    # Apply color palette
    palette = get_bortle_color_palette()
    img.putpalette(palette)

    # Save with optimization
    print(f"Saving to {output_png}...")
    img.save(output_png, optimize=True, compress_level=9)

    file_size_mb = os.path.getsize(output_png) / (1024 * 1024)
    print(f"✓ Saved successfully! File size: {file_size_mb:.1f} MB")

    dataset = None  # Close GDAL dataset


if __name__ == "__main__":
    import os

    # Paths
    input_tif = "/Users/hp/Desktop/Work/Repositories/Astr/Light_Pollution_ATLAS/World_Atlas_2015.tif"
    output_png = "/Users/hp/Desktop/Work/Repositories/Astr/assets/maps/world_atlas_2015_bortle.png"

    if not os.path.exists(input_tif):
        print(f"ERROR: Input file not found: {input_tif}")
        sys.exit(1)

    # Create output directory if needed
    os.makedirs(os.path.dirname(output_png), exist_ok=True)

    print("=" * 70)
    print("World Atlas 2015 → Bortle Scale PNG Converter")
    print("=" * 70)
    print()

    # Process with target width of 21600 pixels (half of original ~43200)
    # This gives good accuracy while keeping file size around 10-15MB
    process_world_atlas(input_tif, output_png, target_width=21600)

    print()
    print("=" * 70)
    print("DONE! You can now use the generated map in your Flutter app.")
    print("=" * 70)
    print()
    print("Next steps:")
    print("1. Update png_map_service.dart to load 'world_atlas_2015_bortle.png'")
    print("2. The color-to-Bortle mapping is already configured correctly")
    print("3. Test with New Delhi - should now show Bortle 8-9")
