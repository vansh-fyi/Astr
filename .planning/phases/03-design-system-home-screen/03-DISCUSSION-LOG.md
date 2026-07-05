# Phase 3: Design System + Home Screen - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-04
**Phase:** 3-Design System + Home Screen
**Areas discussed:** Illustrated backgrounds, Home screen rebuild strategy, Design token structure, Navigation bar scope

---

## Illustrated Backgrounds

| Option | Description | Selected |
|--------|-------------|----------|
| Static PNG/SVG exports | One image per sky state. Simple Image.asset(). No animation. | ✓ |
| Rive animations | Animated, GPU-accelerated .riv files. Cinematic but requires Rive editor. | |
| Lottie animations | JSON-based animations. Lighter than Rive but requires animation files. | |

**User's choice:** Static JPG assets

**Notes:** All 6 assets are already present in `assets/img/`: `milkyway.jpg`, `starry_sky.jpg`, `planets.jpg`, `few_stars.jpg`, `cloudy.jpg`, `excessive_light_pollution.jpg`. Background implementation is a full replacement — `nebula_background.dart` and `sky_portal.dart` are deleted in favor of a new full-bleed image fill with dark gradient overlay per Figma.

---

## Home Screen Rebuild Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Clean rewrite from Figma spec | Delete home_screen.dart and all old widgets; build fresh. | |
| In-place refactor | Keep home_screen.dart structure, preserve provider wiring and state logic, reshape widget tree. | ✓ |

**User's choice:** In-place refactor

**Widget strategy follow-up:**

| Option | Description | Selected |
|--------|-------------|----------|
| Keep useful, replace visual-specific | Refactor logic-heavy widgets, replace layout/visual ones. | |
| Keep all, refactor each individually | No deletions — every widget gets refactored to match Figma. | ✓ |
| You decide based on Figma spec | Executor decides per widget. | |

**Notes:** All existing widgets refactored individually. Design reference: user will export Figma frames as images and place them in `figma/home/` before execution starts. Executor works from those images + REQUIREMENTS.md HOME-01 through HOME-09.

---

## Design Token Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Extend AppTheme in lib/app/theme/app_theme.dart | Add token fields to existing class. | |
| New separate file(s) in lib/app/theme/ | app_colors.dart, app_typography.dart, etc. | |
| New lib/core/design/ directory | Design system gets its own top-level directory under core/. | ✓ |

**User's choice:** New `lib/core/design/` directory

**DS-02 enforcement follow-up:**

| Option | Description | Selected |
|--------|-------------|----------|
| Tokens apply to home screen only | Other surfaces migrated per phase as they're redesigned. | |
| Global token migration now | All 15 surfaces have hardcoded values replaced with tokens in Phase 3. | ✓ |

**bortleClass rename follow-up:**

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — rename in Phase 3 | ZoneData.bortleClass → ZoneData.astrZone + all references. | ✓ |
| No — defer further | Leave as naming debt for later. | |

**Notes:** Phase 3 is the right time to rename since the home screen UI reads and displays the zone value. Must verify JSON key compatibility with Cloudflare Worker response before renaming Dart field.

---

## Navigation Bar Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Redesign nav bar visually + add 5th tab/FAB structure | Restyle with tokens, add FAB placeholder if not present. | ✓ |
| Restyle only — keep 4-tab structure | Map FAB deferred. | |
| Leave nav bar untouched | No nav changes in Phase 3. | |

**User's choice:** Redesign nav bar visually + add 5th tab/FAB structure

**Notes:** The nav bar is already fully built with the correct structure — centered map FAB already present with "Sky Map coming soon!" toast, custom `NavBarClipper` notch, `NotchShinePainter` shine effect. No structural additions needed — Phase 3 only restyled with design tokens.

**Header placement follow-up:**

| Option | Description | Selected |
|--------|-------------|----------|
| Keep as global header — visible on all tabs | Location pill and date nav stay in ScaffoldWithNavBar. | ✓ |
| Move to home screen only | Other tabs get simpler header. | |

**Notes:** Global header confirmed as correct. User also clarified that Figma design images will be placed in `figma/home/` (folder already exists at repo root).

---

## Claude's Discretion

None — user made all decisions directly.

## Deferred Ideas

None — discussion stayed within phase scope.
