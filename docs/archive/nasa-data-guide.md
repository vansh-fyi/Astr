# NASA Black Marble Data Download Guide

This guide explains how to download **VNP46A2 (Daily Lunar-Bidirectional Reflectance Distribution Function-Adjusted Nighttime Lights)** HDF5 files for use with the Astr backend.

## 1. Create a NASA Earthdata Account

Access to NASA data requires a free account.
1. Go to [NASA Earthdata Login](https://urs.earthdata.nasa.gov/).
2. Click **Register** and create an account.
3. Verify your email.

## 2. Find Your Tile (hXXvYY)

NASA MODIS/VIIRS data uses a specific grid system (Sinusoidal Tile Grid). You need to know which "Tile" covers your location.

- **Interactive Map:** Use the [MODIS Land Global Grid](https://modis-land.gsfc.nasa.gov/MODLAND_grid.html) or simply guess based on coordinates.
- **Common Tiles:**
    - **New York / NE USA:** h12v04
    - **California / West USA:** h08v05
    - **UK / Western Europe:** h17v03 or h18v03
    - **India:** h24v06 or h25v06

## 3. Search and Download Data

We recommend using **NASA LAADS DAAC** or **Earthdata Search**.

### Option A: Earthdata Search (Recommended)
1. Go to [Earthdata Search](https://search.earthdata.nasa.gov/search).
2. In the search bar, type: `VNP46A2`.
3. Select the collection: **VNP46A2 - VIIRS/NPP Gap-Filled Lunar BRDF-Adjusted NTL Daily L3 Global 500m Linear Lat Lon Grid**.
4. **Filter by Time:** Click the "Time" button and select a recent date (e.g., last month).
    - *Note: Data usually has a lag of a few days to a week.*
5. **Filter by Location:**
    - You can draw a rectangle on the map around your area of interest.
    - Or search for a specific tile ID if you know it.
6. Click on a file in the list to download it.
    - Filename format: `VNP46A2.AYYYYDDD.hXXvYY.001.2023...h5`
    - Ensure it ends in `.h5` or `.hdf`.

### Option B: LAADS DAAC Archive
1. Go to [LAADS DAAC Archive](https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/5000/VNP46A2/).
2. Select the **Year** (e.g., 2024).
3. Select the **Day of Year** (001 to 365).
    - *Tip: Google "Day of year calendar" to find the number for today's date.*
4. Look for the file matching your tile (e.g., `h12v04`).
5. Click to download.

### Option C: Automated Python Script (Recommended)

We have created a script to automate the download process using the `earthaccess` library.

1.  **Install Dependencies:**
    ```bash
    pip install earthaccess
    ```

2.  **Run the Downloader:**
    ```bash
    # Example: Download data for New York (h12v04) for Jan 2024
    python backend/scripts/download_nasa_data.py --tile h12v04 --start 2024-01-01 --end 2024-01-05
    ```

3.  **Authentication:**
    - The script will ask for your NASA Earthdata username and password the first time.
    - It saves a token so you don't have to login again.

---

## 4. Process the Data

Once downloaded to your laptop:

1. Place the file in the `backend/` folder (or anywhere accessible).
2. Run the processing script:

```bash
# Dry run (check output without uploading)
python backend/scripts/process_nasa_data.py --file VNP46A2.A2024032.h12v04.001.h5

# Upload to MongoDB (Real run)
python backend/scripts/process_nasa_data.py --file VNP46A2.A2024032.h12v04.001.h5 --upload
```

## Troubleshooting

- **401 Unauthorized:** If clicking the link gives a 401 error, you need to authorize the application. Usually, logging into Earthdata in the same browser session fixes this.
- **Missing h5py:** If the script fails, ensure you installed dependencies: `pip install h5py numpy pymongo dnspython python-dotenv`.

## 5. Global Coverage vs. Storage Limits (CRITICAL)

**You cannot store high-resolution data for the entire world on the MongoDB Free Tier.**

- **MongoDB Atlas Free Tier Limit:** 512 MB.
- **One Tile (Full Res):** ~5 million points (~500 MB uncompressed DB size).
- **The World:** ~300+ tiles.

### Strategies

#### A. Regional High-Res (Recommended)
Download and process tiles **only for your target markets** (e.g., US, Europe, India) with a moderate step (e.g., `--step 10` for ~5km resolution).
- **Command:** `python backend/scripts/process_nasa_data.py --file ... --step 10 --upload`
- **Pros:** Accurate street-level data for users.
- **Cons:** No data for unmapped regions (app falls back to general calculation).

#### B. Global Low-Res (Background Map)
Process **all tiles** but with a very large step (e.g., `--step 100` for ~50km resolution).
- **Command:** `python backend/scripts/process_nasa_data.py --file ... --step 100 --upload`
- **Pros:** Global coverage. Fits in Free Tier (~20MB total).
- **Cons:** Very blurry. Misses small dark sky parks.

   - *Note: The script upserts data, so high-res points will coexist with low-res points.*

## 6. Production Rollout Strategy (The "Free Tier" Plan)

To roll this out to users globally without paying for database storage, use **Strategy B (Global Low-Res)**.

**The Math:**
- **Resolution:** Step 100 (~50km x 50km pixels).
- **Total Points:** ~200,000 points for the entire Earth.
- **DB Size:** ~20 MB (well within the 512 MB limit).
- **Accuracy:** Sufficient for general Bortle Class (1-9) indication. Light pollution is diffuse; it doesn't change sharply every meter.

**The "Sweet Spot" (20km Resolution):**
If you want better accuracy, you can use **Step 40** (~20km resolution).
- **Total Points:** ~500,000 points.
- **DB Size:** ~75 MB.
- **Verdict:** **Safe!** This leaves >400 MB for user data.

**The "Danger Zone" (10km Resolution / Step 20):**
- **Total Points:** ~4.3 million points.
- **Estimated DB Size:** **~650 MB - 800 MB**.
- **Verdict:** **UNSAFE.** This exceeds the 512 MB Free Tier limit. You would need to upgrade to a paid MongoDB cluster (~$9/month).

**Action Plan:**
1. Download all ~300 tiles from NASA (use their "Bulk Download" script).
2. Run the processor with `--step 40` (20km resolution) for all files.
3. Your app now works globally with good accuracy for $0.
4. As you grow, upgrade MongoDB and ingest higher-resolution data.
