# H3 Data Pipeline Scripts

This directory contains Python scripts for generating the production `zones.db` binary database used by the Astr app for light pollution data.

## Overview

The ETL (Extract, Transform, Load) pipeline downloads NASA VIIRS nighttime lights data and converts it to H3-indexed light pollution zones.

**Data Flow:**
1. Download NASA VNP46A2 tiles (Black Marble nighttime lights) → HDF5 format
2. Extract radiance values from HDF5 grids
3. Convert pixel coordinates (lat/lon) → H3 Resolution 8 indices
4. Calculate Bortle class and SQM values from radiance
5. Write binary `zones.db` with sorted H3 indices for binary search

## Scripts

### `generate_h3_db_v2.py` ⭐ RECOMMENDED
**Purpose**: Full production ETL pipeline for generating zones.db from NASA VIIRS data with **correct MODIS sinusoidal projection handling**.

> [!IMPORTANT]
> This version fixes a critical bug in v1 where tile coordinates were incorrectly calculated using simple equirectangular math instead of proper MODIS sinusoidal projection. Use this version for production data generation.

**Requirements**:
```bash
pip install -r requirements.txt
```

**Setup**:
1. Create NASA Earthdata account: https://urs.earthdata.nasa.gov/users/new
2. Get App Key from LAADS DAAC: https://ladsweb.modaps.eosdis.nasa.gov/profile/
3. Add to `backend/.env`:
   ```
   NASA_EARTHDATA_APP_KEY=your_app_key_here
   ```

**Usage**:
```bash
# Install dependencies (including pyproj for projection math)
pip install -r scripts/requirements.txt

# Run the pipeline (processes in batches, restart to continue)
python3 scripts/generate_h3_db_v2.py
```

**Key Improvement**: Uses `pyproj` library to properly transform from MODIS sinusoidal projection (meters) to WGS84 lat/lon before calculating H3 indices. The validation step at startup confirms projection accuracy for major cities.

**Output**:
- Downloads HDF5 files to `NASA_VIIRS/` directory (gitignored)
- Generates `assets/db/zones.db` binary database
- Prints SHA-256 hash for updating `BinaryReaderService.expectedZonesDbHash`

---

### `generate_h3_db.py` ⚠️ DEPRECATED
**Purpose**: Original ETL pipeline with **incorrect tile coordinate calculation**.

> [!CAUTION]  
> This script has a bug where it assumes a simple 10° equirectangular grid instead of the MODIS sinusoidal projection. H3 indices generated are for wrong coordinates. Use `generate_h3_db_v2.py` instead.

**Tile Coverage**:
MODIS sinusoidal grid tiles cover ~10° × ~10° regions:
- Horizontal (h): 0-35 (West to East, 36 tiles)
- Vertical (v): 0-17 (North to South, 18 tiles)
- Example: h24v06 covers northern India/Nepal region

Find your region: https://modis-land.gsfc.nasa.gov/MODLAND_grid.html


---

### `generate_placeholder_zones_db.py`
**Purpose**: Generate a minimal test zones.db with 10 sample H3 indices for development/testing.

**Usage**:
```bash
python3 scripts/generate_placeholder_zones_db.py
```

**Output**:
- `assets/db/zones.db` (216 bytes: 16-byte header + 10 × 20-byte records)
- Prints SHA-256 hash
- Contains sample data covering Bortle classes 1-9

**Use Case**: Development and testing without downloading full NASA dataset.

---

## Binary Format Specification

### zones.db Structure (Story 1.3 Architecture)

**Header (16 bytes):**
```
Offset 0-3:   Magic "ASTR" (4 bytes ASCII)
Offset 4-7:   Version = 1 (uint32 little-endian)
Offset 8-15:  Record Count (uint64 little-endian)
```

**Records (20 bytes each, sorted by H3 index):**
```
Offset 0-7:   H3 Index (uint64 little-endian)
Offset 8:     Bortle Class 1-9 (uint8)
Offset 9-12:  Light Pollution Ratio (float32 little-endian, 0-10 scale)
Offset 13-16: SQM value (float32 little-endian, mag/arcsec²)
Offset 17-19: Reserved (3 bytes, zeros)
```

**Rationale**: Records include H3 index to enable O(log n) binary search for sparse spatial data. See Story 1.3 architecture fix documentation for details.

