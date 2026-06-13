---
phase: 01-archive-cleanup
plan: "05"
subsystem: infra
tags: [archive, planner, theme, common, cleanup, dart]

# Dependency graph
requires: [01-04]
provides:
  - archive/planner/ with all former lib/features/planner/ and test/features/planner/ contents
  - archive/config-theme/ with all former lib/config/theme/ contents
  - archive/common/ with all dead lib/common/ widget files
  - Clean lib/ tree with zero error-level diagnostics
affects: [01-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Archive pattern: moved dead feature directories to archive/ with README.md"

key-files:
  created:
    - archive/planner/README.md
  deleted:
    - lib/features/planner/ (9 files — all moved to archive/planner/lib/)
    - test/features/planner/ (6 files — moved to archive/planner/tests/features/)
    - lib/config/theme/ (5 files — moved to archive/config-theme/)
    - lib/common/app_bar_gone.dart
    - lib/common/grid_item.dart
    - lib/common/link_card.dart

key-decisions:
  - "All 3 lib/common/ widgets confirmed dead via grep before archiving"
  - "lib/config/theme/ confirmed unreferenced after hive_adapters cleanup in 01-04"
  - "lib/features/planner/ confirmed unreferenced after forecast domain/presentation migration in 01-03/01-04"

requirements-completed: [ARCH-03, ARCH-05, ARCH-06]

# Metrics
duration: 15min
completed: "2026-06-13"
---

# Phase 1 Plan 05: Archive Dead Planner/Config/Common Summary

**lib/features/planner/, lib/config/theme/, and dead lib/common/ widgets archived; active lib/ tree contains only live code with zero analyzer errors**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-06-13
- **Tasks:** 2/2

## Accomplishments

- Task 1: Moved `lib/features/planner/` (9 files) to `archive/planner/lib/` and `test/features/planner/` (6 files) to `archive/planner/tests/features/`. Created `archive/planner/README.md`. Ran `flutter analyze lib/` — zero errors.
- Task 2: Moved `lib/config/theme/` (5 files: theme_logic.dart, theme_logic.g.dart, theme_ui_model.dart, theme_ui_model.freezed.dart, theme_ui_model.g.dart) to `archive/config-theme/`. Confirmed all 3 `lib/common/` widgets dead via grep and moved them to `archive/common/`. Removed empty `lib/common/` directory. Ran `flutter analyze lib/` — zero errors.

## Task Commits

1. **Task 1: Archive planner feature and tests** — `f66b9f8` (chore)
2. **Task 2: Archive config/theme and dead common widgets** — `de30001` (chore)

## Files Created/Modified

- `archive/planner/README.md` — Archive reference for dead planner feature
- `archive/planner/lib/` — 9 former lib/features/planner/ files
- `archive/planner/tests/features/` — 6 former test/features/planner/ files
- `archive/config-theme/` — 5 former lib/config/theme/ files
- `archive/common/` — 3 dead lib/common/ widget files

## Deviations from Plan

None.

## Self-Check: PASSED

`flutter analyze lib/` exits with zero error-level diagnostics after all moves.

---
*Phase: 01-archive-cleanup | Completed: 2026-06-13*
