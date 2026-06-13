# archive/backend — MongoDB/Flask Backend (Archived)

**Archived:** Phase 1, 2026-06-13
**Original location:** `backend/` (repo root)

---

## What This Was

This folder contains the original MongoDB/Flask REST API that served light pollution zone data to the Astr app.

**Stack:**
- Flask 3.0.0 — Python web framework
- pymongo 4.6.0 — MongoDB client
- Python 3.x with virtualenv (`venv/`)

**Endpoints:**
- `POST /api/light-pollution` — Looked up light pollution zone for a given coordinate via MongoDB queries. Accepted `lat`/`lon` and returned a Bortle class value.

**Scripts (in `scripts/`):**
- `check_mongo_count.py` — Checked MongoDB record count for the zone collection.
- `download_nasa_data.py` — Downloaded NASA VIIRS/MODIS HDF5 data tiles (the predecessor pipeline to the current VNL approach).
- `process_nasa_data.py` — Processed NASA HDF5 data files to extract light pollution radiance values for H3 zones.

These `scripts/` files represent the older VIIRS HDF5 / NASA LAADS DAAC pipeline, which was superseded by the VNL NPP 2024 pipeline documented in `archive/data-pipeline/README.md`.

**Deployment:** Deployed on Vercel via Python serverless runtime (`vercel.json` included).

---

## Why It Was Archived (Phase 1, 2026-06-13)

The entire backend architecture was replaced:

1. **Zone data** is now served by the Cloudflare Worker in `cloudflare/` — it reads from Cloudflare R2 (binary `zones.db`) and D1 (SQL fallback). No MongoDB dependency.
2. **Weather data** now comes from Open-Meteo directly via `OpenMeteoWeatherService` in `lib/features/dashboard/data/datasources/open_meteo_weather_service.dart`. No Flask proxy needed.
3. No active Flutter code (in `lib/`) references this backend. It was Python-only; no Dart files imported from or called it.
4. The `MONGODB_URI` and `NASA_EARTHDATA_APP_KEY` environment variables are no longer consumed by any active code path.

---

## What Replaced It

| Concern | Replacement | Location |
|---------|-------------|----------|
| Zone lookup (light pollution) | Cloudflare Worker + R2/D1 | `cloudflare/` |
| Weather data | Open-Meteo HTTP API | `lib/features/dashboard/data/datasources/open_meteo_weather_service.dart` |
| Zone DB generation | VNL NPP 2024 pipeline | `scripts/generate_zones_vnl.py`, `scripts/apply_skyglow.py` |

---

## Note on Credentials

`backend/.env` (present alongside this README, not committed — excluded by `backend/.gitignore`) contains:

- `MONGODB_URI` — MongoDB Atlas connection string. **Inert** — no active code references it.
- `NASA_EARTHDATA_APP_KEY` — NASA Earthdata API key for the old VIIRS HDF5 download pipeline. **Inert** — the VNL pipeline does not require this key.

Both secrets are for dead services with no active consumers. The file is excluded from git by `backend/.gitignore` and the `archive/` entry in the root `.gitignore`.

---

## See Also

- `archive/data-pipeline/README.md` — Full reproduction guide for the current VNL-based zone generation pipeline (including what replaced the MongoDB-era `scripts/` here).
- `archive/api/README.md` — Documents the Python/Vercel serverless function that was the API gateway in front of this Flask app.
- `archive/INDEX.md` — Root index of all archived subfolders.
