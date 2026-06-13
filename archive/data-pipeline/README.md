# Archive: Data Pipeline — VNL NPP 2024 Zone Generation Guide

This document is the full reproduction guide for the Astr zone generation pipeline (ARCH-04).
It covers every step needed to regenerate `assets/db/zones.db` from scratch using the
**VNL NPP 2024 (VIIRS Nighttime Lights) annual composite** data from Colorado School of Mines.

> **IMPORTANT:** This is NOT the same pipeline documented in `scripts/README.md`.
> That file documents the older VIIRS HDF5 / NASA LAADS DAAC pipeline
> (`generate_h3_db_v2.py`, `generate_h3_db.py`), which is superseded and whose
> scripts are no longer present. The current production method is the VNL TIF pipeline
> described in this document.

---

## 1. Environment Setup

**Python version:** 3.10+ recommended (scripts use f-strings, walrus, `match` not required)

**Dependencies for the pipeline scripts** (`scripts/requirements.txt` covers the older VIIRS
pipeline's deps; the VNL pipeline requires slightly different packages):

```bash
pip install rasterio h3 numpy scipy tqdm boto3
```

Exact version bounds that have been tested:
- `rasterio` — any recent (1.3+); requires GDAL under the hood
- `h3 >= 4.0.0, < 5.0.0` — H3 v4 API (`h3.latlng_to_cell`, not the v3 `h3.geo_to_h3`)
- `numpy >= 1.24.0`
- `scipy` — for `fftconvolve` used in `apply_skyglow.py`
- `tqdm` — progress bars
- `boto3` — for `upload_to_r2.py` (Cloudflare R2 via S3-compatible API)

**Recommended setup using a venv:**

```bash
cd /path/to/repo
python -m venv scripts/venv
source scripts/venv/bin/activate
pip install rasterio h3 numpy scipy tqdm boto3
```

> **GDAL note:** `rasterio` bundles GDAL on most platforms when installed via pip.
> If you get GDAL errors on Linux, install `gdal-bin` and `libgdal-dev` from your package
> manager, then `pip install rasterio --no-binary rasterio`.

---

## 2. Data Source

**Dataset:** VNL NPP 2024 Global Annual Average Masked Data
**Provider:** Colorado School of Mines — Earth Observation Group (EOG)
**URL:** https://eogdata.mines.edu/products/vnl/

**File to download:** `VNL NPP 2024 Global Masked Data.tif.gz`
(~3–5 GB compressed; already listed in `.gitignore` so it will not be committed)

This is a GeoTIFF (EPSG:4326, WGS84) containing per-pixel radiance values in
nW/cm²/sr for the 2024 annual composite. The `.gz` version can be read directly
by GDAL via `/vsigzip/` — no manual decompression needed.

> **This is different from the NASA VIIRS HDF5 pipeline:** The older approach used
> HDF5 tiles from NASA LAADS DAAC (`generate_h3_db_v2.py`), required reprojection
> from MODIS sinusoidal coordinates, and used `pyproj`. That pipeline is superseded
> and is not present in the current `scripts/` directory.

---

## 3. Exact Commands in Order

Place the downloaded TIF file at the repo root (or any path; pass it with `--tif`).

### Step 1 — Generate zone accumulator

```bash
# From repo root, with venv active:
python scripts/generate_zones_vnl.py --tif "VNL NPP 2024 Global Masked Data.tif.gz"
```

**What it does:**
- Reads the TIF in horizontal strips of 200 rows at a time (memory-safe)
- Reopens the GDAL file every 25 strips to flush vsigzip decompression buffers
- Caps GDAL internal cache at 256 MB (`GDAL_CACHEMAX`)
- For each pixel above the Zone 2 radiance threshold (≥ 0.25 nW/cm²/sr):
  - Converts pixel centroid (lat, lon) → H3 index at resolution 8 (~461 m cells)
  - Accumulates max radiance per H3 cell into SQLite (`ON CONFLICT DO UPDATE SET radiance = MAX(...)`)
- Writes a binary `zones.db` from the accumulator (see Section 6 for format)
- The accumulator is **resumable** — if interrupted, rerun the same command and it picks
  up from where it left off (completed strips are tracked in the `progress` table)

**Output:** `zones_accumulator.db` at the same directory as the TIF file (the accumulator)
and `assets/db/zones.db` (the final binary output, Zone 2+ records only).

**CLI flags:**
- `--tif <path>` — path to VNL TIF or TIF.GZ file (default: `scripts/data/vnl_average.tif`)
- `--reset` — delete the accumulator and start fresh (removes `zones_accumulator.db` + WAL/SHM files)
- `--skip-download` — (legacy flag, no-op in current version)

### Step 2 — Apply skyglow diffusion

```bash
python scripts/apply_skyglow.py --tif "VNL NPP 2024 Global Masked Data.tif.gz"
```

**What it does:**
- Reads the same TIF; applies a Garstang-inspired scatter model (see Section 5)
- Downsamples the raster by 12× (15 arcsec × 12 ≈ 3 arcmin ≈ 5.5 km/pixel coarse grid)
- Convolves the coarse grid with the scatter kernel using FFT (`scipy.signal.fftconvolve`)
- Re-scans the full-resolution TIF, adding interpolated scatter to each pixel's direct radiance
- Updates `zones_accumulator.db` with enhanced radiance values (max wins)
- Writes the final enhanced `assets/db/zones.db`

**Output:** Updated `zones_accumulator.db` + enhanced `assets/db/zones.db`

**CLI flags:**
- `--tif <path>` — path to VNL TIF or TIF.GZ (required)
- `--accum <path>` — path to accumulator DB (default: same directory as TIF)
- `--fraction <float>` — override scatter fraction (default: 0.12)
- `--scale-km <float>` — override exponential decay length in km (default: 20.0)

### Step 3 — Export to SQL for Cloudflare D1

```bash
python scripts/export_zones_to_sql.py
```

Reads `assets/db/zones.db` and writes chunked SQL files to `assets/db/zones_part1.sql`,
`zones_part2.sql`, etc. (10 MB chunks to stay within D1 upload limits).

Each SQL file creates/populates a `zones` table:
`zones(h3 INTEGER PRIMARY KEY, zone INTEGER, radiance REAL, sqm REAL)`

**CLI flags:**
- `--db <path>` — path to zones.db (default: `assets/db/zones.db`)
- `--out <path>` — output directory for SQL files (default: `assets/db/`)

### Step 4 — Upload to Cloudflare R2

```bash
# Set environment variables first:
export R2_ACCOUNT_ID=your_cloudflare_account_id
export R2_ACCESS_KEY_ID=your_r2_access_key
export R2_SECRET_ACCESS_KEY=your_r2_secret
export R2_BUCKET=astr-zones   # default bucket name

python scripts/upload_to_r2.py
```

Uploads `assets/db/zones.db` to the `astr-zones` R2 bucket using multipart upload
(100 MB chunks, 10× concurrency). Prints SHA-256 of the uploaded file.

**Required env vars:** `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`
**Optional:** `R2_BUCKET` (defaults to `astr-zones`)

Credentials come from Cloudflare Dashboard → R2 → Manage R2 API Tokens (Object Read + Write).

### Full ETL: run_etl_loop.sh (LEGACY — not for VNL pipeline)

> **WARNING:** `scripts/run_etl_loop.sh` is a legacy wrapper that calls
> `generate_h3_db.py` — the OLD VIIRS HDF5 pipeline script. Do NOT use it for
> the VNL pipeline. Run Steps 1–4 above manually.

---

## 4. Expected Intermediate Outputs

| File | Location | Size | Description |
|------|----------|------|-------------|
| `zones_accumulator.db` | Same directory as the TIF (typically repo root) | ~1.3 GB | SQLite accumulator: `cells(h3 INTEGER PK, radiance REAL)` + `progress(strip_idx INTEGER PK)` for resumability |
| `zones_accumulator.db-wal` | Same directory | Variable | SQLite WAL file (auto-managed, safe to leave) |
| `assets/db/zones.db` | Repo root → `assets/db/` | ~80 MB | Final binary zone database (see Section 6 for format) |

---

## 5. Skyglow Diffusion Parameters

The `apply_skyglow.py` script uses a Garstang-inspired atmospheric scatter model.
The scatter kernel PSF formula is:

```
scatter(d) = fraction × exp(−d / scale) / (1 + (d / d0)^power)
```

Where:

| Parameter | Variable in code | Value | Meaning |
|-----------|-----------------|-------|---------|
| `fraction` | `SCATTER_FRACTION` | **0.12** | 12% of upward light scatters horizontally |
| `scale` | `SCATTER_SCALE_KM` | **20.0 km** | Exponential decay length |
| `d0` | `D_REF_KM` | **10.0 km** | Reference distance for power-law falloff |
| `power` | `SCATTER_POWER` | **2.5** | Power-law exponent |
| `max_radius` | `MAX_RADIUS_KM` | **80.0 km** | Kernel truncation radius |
| `pixel_km` | `PIXEL_KM` | **5.55 km** | km per coarse pixel at equator (after 12× downsample) |
| `downsample` | `DOWNSAMPLE` | **12** | Downsampling factor (15 arcsec × 12 ≈ 3 arcmin/pixel) |

**scipy dependency:** `scipy.signal.fftconvolve` is used for the 2D convolution of the
coarse radiance grid with the scatter kernel. This is the only reason scipy is needed.

**Overridable via CLI:** `--fraction` and `--scale-km` can be passed to experiment
with different scatter parameters without editing the script.

**Radiance → Bortle zone thresholds** (calibrated from SQM ground-truth measurements,
must match identically in both `generate_zones_vnl.py` and `apply_skyglow.py`):

| Radiance threshold (nW/cm²/sr) | Bortle zone |
|-------------------------------|-------------|
| ≥ 125.0 | Zone 9 (inner city) |
| ≥ 50.0 | Zone 8 (dense urban) |
| ≥ 20.0 | Zone 7 (urban) |
| ≥ 9.0 | Zone 6 (bright suburban) |
| ≥ 3.0 | Zone 5 (suburban) |
| ≥ 1.0 | Zone 4 (rural/suburban transition) |
| ≥ 0.50 | Zone 3 (rural sky) |
| ≥ 0.25 | Zone 2 (typical dark site) |
| < 0.25 | Zone 1 (pristine — not written to zones.db) |

**SQM formula:** `sqm = clamp(22.0 − 1.7 × log10(1.0 + 2.0 × radiance), 16.0, 22.0)`

---

## 6. Final Output Format (zones.db binary format)

`assets/db/zones.db` is a little-endian binary file, not a SQLite database.

**Header (16 bytes):**

| Offset | Size | Type | Value |
|--------|------|------|-------|
| 0 | 4 | bytes | Magic: `ASTR` (`\x41\x53\x54\x52`) |
| 4 | 4 | bytes | Version: `\x01\x00\x00\x00` (version 1) |
| 8 | 8 | uint64 LE | Record count (patched after writing all records) |

**Records (20 bytes each, sorted ascending by H3 index):**

| Offset | Size | Type | Field |
|--------|------|------|-------|
| 0 | 8 | uint64 LE | H3 cell index (resolution 8, stored as integer) |
| 8 | 1 | uint8 | Bortle zone (2–9; Zone 1 is implicit/omitted) |
| 9 | 4 | float32 LE | Radiance (nW/cm²/sr) |
| 13 | 4 | float32 LE | SQM value (mag/arcsec²) |
| 17 | 3 | bytes | Reserved padding (`\x00\x00\x00`) |

Records are written in ascending H3 integer order to support binary search on the
Cloudflare Worker side.

**Validation:** After writing, the script prints the SHA-256 of `zones.db`. This hash
should be noted for updating the app's integrity check (see Section 7).

---

## 7. SHA-256 Hash Update After Regeneration

After regenerating `zones.db`, the file's SHA-256 hash changes. If the Flutter app
performs integrity verification of the bundled `assets/db/zones.db`, update the
expected hash constant.

**Search the codebase for the hash constant:**

```bash
grep -rn "expectedZonesDbHash\|zonesDbHash\|zones_db_hash" lib/ --include="*.dart"
```

As of Phase 1 (2026-06-13), no explicit hash constant was found in `lib/` — the app
uses the Cloudflare Worker for live zone lookups and the bundled `zones.db` is loaded
via `sqflite` without a hash check. If hash verification is added in a future phase,
look for it in:
- `lib/features/data_layer/` — zone data loading services
- `lib/features/splash/` — initialization sequence

When found, update `BinaryReaderService.expectedZonesDbHash` (or equivalent field)
with the SHA-256 printed by `generate_zones_vnl.py` or `apply_skyglow.py` upon
successful write.

---

## 8. zones_accumulator.db — DO NOT DELETE

**Location:** Repo root (same directory where the TIF file is placed, typically repo root)
**Size:** ~1.3 GB SQLite database
**Git status:** Gitignored via `zones_accumulator.db` in `.gitignore`

`zones_accumulator.db` is the intermediate accumulator built by `generate_zones_vnl.py`
and consumed/enhanced by `apply_skyglow.py`. It contains the `cells` table with every
H3 cell that has radiance ≥ 0.25 nW/cm²/sr, along with the `progress` table tracking
which TIF strips have been processed.

**Why it must not be deleted:**
- **Phase 2 (Zone Data Validation)** uses this database directly for validation
  (`scripts/validate_zones_db.py`, `scripts/validate_zones_extended.py`,
  `scripts/validate_global_coverage.py`)
- Regenerating it from scratch requires re-processing the full VNL TIF (~3–5 GB,
  multiple hours of CPU time)
- The resumable design means you can stop and restart processing without losing work

If you must reset: `python scripts/generate_zones_vnl.py --reset --tif <path>`
This deletes the accumulator and its WAL/SHM files before starting fresh.

---

## 9. Note About scripts/README.md

`scripts/README.md` documents the **older VIIRS HDF5 / NASA LAADS DAAC pipeline**.
That approach used:
- `generate_h3_db_v2.py` / `generate_h3_db.py` — H3 database generation from HDF5 tiles
- NASA LAADS DAAC as the data source (requires NASA Earthdata account)
- MODIS sinusoidal projection → WGS84 reprojection via `pyproj`
- HDF5 reading via `h5py`

Those scripts are **not present** in the current `scripts/` directory. The VNL NPP 2024
pipeline documented above is the current production method.

The `scripts/README.md` file is retained for historical context only. Do not use it as
a guide for regenerating the current `zones.db`.

---

## Pipeline Scripts Reference

| Script | Location | Purpose | Phase 2 Needed? |
|--------|----------|---------|-----------------|
| `generate_zones_vnl.py` | `scripts/` | Step 1: TIF → accumulator → zones.db | No (generation only) |
| `apply_skyglow.py` | `scripts/` | Step 2: Scatter diffusion → enhanced zones.db | No (generation only) |
| `export_zones_to_sql.py` | `scripts/` | Step 3: zones.db → SQL chunks for D1 | No |
| `upload_to_r2.py` | `scripts/` | Step 4: Upload zones.db to R2 | No |
| `validate_zones_db.py` | `scripts/` | Validates zones.db structure and spot-checks | **YES — Phase 2** |
| `validate_zones_extended.py` | `scripts/` | Extended geographic coverage validation | **YES — Phase 2** |
| `validate_global_coverage.py` | `scripts/` | Global H3 coverage checks | **YES — Phase 2** |
| `inspect_db.py` | `scripts/` | Debug: inspect accumulator contents | No |
| `inspect_h3.py` | `scripts/` | Debug: inspect H3 cell data | No |
| `debug_vnl_reading.py` | `scripts/` | Debug: VNL TIF reading diagnostics | No |
| `test_h3_int.py` | `scripts/` | H3 integer conversion test | No |
| `generate_city_db.dart` | `scripts/` | City database generation (Dart) | No |
