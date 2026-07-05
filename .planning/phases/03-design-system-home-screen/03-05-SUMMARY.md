---
phase: 03-design-system-home-screen
plan: 05
subsystem: ui
tags: [flutter, navigation, styling, tokens]

# Dependency graph
requires:
  - plan: 03-01A
    provides: [AppColors, AppTypography, AppSpacing]
provides:
  - HighlightsFeed widget styling update
  - ScaffoldWithNavBar token-based migration
  - GlassPanel custom background/border support
affects: [design-system-home-screen]

# Tech tracking
tech-stack:
  added: []
  patterns: [GlassPanel parameterization, Glow shadow navigation labels]

key-files:
  modified:
    - lib/features/dashboard/presentation/widgets/highlights_feed.dart
    - lib/app/router/scaffold_with_nav_bar.dart
    - lib/core/widgets/glass_panel.dart
    - test/features/dashboard/presentation/widgets/highlights_feed_test.dart

key-decisions:
  - "Updated highlights list item rows to use DecoratedBox and InkWell container matching the cardRadius token to align item outlines and resolve container widget lints."
  - "Configured active navigation bar labels with a dual-glow shadow effect verbatim to Figma node 119:92, and updated inactive labels to use AppColors.textSubdued."
  - "Parameterised GlassPanel to accept optional backgroundColor and borderColor parameters while preserving default values for existing codebase consumers."

patterns-established:
  - "Alphabetical sorting of design-specific utility and layout imports."

requirements-completed:
  - HOME-07
  - HOME-08
  - DS-02

# Metrics
duration: 20min
completed: 2026-07-05
---

# Phase 3 Plan 05: HighlightsFeed and ScaffoldWithNavBar Styling Summary

**Redesigned HighlightsFeed items and migrated ScaffoldWithNavBar styling and glow details to design system tokens.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-07-05T17:49:00Z
- **Completed:** 2026-07-05T17:52:00Z
- **Tasks:** 2
- **Files modified/created:** 4

## Accomplishments
- Restyled `HighlightsFeed` header to use `AppTypography.micro` and `AppColors.textMuted` tokens.
- Replaced `GlassPanel(enableBlur: false)` with token-parameterized `DecoratedBox` + `InkWell` layout for each highlight row item.
- Replaced 14 hardcoded color values in `scaffold_with_nav_bar.dart` with token parameters, ensuring no `Colors.blueAccent` or legacy `AppTheme` references remain.
- Implemented blue and white double-shadow glow effect on the active tab label and converted inactive items to use `AppColors.textSubdued`.
- Parameterized `GlassPanel` constructor, adding optional `backgroundColor` and `borderColor` fields.
- Fixed unit test expectations in `highlights_feed_test.dart` to check for `InkWell` and cleared all static analysis warnings.

## Task Commits

1. **Task 1 & 2: Restyle HighlightsFeed, ScaffoldWithNavBar and update GlassPanel** - `1e88061` (feat)

## Next Phase Readiness
- Both Wave 2 (`03-05-PLAN.md`) and Wave 3 (`03-02-PLAN.md`) are successfully implemented, verified, and committed.
