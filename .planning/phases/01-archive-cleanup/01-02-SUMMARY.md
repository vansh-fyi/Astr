---
phase: 01-archive-cleanup
plan: "02"
subsystem: infra
tags: [archive, api, vercel, python, pipeline, vnl, documentation]

# Dependency graph
requires: []
provides:
  - archive/api/ directory with all former api/ contents and README
  - archive/data-pipeline/README.md with full VNL NPP 2024 zone generation pipeline reproduction guide
  - ARCH-04 documentation deliverable
affects: [01-03, 01-04, 01-05, 01-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Archive README pattern: each archive/ subfolder gets README.md with What/Why Archived/What Replaced sections"
    - "Pipeline documentation: self-contained reproduction guide covering data source, scripts, parameters, upload steps"

key-files:
  created:
    - archive/api/README.md
    - archive/data-pipeline/README.md
  modified:
    - .gitignore

key-decisions:
  - "Force-add archive/ READMEs because gitignore exceptions cannot un-ignore files inside parent-ignored directory"
  - "Document VNL NPP 2024 pipeline (NOT superseded VIIRS HDF5 pipeline) per ARCH-04 requirement"
  - "Keep zones_accumulator.db at repo root (~1.3 GB) — gitignored but do NOT delete; Phase 2 dependency"

patterns-established:
  - "Archive README pattern: each archive/ subfolder gets a README.md with What/Why Archived/What Replaced sections"
  - "Pipeline doc pattern: step-by-step with exact commands, env vars, data source URLs, parameter values"

requirements-completed: [ARCH-04]

# Metrics
duration: 20min
completed: "2026-06-13"
---

# Phase 1 Plan 02: API Archive + Pipeline Documentation Summary

**Python/Vercel API archived to archive/api/; full VNL NPP 2024 zone generation pipeline reproduction guide written in archive/data-pipeline/README.md**

## Performance

- **Duration:** ~20 min
- **Completed:** 2026-06-13
- **Tasks:** 2/2

## Accomplishments

- Moved `api/index.py` (Python/Vercel serverless MongoDB proxy) to `archive/api/` preserving git rename history
- Created `archive/api/README.md` documenting: Flask serverless on Vercel, MongoDB proxy purpose, why archived (replaced by Cloudflare Worker + R2), what replaced it
- Created `archive/data-pipeline/README.md` with complete VNL NPP 2024 pipeline reproduction guide (ARCH-04):
  - Data source: `https://eogdata.mines.edu/products/vnl/` (VNL NPP 2024 Global Masked Data.tif.gz)
  - Step 1: `python scripts/generate_zones_vnl.py --tif "VNL NPP 2024 Global Masked Data.tif.gz"`
  - Step 2: `python scripts/apply_skyglow.py --tif "VNL NPP 2024 Global Masked Data.tif.gz"`
  - Step 3: `python scripts/export_zones_to_sql.py`
  - Step 4: `python scripts/upload_to_r2.py` (requires R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY)
  - Skyglow parameters: fraction=0.12, scale=20.0km, d0=10.0km, power=2.5, max_radius=80km
  - Binary zone format: 16-byte header (ASTR magic + version + record count) + 20-byte records
  - `zones_accumulator.db` location (~1.3 GB), importance, and DO NOT DELETE warning

## Task Commits

1. **Task 1: Archive api/ to archive/api/ with README** — `8e0dbc3` (chore)
2. **Task 2: Write VNL pipeline reproduction guide** — `50b7425` (docs)

## Files Created/Modified

- `archive/api/README.md` — Archive reference; Flask + pymongo stack, MongoDB proxy purpose, why archived, what replaced it
- `archive/data-pipeline/README.md` — ARCH-04 pipeline reproduction guide; VNL NPP 2024 data source, 4 pipeline steps, skyglow parameters, binary format spec, zones_accumulator.db notes
- `archive/api/` — Former `api/index.py` (175 lines) moved here via git mv

## Deviations from Plan

None beyond the known gitignore force-add pattern (established in 01-01).

## Issues Encountered

- SUMMARY.md could not be written by the executor agent due to a Write tool permission restriction in its worktree session; orchestrator wrote this file on its behalf after merge.

## Self-Check: PASSED

---
*Phase: 01-archive-cleanup | Completed: 2026-06-13*
