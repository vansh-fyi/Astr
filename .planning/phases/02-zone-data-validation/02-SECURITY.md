---
phase: "02"
slug: zone-data-validation
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-04
---

# Phase 02 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| developer shell → Python scripts | CLI args passed to apply_skyglow.py and validate_zones_db.py | Path strings, numeric parameters — developer-only, no user input |
| zones_accumulator.db → assets/db/zones.db | Binary read from local SQLite, write to binary format | Satellite radiance floats, H3 indices — no PII |
| developer shell → Cloudflare D1 | wrangler d1 execute --remote with generated SQL chunks | Zone integers, radiance floats — public satellite data |
| developer shell → Cloudflare R2 | upload_to_r2.py using env-var S3 credentials | zones.db binary — public data, 715 MB |
| Cloudflare Worker → app client | HTTPS JSON response from /zone/{h3} endpoint | Zone integer, radiance float, SQM float — public |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-02-01 | Tampering | CLI args in apply_skyglow.py / validate_zones_db.py | accept | argparse + pathlib.Path validates inputs; developer-only script, no user input reaches production | closed |
| T-02-02 | Info Disclosure | zones_accumulator.db at repo root | accept | File is gitignored and documented in archive/data-pipeline/README.md; no PII; low-value satellite radiance data | closed |
| T-02-03 | Tampering | darkness_calculator_test.dart assertions | accept | Tests are developer-authored and reviewed; DarknessCalculator is pure math with no external input | closed |
| T-02-04 | Tampering | zones_accumulator.db overwrite during re-scan | accept | Single trusted developer; gitignored; interrupted write is recoverable by re-running from TIF source | closed |
| T-02-05 | Info Disclosure | R2 credentials during apply_skyglow.py run | accept | Credentials set as env vars only, never committed to git; R2 not touched in Plan 03 | closed |
| T-02-06 | Tampering | zones.db file integrity (correct version used for deploy) | mitigate | SHA-256 comparison performed before deploy: 09cb4d99... confirmed matching Plan 03 output in 02-04-SUMMARY.md | closed |
| T-02-07 | Tampering | D1 SQL injection via generated SQL chunks | accept | export_zones_to_sql.py generates values from trusted struct-unpacked binary data, not user input; no injection surface | closed |
| T-02-08 | Info Disclosure | R2 credentials in deploy environment | mitigate | upload_to_r2.py reads credentials via os.environ.get() only; no .env file tracked in git (verified: git ls-files shows no .env) | closed |
| T-02-09 | EoP | wrangler --remote executing against production D1 | accept | Production database holds only public satellite radiance data (no PII, no secrets); worst case is corrupted zone data, recoverable by re-import from zones.db | closed |
| T-02-SC | Tampering | npm/pip/cargo supply chain (×5 plans) | accept | No new packages installed across any plan; all dependencies pre-installed in scripts/.venv and cloudflare/node_modules | closed |
| T-02-TF01 | Info Disclosure | R2 API token cca1376b... exposed in deploy session conversation history | mitigate | Token rotated by developer after session. New token scoped to Object Read & Write on astr-zones bucket only. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-02-01 | T-02-01 | apply_skyglow.py and validate_zones_db.py are developer-only pipeline scripts; no user input reaches them in production | vanshgrover.work@gmail.com | 2026-07-04 |
| AR-02-02 | T-02-02 | zones_accumulator.db contains only satellite radiance floats and H3 indices — no PII, no secrets, no credentials | vanshgrover.work@gmail.com | 2026-07-04 |
| AR-02-03 | T-02-03 | Darkness calculator tests are pure Dart math; no network, no I/O, no external input surface | vanshgrover.work@gmail.com | 2026-07-04 |
| AR-02-04 | T-02-04 | Accumulator overwrite risk is limited to a developer re-running the pipeline; fully recoverable from the source TIF file | vanshgrover.work@gmail.com | 2026-07-04 |
| AR-02-05 | T-02-09 | Cloudflare D1 holds only public satellite data. A corrupted import is the worst-case outcome and is recoverable in ~30 min | vanshgrover.work@gmail.com | 2026-07-04 |
| AR-02-06 | T-02-SC | No new packages installed across all 5 Phase 02 plans; existing pinned dependencies in scripts/.venv and cloudflare/node_modules | vanshgrover.work@gmail.com | 2026-07-04 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-04 | 11 | 11 | 0 | Claude Sonnet 4.6 (gsd-secure-phase) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter
