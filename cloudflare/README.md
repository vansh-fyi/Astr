# ASTR Zones API — Cloudflare Worker

Serves light pollution zone data via a JSON API, backed by Cloudflare D1 (SQLite).

## Quick Start

```bash
cd cloudflare
npm install

# 1. Login to Cloudflare
npx wrangler login

# 2. Create the D1 database
npx wrangler d1 create astr-zones-db
# Copy the database_id into wrangler.toml

# 3. Generate & import zone data (see scripts/setup_d1.sh)
cd ../scripts && ./setup_d1.sh

# 4. Deploy the Worker
cd ../cloudflare && npx wrangler deploy

# 5. Verify
curl https://astr-zones.<YOUR_SUBDOMAIN>.workers.dev/health
curl https://astr-zones.<YOUR_SUBDOMAIN>.workers.dev/zone/882a100d63fffff
```

## API

| Endpoint | Description | Response |
|---|---|---|
| `GET /zone/{h3hex}` | Zone lookup | `{ bortle, ratio, sqm, h3 }` |
| `GET /health` | Health + record count | `{ status: "ok", records: N }` |
| `GET /stats` | Record count + backend | `{ records, backend: "d1" }` |
| `GET /download` | Stream zones.db from R2 | Binary file (~913 MB) |

**Not-found behavior:** If an H3 index isn't in the database, the API returns Zone 1 (pristine dark sky) with `"implicit": true` — matching the app's local behavior.

## Architecture

```
Flutter App → CachedZoneRepository → RemoteZoneService
                                          ↓ HTTPS
                                    Cloudflare Worker
                                          ↓ SQL query
                                    D1 database (zones table)

Offline Mode:
  Settings → Download → R2 /download endpoint → local zones.db
           → ZoneDataService (binary search, no network needed)
```

Zone lookups are a single `SELECT * FROM zones WHERE h3 = ?` query on D1. The `/download` endpoint streams `zones.db` from R2 for the app's optional offline mode.

## Local Development

```bash
npx wrangler dev
# Then test: curl http://localhost:8787/health
```

> Note: `wrangler dev` uses local D1 by default. Run SQL imports with `--local` flag for dev.
