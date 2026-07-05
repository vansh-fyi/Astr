# Phase 1: Archive & Cleanup - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 1-Archive & Cleanup
**Areas discussed:** Lib dead-code depth, Pipeline docs depth, scripts/ fate, Root-level artifact files

---

## Lib Dead-Code Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Confirmed-dead only | Archive backend/, api/, planner/, duplicate forecast screen only | |
| Full lib/ audit | Walk every lib/features/* module for stale providers, dead screens, orphaned code | ✓ |
| Confirmed-dead + quick scan | Archive known items + grep-based scan for obvious dead code | |

**User's choice:** Full lib/ audit

---

### Dead Code Classification Bar

| Option | Description | Selected |
|--------|-------------|----------|
| Unreachable = archive it | Any screen/provider not reachable from GoRouter goes to archive | |
| Unused + no future plan = archive it | Archive only if unreachable AND not planned for a future phase | ✓ |
| Flag, don't archive | Add TODOs to borderline code; let future phases decide | |

**User's choice:** Unused + no future plan = archive it

---

### Dangling Import Handling

| Option | Description | Selected |
|--------|-------------|----------|
| Remove all dangling refs | After each move, scan and remove all dangling imports, dead routes, orphaned provider registrations | ✓ |
| Remove only if compile breaks | Only fix what dart analyze flags as an error | |
| Leave to researcher/planner | Defer this decision | |

**User's choice:** Remove all dangling refs (Recommended)

---

## Pipeline Docs Depth

| Option | Description | Selected |
|--------|-------------|----------|
| README per subfolder | Brief README explaining what each script does, inputs/outputs, why archived | |
| Full reproduction guide | Step-by-step: environment setup, data sources, exact commands, expected outputs, diffusion tuning | ✓ |
| Code comments only | Header comments on each script; no separate doc | |

**User's choice:** Full reproduction guide (Recommended)

---

## scripts/ Fate

| Option | Description | Selected |
|--------|-------------|----------|
| Split: pipeline to archive, validators stay | Generation scripts to archive/data-pipeline/; validation scripts stay in scripts/ | |
| All of scripts/ to archive | Move everything to archive/data-pipeline/ | |
| All of scripts/ stays | Don't touch scripts/ in Phase 1; Phase 2 decides | ✓ |

**User's choice:** All of scripts/ stays
**Notes:** scripts/ contains both pipeline scripts AND validation scripts needed for Phase 2 (Zone Data Validation). Leaving it untouched ensures Phase 2 has immediate access.

---

## Root-Level Artifact Files

### zones_accumulator.db (1.3GB)

| Option | Description | Selected |
|--------|-------------|----------|
| Add to .gitignore, keep locally | Don't commit, add to .gitignore, document location and regeneration steps in archive/data-pipeline/ | ✓ |
| Archive/document only | .gitignore it and note its location; Phase 2 decides whether to regenerate | |
| Delete it | Can be regenerated from pipeline scripts | |

**User's choice:** Add to .gitignore, keep locally (Recommended)

### test_failures.log, GetStorage.bak, GetStorage.gs

| Option | Description | Selected |
|--------|-------------|----------|
| Delete + add to .gitignore | Delete all three files and add patterns to .gitignore | ✓ |
| .gitignore only | Add to .gitignore but leave files on disk | |
| Delete only | Delete the files; don't update .gitignore | |

**User's choice:** Delete + add to .gitignore

---

## Claude's Discretion

None — all areas had explicit user decisions.

## Deferred Ideas

None — discussion stayed within phase scope.
