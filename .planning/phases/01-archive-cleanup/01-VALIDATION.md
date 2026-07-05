---
phase: 1
slug: archive-cleanup
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-13
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter analyze (static analysis) |
| **Config file** | `analysis_options.yaml` |
| **Quick run command** | `flutter analyze lib/` |
| **Full suite command** | `flutter analyze && flutter test` |
| **Estimated runtime** | ~15 seconds (analyze) / ~60 seconds (analyze + test) |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze lib/`
- **After every plan wave:** Run `flutter analyze && flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 1-xx-xx | TBD | 1 | ARCH-01 | — | N/A | analyze | `flutter analyze lib/` | ✅ | ⬜ pending |
| 1-xx-xx | TBD | 1 | ARCH-02 | — | N/A | analyze | `flutter analyze lib/` | ✅ | ⬜ pending |
| 1-xx-xx | TBD | 1 | ARCH-03 | — | N/A | analyze | `flutter analyze lib/` | ✅ | ⬜ pending |
| 1-xx-xx | TBD | 1 | ARCH-04 | — | N/A | manual | Check `archive/data-pipeline/README.md` | ❌ W0 | ⬜ pending |
| 1-xx-xx | TBD | 1 | ARCH-05 | — | N/A | analyze | `flutter analyze lib/` | ✅ | ⬜ pending |
| 1-xx-xx | TBD | 1 | ARCH-06 | — | N/A | manual | Check `archive/INDEX.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `archive/INDEX.md` — new file documenting all archived subfolders (ARCH-06)
- [ ] `archive/data-pipeline/README.md` — full reproduction guide for zone pipeline (ARCH-04)

*Note: This phase creates new archive documentation files — they do not exist yet and must be created during execution.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `archive/INDEX.md` describes each subfolder (what, why, replacement) | ARCH-06 | Documentation quality cannot be machine-verified | Read `archive/INDEX.md`; confirm each subfolder has: what it contained, why archived, what replaced it |
| `archive/data-pipeline/README.md` covers full reproduction guide | ARCH-04 | Documentation completeness is human-evaluated | Read README; verify: environment setup, data sources (VNL NPP 2024 TIF), exact commands, intermediate outputs, skyglow params, final SQLite schema + R2 upload |
| No dangling imports to archived code remain | ARCH-05 | `flutter analyze` catches compile errors; semantic dead refs may need grep | Run `grep -r "planner\|backend\|api/index" lib/` after archiving |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