**Example**:
For 4 million H3 cells:
- File size: 16 + (4M × 20) = ~80 MB
- Lookup time: ~22 binary search iterations = ~100μs
- Meets NFR-01 performance requirement (< 100ms)

---

## Data Sources

**NASA VNP46A2 (VIIRS Black Marble):**
- **Source**: Suomi NPP satellite Day/Night Band (DNB)
- **Resolution**: 500m pixels
- **Coverage**: Global, daily
- **Format**: HDF5 tiles (MODIS sinusoidal grid)
- **Key Dataset**: `DNB_BRDF-Corrected_NTL` (radiance in nW/cm²/sr)
- **Documentation**: https://viirsland.gsfc.nasa.gov/Products/NASA/BlackMarble.html

**H3 Spatial Indexing:**
- **System**: Uber H3 hexagonal hierarchical spatial index
- **Resolution**: 8 (~0.7 km² per hexagon)
- **Documentation**: https://h3geo.org/

---

## Conversion Formulas

### Radiance → MPSAS (Magnitudes Per Square Arcsecond)
```python
# Placeholder approximation (needs calibration with scientific literature)
if radiance <= 0:
    mpsas = 22.0  # Pristine dark sky
else:
    mpsas = 22.0 - 2.5 * log10(radiance + 1)
```

**Note**: This formula is a rough approximation for MVP. Production should use calibrated conversion from scientific papers (e.g., Falchi et al. 2016).

### MPSAS → Bortle Scale
```python
if mpsas >= 21.69: return 1  # Excellent dark sky
elif mpsas >= 21.50: return 2
elif mpsas >= 21.30: return 3
elif mpsas >= 20.49: return 4
elif mpsas >= 19.10: return 5
elif mpsas >= 18.50: return 6
elif mpsas >= 18.00: return 7
elif mpsas >= 16.50: return 8
else: return 9  # Inner-city sky
```

Source: International Dark-Sky Association (IDA) Bortle Scale

---

## Troubleshooting

### Authentication Errors
**Problem**: `Auth Check Failed: HTTP 401`

**Solution**:
1. Verify NASA Earthdata account is active
2. Generate new App Key at https://ladsweb.modaps.eosdis.nasa.gov/profile/
3. Check `backend/.env` has correct `NASA_EARTHDATA_APP_KEY`
4. Ensure no extra whitespace in the key value

### No Files Found
**Problem**: `No files found for tile h24v06`

**Solution**:
1. Check tile identifier is correct (use MODIS grid map)
2. Verify target date has available data (VNP46A2 starts from 2012)
3. Try different day of year (some days may have gaps)

### HDF5 Structure Errors
**Problem**: `DNB_BRDF-Corrected_NTL dataset not found`

**Solution**:
1. Check HDF5 file structure manually: `h5dump -n <file.h5>`
2. Verify file is VNP46A2 product (not VNP46A1 or other variant)
3. File may be corrupted - re-download

### Memory Issues
**Problem**: Script crashes with memory error on large tiles

**Solution**:
1. Process tiles one at a time (modify script to iterate)
2. Use chunked reading for HDF5 (update `process_tile()`)
3. Increase system swap space

---

## Performance Notes

**Processing Time** (approximate):
- Single 1200×1200 tile: ~2-5 minutes
- 10 global tiles: ~30-60 minutes
- Full global dataset: Several hours (not recommended for MVP)

**Disk Space**:
- Single HDF5 tile: ~50-100 MB
- 10 tiles: ~500 MB - 1 GB
- zones.db output: ~80 MB for 4M H3 cells

**Optimization Tips**:
- Start with 1-2 test tiles
- Use recent dates (better data quality)
- Consider monthly composites instead of daily for cleaner data

---

## References

- **Architecture**: `_bmad-output/project-planning-artifacts/architecture.md`
- **Story 1.3**: Binary format and ZoneDataService implementation
- **Story 1.6**: This ETL pipeline implementation
- **Epic 1 Retrospective**: `_bmad-output/implementation-artifacts/epic-1-retro-2025-12-27.md`

---

## Security Notes

**Credentials**:
- NEVER commit `backend/.env` to git (already gitignored)
- NEVER hardcode App Keys in scripts
- Rotate keys if accidentally exposed

**Data Validation**:
- zones.db integrity verified via SHA-256 hash on app startup
- Hash must be updated in `BinaryReaderService.expectedZonesDbHash` after regeneration
