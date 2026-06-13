---
phase: 01-archive-cleanup
plan: "01"
subsystem: infra
tags: [gitignore, archive, backend, mongodb, flask, cleanup]

# Dependency graph
requires: []
provides:
  - archive/backend/ directory with all former backend/ contents and README
  - .gitignore with correct zones_accumulator.db, test_failures*.log, GetStorage.bak/gs patterns
  - gitignore exceptions for archive documentation (INDEX.md, **/README.md)
  - Deleted root junk files (test_failures*.log x6, test_output*.txt x7, GetStorage.bak, GetStorage.gs)
affects: [01-02, 01-03, 01-04, 01-05, 01-06, 02-zone-validation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Archive pattern: dead backends moved to archive/ with README explaining what/why/what-replaced"
    - "Gitignore exception pattern: archive/ ignored globally, force-add required for docs inside ignored parent"

key-files:
  created:
    - archive/backend/README.md
  modified:
    - .gitignore

key-decisions:
  - "Force-add archive/backend/README.md to git because gitignore negation cannot un-ignore files inside a parent-ignored directory per git rules"
  - "Delete junk files from main working tree (they were untracked, not committed), gitignore patterns prevent re-addition"
  - "Keep zones_accumulator.db on disk (needed for Phase 2 zone validation) — only gitignore it, do not delete"

patterns-established:
  - "Archive README pattern: each archive/ subfolder gets a README.md with What/Why Archived/What Replaced sections"

requirements-completed: [ARCH-01, ARCH-02]

# Metrics
duration: 6min
completed: "2026-06-13"
---

# Phase 1 Plan 01: .gitignore Fix and Backend Archive Summary

**MongoDB/Flask backend moved to archive/backend/ with README; .gitignore corrected with zones_accumulator.db, test_failures*.log, GetStorage patterns, and archive documentation exceptions**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-06-13T09:57:00Z
- **Completed:** 2026-06-13T10:03:38Z
- **Tasks:** 2
- **Files modified:** 2 (1 modified .gitignore, 1 created README.md) + 12 backend files renamed

## Accomplishments

- Fixed .gitignore with 4 missing patterns (zones_accumulator.db correct spelling, test_failures*.log, GetStorage.bak, GetStorage.gs) plus archive documentation exceptions
- Deleted 15 junk root files (6 test_failures*.log, 7 test_output*.txt, GetStorage.bak, GetStorage.gs) from working tree
- Moved entire backend/ (MongoDB/Flask API, 12 tracked files) to archive/backend/ using git mv preserving rename history
- Created archive/backend/README.md documenting: Flask 3.0.0 + pymongo 4.6.0 stack, why archived (replaced by Cloudflare + Open-Meteo), what replaced it, credential note

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix .gitignore patterns and delete junk root files** - `63885ad` (chore)
2. **Task 2: Move backend/ to archive/backend/ and write archive README** - `b6a95f5` (chore)

**Plan metadata:** skipped (commit_docs: false)

## Files Created/Modified

- `archive/backend/README.md` — Archive reference for MongoDB/Flask backend; documents what it was, why archived (Phase 1, 2026-06-13), what replaced it (Cloudflare Worker + Open-Meteo)
- `.gitignore` — Added zones_accumulator.db, zone_accumulator.db (old spelling kept), test_failures*.log, GetStorage.bak, GetStorage.gs; added !archive/INDEX.md and !archive/**/README.md exceptions
- `archive/backend/**` (12 files renamed from backend/) — All tracked backend files now at archive path, git history preserved as renames

## Decisions Made

- Used `git mv` for backend/ move to preserve rename history (git tracks as R, not D+A)
- Used `git add -f` for archive/backend/README.md because git cannot un-ignore files inside a parent-ignored directory via negation patterns; force-add is the practical mechanism
- Deleted junk files from main repo working tree (they were untracked there); gitignore patterns in worktree branch prevent any future accidental commit

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Gitignore exception pattern requires force-add for README.md**
- **Found during:** Task 2 (archive README creation)
- **Issue:** The `!archive/**/README.md` exception in .gitignore cannot un-ignore files inside an already-ignored parent directory (`archive/`). `git check-ignore` confirmed README.md was still ignored after adding the exception.
- **Fix:** Used `git add -f archive/backend/README.md` to force-track the file. The gitignore exception rules are kept in .gitignore for intent documentation.
- **Files modified:** No additional files; git index updated
- **Verification:** `git ls-files archive/backend/README.md` returns the file path (confirmed tracked)
- **Committed in:** b6a95f5 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Force-add is the correct git mechanism for this pattern. No scope creep.

## Issues Encountered

- Junk files (test_failures*.log etc.) do not appear in the worktree because they are untracked files that only exist in the main working tree. Deleted them from the main repo path. The gitignore patterns in the worktree branch prevent any future accidental commits.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- archive/backend/ is ready; Plan 02 (archive/api/) can reference this pattern
- zones_accumulator.db is gitignored and preserved on disk for Phase 2 zone validation
- .gitignore is correct for all known junk file patterns

---
*Phase: 01-archive-cleanup*
*Completed: 2026-06-13*
