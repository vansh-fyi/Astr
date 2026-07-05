---
phase: 02-zone-data-validation
plan: "05"
subsystem: zone-data-pipeline
tags: [cloudflare, d1, r2, deploy, production]
dependency_graph:
  requires: [02-04]
  provides: [production-zone-data-live]
  affects: []
tech_stack:
  added: [boto3]
  patterns: [d1-chunked-import, r2-multipart-upload, wrangler-remote]
key_files:
  created: []
  modified:
    - Cloudflare D1 astr-zones-db (production — 37,528,537 records)
    - Cloudflare R2 astr-zones/zones.db (production — 715.8 MB)
decisions:
  - "148 SQL chunks imported in numeric order (seq 1 148) — first attempt used incorrect shell sort which corrupted D1; fixed by explicit numeric sequence"
  - "DROP TABLE + CREATE TABLE in chunk 1 correctly wiped old 47.9M records before inserting 37.5M new records"
  - "R2 upload ran in parallel with D1 import — no dependency between them"
  - "boto3 installed into scripts/.venv for R2 S3-compatible upload"
metrics:
  duration_minutes: 22
  completed_date: "2026-06-14"
  tasks_completed: 2
  files_changed: 0
---

# Phase 02 Plan 05: Cloudflare D1 + R2 Deploy Summary

**One-liner:** Corrected zones.db (37.5M records, SCATTER_FRACTION=0.06) deployed to Cloudflare D1 and R2; live Worker endpoint verified returning correct zones for all spot-check locations.

## Task 1: D1 SQL Import

### SQL chunk generation

```bash
source scripts/.venv/bin/activate
python scripts/export_zones_to_sql.py --db assets/db/zones.db --out assets/db/
```

- Input: `assets/db/zones.db` (715.8 MB, 37,528,537 records)
- Output: 148 SQL files (`zones_part1.sql` … `zones_part148.sql`) in `assets/db/`
- Chunk 1 contains `DROP TABLE IF EXISTS zones` + `CREATE TABLE` + first INSERT batch
- Chunks 2–148 are INSERT-only

### Import sequence

First attempt failed — the bash sort `sort -t 't' -k2 -V` split on the character 't' incorrectly, causing chunks to run out of numeric order. The DROP TABLE in chunk 1 ran mid-sequence, wiping already-imported data. Result: 47,377,626 records (corrupt merge with old table).

Fix: dropped and recreated the table interactively, then re-imported with explicit `seq 1 148`:

```bash
# Interactive (user terminal — needed for wrangler auth):
cd cloudflare
node_modules/.bin/wrangler d1 execute astr-zones-db \
  --command "DROP TABLE IF EXISTS zones; CREATE TABLE zones (h3 INTEGER PRIMARY KEY, zone INTEGER, radiance REAL, sqm REAL);" \
  --remote

# Background (with CLOUDFLARE_API_TOKEN set):
for i in $(seq 1 148); do
  node_modules/.bin/wrangler d1 execute astr-zones-db \
    --file "../assets/db/zones_part${i}.sql" --remote
done
```

### D1 verification

```
SELECT COUNT(*) as total FROM zones;
→ total: 37,528,537  ✓
```

Matches `assets/db/zones.db` record count exactly. Import confirmed clean.

## Task 2: R2 Upload

```bash
export R2_ACCOUNT_ID="5ba03fba..."
export R2_ACCESS_KEY_ID="cca1376b..."
export R2_SECRET_ACCESS_KEY="e070eb20..."
source scripts/.venv/bin/activate
python scripts/upload_to_r2.py
```

- Bucket: `astr-zones` (pre-existing)
- Object key: `zones.db`
- Size: 0.70 GB
- SHA-256: `09cb4d9920c65fc70eebfa098223809e9b7dd451aecc01965d6aef54f7b83f08` ✓ (matches Plan 03 generated file)
- Upload: multipart, 10 concurrent parts, completed successfully

**Note:** R2 credentials were shared in conversation — rotate the API token after this session (Cloudflare Dashboard → R2 → Manage R2 API Tokens).

## Live Worker Endpoint Verification

Worker: `https://astr-zones.astr-vansh-fyi.workers.dev/zone/{h3hex}`

| Location | H3 Index | Response | Expected Zone | Status |
|----------|----------|----------|---------------|--------|
| New York, USA | `882a107289fffff` | `{"bortle":9,"ratio":247.76,"sqm":17.42}` | 9 | ✅ |
| Wellington, NZ | `88bb2955a3fffff` | `{"bortle":8,"ratio":59.47,"sqm":18.47}` | 8 | ✅ |
| Anchorage, Alaska | `880c733849fffff` | `{"bortle":8,"ratio":124.66,"sqm":17.92}` | 8 | ✅ |
| Death Valley, USA | `88298571c9fffff` | `{"bortle":1,"ratio":0,"sqm":22,"implicit":true}` | 1 | ✅ |

All responses match the validator output exactly. The `implicit: true` flag on Death Valley confirms Zone 1 cells are correctly handled (not stored in D1, returned as implicit dark sky).

## Tester Instructions — Clearing Hive Zone Cache

The app caches zone data in Hive (`zoneCache` box) with a TTL of 365 days. Test devices will continue showing old zones until the cache is cleared.

To test corrected zones on device:
1. **Clear app data** (Android: Settings → Apps → Astr → Clear Storage) or **reinstall the app** (iOS/Android) to flush the Hive `zoneCache` box entirely
2. **Wait for Cloudflare edge cache to expire** — if the Worker was queried recently, edge cache may serve stale data for up to 1 hour (CACHE_TTL in worker.js)
3. **Re-open the app** and navigate to a previously-wrong location — the corrected zone will be fetched from D1 and cached fresh

For quick dev testing without reinstall: add a cache-clear button in debug settings, or call `Hive.box('zoneCache').clear()` from a debug breakpoint.

## Commits

No source code commits (D1 and R2 are production infrastructure; SQL chunks and zones.db are gitignored).

## Threat Flags

- **R2 credentials shared in conversation history** — rotate the `cca1376b...` API token immediately after this session. New token only needs Object Read & Write on `astr-zones` bucket.

## Self-Check: PASSED

- D1 record count: 37,528,537 ✓ (matches zones.db)
- R2 SHA-256: `09cb4d99...` ✓ (matches Plan 03 output)
- Live Worker: all 4 spot-check locations return correct zone ✓
- Implicit Zone 1 handling confirmed (Death Valley returns `implicit: true`) ✓
- Tester cache-clear instructions documented ✓
- ZONE-03 satisfied: corrected zone data is live in production ✓
