#!/usr/bin/env python3
from osgeo import gdal
import numpy as np

# Open World Atlas TIFF
ds = gdal.Open('/Users/hp/Desktop/Work/Repositories/Astr/Light_Pollution_ATLAS/World_Atlas_2015.tif')

# New Delhi coordinates
lat, lng = 28.6139, 77.2090

# Convert to pixel coordinates
width, height = ds.RasterXSize, ds.RasterYSize
x = int((lng + 180.0) * (width / 360.0))
y = int((90.0 - lat) * (height / 180.0))

print(f"New Delhi: lat={lat}, lng={lng}")
print(f"Pixel coordinates: x={x}, y={y}")
print(f"Image dimensions: {width}x{height}")
print()

# Read the brightness value at that pixel
band = ds.GetRasterBand(1)
window = band.ReadAsArray(x, y, 1, 1)
brightness = window[0, 0]

print(f"Raw brightness value: {brightness}")
print()

# Try different interpretations
print("Interpretations:")
print(f"1. As ratio to natural sky: {brightness:.2f}x")
print(f"2. As radiance (nW·cm⁻²·sr⁻¹): {brightness} nW·cm⁻²·sr⁻¹")
print()

# Calculate MPSAS different ways
mpsas_ratio = 21.58 - 2.5 * np.log10(brightness + 1)
print(f"MPSAS (if ratio): {mpsas_ratio:.2f}")

# If it's radiance in nW·cm⁻²·sr⁻¹, convert to mcd/m²
# 1 mcd/m² ≈ 3.4 nW·cm⁻²·sr⁻¹
brightness_mcd = brightness / 3.4
mpsas_radiance = 21.58 - 2.5 * np.log10(brightness_mcd / 174.0 + 1)
print(f"MPSAS (if radiance): {mpsas_radiance:.2f}")

print()
print("Expected for New Delhi: MPSAS ~16-17 (Bortle 8-9)")

ds = None
