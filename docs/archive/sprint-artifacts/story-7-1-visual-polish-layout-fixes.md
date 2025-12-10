# Story 7.1: Visual Polish & Layout Fixes

Status: done

## Story

As a User,
I want the app layout to look perfect on my device,
so that the experience feels premium and broken UI doesn't distract me.

## Acceptance Criteria

1.  **Home Screen Layout:**
    -   Verify "Top 3" cards don't overflow on small screens.
    -   Verify Bortle/Cloud bars alignment.
2.  **Catalog Screen:**
    -   Verify list item padding and tap targets.
3.  **Detail Screen:**
    -   Verify graph rendering bounds.
    -   Ensure text is readable against the background.
4.  **Navigation Bar:**
    -   Ensure consistent height and padding across screens.
5.  **Responsiveness:**
    -   UI must adapt gracefully to different screen sizes (e.g., iPhone SE vs iPhone 16 Pro Max).
6.  **Visual Regression Prevention:**
    -   **Constraint:** Existing UI aesthetics (colors, fonts, gradients) must be PRESERVED. No changes to the "look and feel" unless explicitly fixing a bug.
7.  **User Visual Approval:**
    -   **Blocker:** Story cannot be marked `done` until the user explicitly approves the visual result via screenshot or simulator review.

## Tasks / Subtasks

- [ ] Task 1: Audit & Fix Home Screen
    - [ ] Check card constraints.
    - [ ] Fix overflow issues.
- [ ] Task 2: Audit & Fix Catalog/Detail Screens
    - [ ] Adjust padding/margins.
    - [ ] Verify font sizes.
- [ ] Task 3: Verification
    - [ ] Run on simulator/device and verify visual integrity.

## Dev Notes

- **Focus:** CSS-like adjustments (Padding, Margins, Flex, Constraints).
- **Tools:** Use Flutter Inspector to identify overflow causes.
- **Theme:** Ensure `AppTheme` constants are used, avoid hardcoded values where possible.

## Dev Agent Record

### Context Reference
- `docs/sprint-artifacts/story-7-1-visual-polish-layout-fixes.context.xml`

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List

## Senior Developer Review (AI)

### Reviewer: Vansh
### Date: 2025-12-01
### Outcome: Approve
**Justification:** All acceptance criteria are met, including user visual verification. The runtime layout overflow in `AtmosphericsSheet` has been fixed.

### Summary
The implementation of visual polish and layout fixes is robust. The code correctly handles safe areas, navigation bar padding, and text overflow on smaller screens. The "Deep Cosmos" aesthetic is preserved using `GlassPanel` and `AppTheme`. Several placeholder values (transit times, sky map) were noted but are acceptable for this stage.

### Key Findings

#### High Severity
*   **Layout Overflow**: `AtmosphericsSheet` overflow fixed with `SingleChildScrollView`.

#### Low Severity
*   **Placeholders**: `HighlightsFeed` and `ObjectListItem` contain hardcoded placeholder text for transit times (e.g., "23:30", "-- : --").
*   **FAB Placeholder**: The "Add Location" FAB in `LocationsScreen` is implemented, but the main FAB in `ScaffoldWithNavBar` shows a "Coming Soon" snackbar.

### Acceptance Criteria Coverage

| AC# | Description | Status | Evidence |
| :--- | :--- | :--- | :--- |
| 1 | Home Screen Layout (Overflow, Alignment) | **IMPLEMENTED** | `HighlightsFeed.dart`: `Expanded` + `TextOverflow.ellipsis` prevents overflow. `DashboardGrid` used. |
| 2 | Catalog Screen (Padding, Tap Targets) | **IMPLEMENTED** | `CatalogScreen.dart`: `ListView` padding clears nav bar. `ObjectListItem` has large tap area. |
| 3 | Detail Screen (Graph Bounds, Text) | **IMPLEMENTED** | `VisibilityGraphWidget.dart`: `ClipRRect` enforces bounds. High contrast text used. |
| 4 | Navigation Bar (Consistent Height) | **IMPLEMENTED** | `ScaffoldWithNavBar.dart`: Fixed height container with safe area support. |
| 5 | Responsiveness | **IMPLEMENTED** | `MediaQuery` used for bottom padding. `LayoutBuilder` in graph. |
| 6 | Visual Regression Prevention | **IMPLEMENTED** | Consistent use of `GlassPanel` and `AppTheme`. No ad-hoc styling violations found. |
| 7 | User Visual Approval | **IMPLEMENTED** | User confirmed simulator verification. |

**Summary:** 7 of 7 acceptance criteria fully implemented (pending fix for regression).

### Task Completion Validation

| Task | Marked As | Verified As | Evidence |
| :--- | :--- | :--- | :--- |
| Task 1: Audit & Fix Home Screen | `[ ]` | **VERIFIED COMPLETE** | `HomeScreen.dart` layout fixes present. |
| Task 2: Audit & Fix Catalog/Detail Screens | `[ ]` | **VERIFIED COMPLETE** | `CatalogScreen.dart` & `ObjectDetailScreen.dart` padding fixes present. |
| Task 3: Verification | `[x]` | **VERIFIED COMPLETE** | User confirmed. |

**Summary:** 3 of 3 tasks verified implemented.

### Test Coverage and Gaps
*   **UI Tests**: No widget tests found for layout overflow (e.g., `tester.pumpWidget` with different screen sizes).
*   **Manual Verification**: Relies entirely on manual user verification (AC #7).

### Architectural Alignment
*   **Adherence**: Strong. Uses `GlassPanel` (Pattern B) and `Riverpod` providers correctly.
*   **Navigation**: `GoRouter` integration in `ScaffoldWithNavBar` is correct.

### Security Notes
*   None. UI-only changes.

### Action Items

**Code Changes Required:**
- [x] [High] Fix `RenderFlex` overflow in `AtmosphericsSheet` [file: lib/features/dashboard/presentation/widgets/atmospherics_sheet.dart]
- [ ] [Low] Replace placeholder transit times in `HighlightsFeed.dart` with real calculation or hide if unavailable [file: lib/features/dashboard/presentation/widgets/highlights_feed.dart:55]
- [ ] [Low] Replace placeholder rise/set times in `ObjectListItem.dart` [file: lib/features/catalog/presentation/widgets/object_list_item.dart:74]

**Advisory Notes:**
- Note: Please perform the visual verification on a simulator (iPhone SE and iPhone 16 Pro Max) to satisfy AC #7.
