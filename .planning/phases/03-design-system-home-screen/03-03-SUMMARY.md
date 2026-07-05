---
phase: 03-design-system-home-screen
plan: 03
subsystem: ui
tags: [flutter, conditions, cloud-bar, dashboard]

# Dependency graph
requires:
  - plan: 03-02
    provides: [SkyStateBackground, HomeScreen Stack layout]
provides:
  - ConditionsCard widget implementation
  - CloudBar token restyle
  - HomeScreen ConditionsCard wiring
affects: [design-system-home-screen]

# Tech tracking
tech-stack:
  added: []
  patterns: [Glassmorphism 2px blur card layout, Stack-based relative card dimensions]

key-files:
  created:
    - lib/features/dashboard/presentation/widgets/conditions_card.dart
    - test/features/dashboard/presentation/widgets/conditions_card_test.dart
  modified:
    - lib/features/dashboard/presentation/widgets/cloud_bar.dart
    - lib/features/dashboard/presentation/home_screen.dart

key-decisions:
  - "Implemented a custom 2px BackdropFilter blur inside ConditionsCard instead of using GlassPanel to conform to the Figma home screen spec."
  - "Preserved leading spaces on the Title (' Clear Skies') and Subtitle ('  Perfect visibility for observation') strings to enforce typographic alignment specs."
  - "Replaced CloudBar's inner GlassPanel wrapper with a DecoratedBox using surfaceGlass and borderSubtle tokens, and converted track and progress fill dimensions to AppSpacing scale values."

patterns-established:
  - "Custom Glassmorphism container layouts with low-sigma blurs (sigma=2) for card overlays."

requirements-completed:
  - HOME-04
  - HOME-09

# Metrics
duration: 25min
completed: 2026-07-05
---

# Phase 3 Plan 03: ConditionsCard Summary

**Delivered the Conditions Card component, restyled the Cloud Cover progress bar, and integrated them directly into the Home Screen layout.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-07-05T17:53:00Z
- **Completed:** 2026-07-05T17:56:00Z
- **Tasks:** 2
- **Files modified/created:** 4

## Accomplishments
- Created `ConditionsCard` as a responsive `ConsumerWidget` that fetches weather and object rise/set detail data directly.
- Designed a custom Glassmorphism style inside `ConditionsCard` using `ImageFilter.blur(sigmaX: 2, sigmaY: 2)` and exact design tokens.
- Structured sun and moon rise/set cells as inline `_TimeCell` blocks with exact absolute positions (`top: 12`, `top: 31`, `height: 64`) to match spacing requirements.
- Restyled `CloudBar` to align with the new design system, converting it from a full-page dialog overlay to a self-contained card element with a solid fill and a subtle glow shadow.
- Replaced the temporary `kConditionsCardHeight` placeholder `SizedBox` in `home_screen.dart` with the live `ConditionsCard` component.
- Implemented unit tests for the card and confirmed all dashboard page, widget, and provider test suites pass successfully.

## Task Commits

1. **Task 1 & 2: implement ConditionsCard, restyle CloudBar and wire into HomeScreen** - `3bb1e9c` (feat)

## Next Phase Readiness
- Plan 03 is complete. The next plan is `03-04-PLAN.md` (Mini-cards row styling: Bortle/Visibility card & Moon card).
