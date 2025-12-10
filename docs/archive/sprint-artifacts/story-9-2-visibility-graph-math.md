# Story 9.2: Universal Visibility Graph & Math Engine

**Epic**: 9 - Astronomy Engine & Data Integration
**Status**: done
**Priority**: High

## User Story
As a stargazer, I want a visual graph that shows me when a celestial object is visible and how the moon affects that visibility, so that I can plan the best time to observe. I also want this graph to be visually consistent with the app's themes (Blue for standard, Orange for highlights).

## Context
The "Universal Visibility Graph" is a core feature used in multiple places:
1.  **Celestial Detail Sheet**: Shows visibility for a specific object.
2.  **Highlights Feed**: Shows "Best View" times.
3.  **Atmospherics Sheet**: Shows Moon altitude and interference.

The graph needs to be highly performant (CustomPaint), interactive (scrubbing), and configurable (themes).

## Acceptance Criteria

### AC 1: Core Graph Rendering
- [x] **Object Curve**: Render altitude (0-90°) over a 12-hour window (Sunset to Sunrise or custom range).
- [x] **Moon Curve**: Render moon altitude/interference curve.
- [x] **Gradient**: Display a gradient under the curve for visual depth.
- [x] **Peak Indicator**: Mark the highest altitude point with a dot.

### AC 2: Interactive Elements
- [x] **Scrubber**: Allow user to drag/tap to see specific time and altitude.
- [x] **Now Indicator**: Show current time with a vertical line and "NOW" badge.
- [x] **Tooltip**: Show time and altitude details when scrubbing.

### AC 3: Configurable Themes
- [x] **Standard Theme (Blue)**: Default for Celestial Details and Moon page.
    - Blue Object Curve (`0xFF3B82F6`)
    - Blue Gradient & Peak Dot
    - Orange Highlights (SQM, Scrubber, Tooltip)
- [x] **Highlights Theme (Orange)**: Used for "Tonight's Highlights".
    - Orange Object Curve
    - Orange Gradient & Peak Dot
    - Orange Highlights (SQM, Scrubber, Tooltip)
- [x] **Parameterization**: `VisibilityGraphWidget` accepts a `highlightColor` parameter to control this.

### AC 4: Integration & Correctness
- [x] **Atmospherics Integration**: Moon graph renders correctly in `AtmosphericsSheet`.
- [x] **Leak Prevention**: Graph does not render outside its bounds (clamped to 0).
- [x] **Data Accuracy**: "Best View" and curve data match astronomy engine calculations.

## Technical Implementation Tasks

### Core Widget
- [x] Create `VisibilityGraphWidget` and `VisibilityGraphPainter`.
- [x] Implement `CustomPainter` logic for curves, gradients, and indicators.
- [x] Implement gesture handling for scrubbing.

### Theming Refactor
- [x] Add `highlightColor` parameter to `VisibilityGraphWidget`.
- [x] Update `VisibilityGraphPainter` to use `highlightColor` for:
    - Object Curve (if overridden)
    - Gradient
    - Peak Dot
    - Scrubber
    - SQM Badge Border/Background
- [x] Ensure default behavior preserves the "Blue Curve / Orange Highlights" look for standard objects.

### Bug Fixes & Polish
- [x] Fix Moon graph leak in `AtmosphericsSheet` (clamp negative values).
- [x] Replace deprecated `withOpacity` with `withValues`.
- [x] Verify "Best View" string and integration in `HighlightsFeed`.

## Dependencies
- `astronomy_engine` (for calculations)
- `VisibilityGraphNotifier` (state management)

## Senior Developer Review (AI)

### Reviewer: Vansh
### Date: 2025-12-01
### Outcome: Approve

### Summary
The implementation of the Universal Visibility Graph is robust, performant, and visually consistent with the design requirements. The configurable theming allows for distinct visual identities for "Highlights" (Orange) and standard views (Blue). The integration into `AtmosphericsSheet` and `HighlightsFeed` is correct.

### Key Findings
- **High Quality**: The use of `CustomPainter` ensures high performance for graph rendering.
- **Correct Theming**: The `highlightColor` parameter correctly propagates to all graph elements (curve, gradient, peak, SQM).
- **Leak Prevention**: `ConditionsGraph` correctly clamps moon altitude values to prevent rendering artifacts.

### Acceptance Criteria Coverage

| AC# | Description | Status | Evidence |
| :--- | :--- | :--- | :--- |
| AC 1 | Core Graph Rendering | IMPLEMENTED | `VisibilityGraphPainter.dart` (lines 222, 146, 48) |
| AC 2 | Interactive Elements | IMPLEMENTED | `VisibilityGraphWidget.dart` (lines 166-186), `VisibilityGraphPainter.dart` (lines 294, 260) |
| AC 3 | Configurable Themes | IMPLEMENTED | `VisibilityGraphWidget.dart` (lines 74, 19), `CelestialDetailSheet.dart` (line 91) |
| AC 4 | Integration & Correctness | IMPLEMENTED | `AtmosphericsSheet.dart`, `ConditionsGraph.dart` (lines 216, 237) |

**Summary**: 4 of 4 acceptance criteria fully implemented.

### Task Completion Validation

| Task | Marked As | Verified As | Evidence |
| :--- | :--- | :--- | :--- |
| Create `VisibilityGraphWidget` | [x] | VERIFIED | `VisibilityGraphWidget.dart` exists |
| Implement `CustomPainter` logic | [x] | VERIFIED | `VisibilityGraphPainter.dart` exists |
| Implement gesture handling | [x] | VERIFIED | `VisibilityGraphWidget.dart` (lines 166-186) |
| Add `highlightColor` parameter | [x] | VERIFIED | `VisibilityGraphWidget.dart` (line 19) |
| Update `VisibilityGraphPainter` | [x] | VERIFIED | `VisibilityGraphPainter.dart` uses `highlightColor` |
| Ensure default behavior | [x] | VERIFIED | Defaults to Blue (line 74) |
| Fix Moon graph leak | [x] | VERIFIED | `ConditionsGraph.dart` clamps values |
| Replace `withOpacity` | [x] | VERIFIED | Used `withValues` throughout |
| Verify "Best View" string | [x] | VERIFIED | `HighlightsFeed.dart` (line 123) |

**Summary**: 9 of 9 completed tasks verified.

### Action Items
**Advisory Notes:**
- Note: `ConditionsGraph` duplicates some logic from `VisibilityGraphPainter` (e.g., moon curve drawing). Consider refactoring to share a common painter or logic in the future to reduce code duplication.
