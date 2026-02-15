# Cloudflare D1 Setup Guide for Astr

This guide explains how to set up the Astr Zones API on Cloudflare Workers with D1.

## Prerequisites

1. **Node.js** 18+
2. **Wrangler CLI**: `npm install -g wrangler`
3. **Cloudflare Login**: `wrangler login`

## 1. Create the D1 Database

```bash
wrangler d1 create astr-zones-db
```

Copy the `database_id` from the output into `cloudflare/wrangler.toml`:

```toml
name = "astr-zones"
main = "worker.js"
compatibility_date = "2024-12-01"

[[r2_buckets]]
binding = "ZONE_BUCKET"
bucket_name = "astr-zones"

[[d1_databases]]
binding = "DB"
database_name = "astr-zones-db"
database_id = "YOUR_DATABASE_ID_HERE"
```

## 2. Generate Zone Data

The data pipeline processes VIIRS satellite imagery through skyglow propagation:

```bash
cd scripts

# Step 1: Generate base zones from VNL raster
python generate_zones_vnl.py --tif "../VNL NPP 2024 Global Masked Data.tif.gz"

# Step 2: Apply atmospheric skyglow propagation
python apply_skyglow.py --tif "../VNL NPP 2024 Global Masked Data.tif.gz"

# Step 3: Generate SQL and import to D1
./setup_d1.sh
```

The pipeline outputs `assets/db/zones.db` (binary format for offline) and SQL files for D1 import.

## 3. Upload to Cloudflare

```bash
# Import SQL parts to D1 (commands printed by setup_d1.sh)
wrangler d1 execute astr-zones-db --file=../assets/db/zones_part1.sql --remote
wrangler d1 execute astr-zones-db --file=../assets/db/zones_part2.sql --remote
# ... continue for all parts

# Upload zones.db to R2 for offline download endpoint
wrangler r2 object put astr-zones/zones.db --file ../assets/db/zones.db

# Deploy the Worker
cd ../cloudflare && npx wrangler deploy
```

## 4. Verify

```bash
# Health check
curl https://astr-zones.astr-vansh-fyi.workers.dev/health

# Zone lookup (NYC)
curl https://astr-zones.astr-vansh-fyi.workers.dev/zone/862a100d7ffffff
```

## 5. API Endpoints

| Endpoint | Description | Response |
|----------|-------------|----------|
| `GET /zone/{h3hex}` | Zone lookup by H3 index | `{ bortle, ratio, sqm, h3 }` |
| `GET /health` | Health + record count | `{ status: "ok", records: N }` |
| `GET /stats` | Record count + backend | `{ records, backend: "d1" }` |
| `GET /download` | Stream zones.db from R2 | Binary file (~913 MB) |

## 6. Global Coverage Logic

The database **only stores zones with light (Zone ≥ 2)**.

- **Query returns a row** → That is the light pollution level
- **Query returns NULL** → Location is **Zone 1 (Pristine)** with `"implicit": true`

This ensures 100% global coverage without storing billions of empty ocean/wilderness records.

## 7. Zone Classification

Zones are assigned using calibrated radiance thresholds:

| Radiance (nW/cm²/sr) | Zone |
|----------------------|------|
| ≥ 125.0 | 9 |
| ≥ 50.0 | 8 |
| ≥ 20.0 | 7 |
| ≥ 9.0 | 6 |
| ≥ 3.0 | 5 |
| ≥ 1.0 | 4 |
| ≥ 0.50 | 3 |
| ≥ 0.25 | 2 |
| < 0.25 | 1 |

H3 resolution: **8** (~0.74 km² hexagons)
