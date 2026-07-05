---
phase: 3
slug: design-system-home-screen
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-05
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (SDK built-in) + widget tests |
| **Config file** | `analysis_options.yaml` |
| **Quick run command** | `flutter test test/` |
| **Full suite command** | `flutter test --coverage` |
| **Estimated runtime** | ~30–60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/`
- **After every plan wave:** Run `flutter test --coverage`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | DS-01 | — | N/A | unit | `flutter test test/` | ❌ W0 | ⬜ pending |
| 03-01-02 | 01 | 1 | DS-02 | — | N/A | unit | `flutter test test/` | ❌ W0 | ⬜ pending |
| 03-01-03 | 01 | 1 | DS-03 | — | N/A | widget | `flutter test test/` | ❌ W0 | ⬜ pending |
| 03-02-01 | 02 | 2 | HOME-01 | — | N/A | widget | `flutter test test/` | ❌ W0 | ⬜ pending |
| 03-02-02 | 02 | 2 | HOME-02 | — | N/A | widget | `flutter test test/` | ❌ W0 | ⬜ pending |
| 03-02-03 | 02 | 2 | HOME-03 | — | N/A | manual | Visual inspection | — | ⬜ pending |
| 03-03-01 | 03 | 3 | HOME-04 | — | N/A | widget | `flutter test test/` | ❌ W0 | ⬜ pending |
| 03-03-02 | 03 | 3 | HOME-05 | — | N/A | widget | `flutter test test/` | ❌ W0 | ⬜ pending |
| 03-03-03 | 03 | 3 | HOME-06 | — | N/A | widget | `flutter test test/` | ❌ W0 | ⬜ pending |
| 03-04-01 | 04 | 4 | HOME-07 | — | N/A | widget | `flutter test test/` | ❌ W0 | ⬜ pending |
| 03-04-02 | 04 | 4 | HOME-08 | — | N/A | widget | `flutter test test/` | ❌ W0 | ⬜ pending |
| 03-04-03 | 04 | 4 | HOME-09 | — | N/A | manual | Visual inspection | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/features/dashboard/presentation/widgets/home_screen_test.dart` — stubs for HOME-01 through HOME-09
- [ ] `test/core/design_system/tokens_test.dart` — stubs for DS-01, DS-02, DS-03
- [ ] `test/features/dashboard/domain/sky_state_test.dart` — stubs for SkyState enum + mapping logic

*Existing flutter_test infrastructure available; Wave 0 creates new test files for phase-specific widgets and domain logic.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Illustrated backgrounds visually match sky state | HOME-01 | Pixel-level visual correctness requires human judgment | Run app on device/emulator, cycle through 6 sky states, confirm correct image per state |
| Glassmorphism blur on cards looks correct | HOME-04 | Visual blur quality not automatable | Run app, confirm 2px blur on ConditionsCard, VisibilityMiniCard, MoonMiniCard |
| Dark-theme starfield aesthetic consistent | HOME-09 | Visual consistency requires subjective review | Full home screen review on dark device |
| Date navigation arrows advance correctly | HOME-03 | Navigation behavior requires running app | Tap `<` / `>`, confirm date changes and data refreshes |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
