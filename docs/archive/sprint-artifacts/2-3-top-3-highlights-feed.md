# User Story: 2.3 Top 3 Highlights Feed

> **Epic:** 2 - The Dashboard ("Is Tonight Good?")
> **Story ID:** 2.3
> **Story Title:** Top 3 Highlights Feed
> **Status:** review
> **Priority:** High
> **Estimation:** 3 Points

## 1. Story Statement
**As a** User,
**I want** to see the top 3 best objects to look at tonight,
**So that** I have an immediate goal.

## 2. Context & Requirements
This story focuses on giving the user immediate, actionable targets. Instead of overwhelming them with a full catalog, we filter the visible objects to find the "Best" 3. "Best" is defined by visibility (Altitude) and brightness (Magnitude), prioritizing Planets over Stars for the MVP.

### Requirements Source
*   **Epics:** Story 2.3.
*   **PRD:** FR9 (Highlights).

## 3. Acceptance Criteria

| AC ID | Criteria | Verification Method |
| :--- | :--- | :--- |
| **AC-2.3.1** | **Filtering Logic:** System filters celestial objects to find those currently visible (Altitude > 0, or > 10 degrees for better viewing). | Unit Test. |
| **AC-2.3.2** | **Ranking Logic:** Sorts visible objects by Priority (Planets > Stars) and Brightness (Magnitude). | Unit Test. |
| **AC-2.3.3** | **Selection:** Selects the top 3 unique objects. | Unit Test. |
| **AC-2.3.4** | **UI Display:** Displays the top 3 objects as cards on the Home screen (e.g., horizontal list or grid). | Visual Inspection. |
| **AC-2.3.5** | **Card Content:** Each card shows Icon, Name, and a brief status (e.g., "Visible Now"). | Visual Inspection. |
| **AC-2.3.6** | **Interaction:** Tapping a card is a placeholder action (no detail page yet). | Manual Test. |

## 4. Technical Tasks

### 4.1 Domain Logic
- [x] Define `CelestialObject` entity (if not already robust enough from Story 1.2).
- [x] Implement `HighlightsLogic` class (or `HighlightsService`).
    - **Logic:**
        1. Get all objects (Sun, Moon, Planets, major Stars).
        2. Calculate current Altitude/Azimuth for each using `IAstroEngine`.
        3. Filter: Altitude > 10 degrees.
        4. Sort:
            - Primary: Type (Planet > Star).
            - Secondary: Magnitude (Lower is brighter).
        5. Take Top 3.
- [x] Write Unit Tests for `HighlightsLogic`.

### 4.2 Presentation
- [x] Create `HighlightCard` widget.
    - Use `GlassPanel` style.
    - Show Icon (asset or Flutter icon), Name, "Visible" tag.
- [x] Create `HighlightsFeed` widget (Horizontal ListView or Row).
- [x] Integrate `HighlightsFeed` into `HomeScreen` (below the Summary).
- [x] Connect to `AstronomyNotifier` (or create `HighlightsNotifier` if complex).

### 4.3 Testing
- [x] Widget Test: `HighlightCard` renders correctly.
- [x] Widget Test: `HighlightsFeed` displays 3 items.

## 5. Dev Notes
*   **Data Source:** We need a list of "Tracked Objects". Story 1.2 implemented the Engine, but maybe not a full Catalog.
    *   *Check:* Does `IAstroEngine` support "Get All Planets"?
    *   *If not:* We might need to define a static list of `CelestialBody` enums (Mercury, Venus, Mars, Jupiter, Saturn, Moon) to iterate over.
*   **Icons:** Use generic icons for now (Planet, Star, Moon) if specific assets aren't available.
*   **Performance:** Calculation should be fast, but ensure it doesn't block UI. `IAstroEngine` is synchronous (C bindings usually fast), but consider `compute` if checking hundreds of stars (unlikely for MVP).

### Learnings from Previous Story
**From Story 2.2-good-bad-summary-logic (Status: done)**
- **Domain Logic:** `StargazingLogic` was successfully isolated. Follow this pattern for `HighlightsLogic`.
- **UI:** `GlassPanel` and `SummaryText` worked well. `HighlightCard` should match the aesthetic.
- **State:** `AstronomyNotifier` already provides `AstronomyState`. We might need to expand `AstronomyState` to include "Visible Objects" or create a separate provider.
- **Testing:** Unit testing the logic covers most edge cases.

## 6. Dev Agent Record
*   **Context Reference:** `docs/sprint-artifacts/2-3-top-3-highlights-feed.context.xml`
*   **Completion Notes:**
    *   Implemented `HighlightItem` entity and `HighlightsLogic` domain class.
    *   Updated `AstronomyState` to include `List<CelestialPosition>` and `AstronomyNotifier` to calculate positions for all bodies.
    *   Created `HighlightCard` and `HighlightsFeed` widgets.
    *   Integrated feed into `HomeScreen`.
    *   Added comprehensive unit and widget tests.
*   **File List:**
    *   `lib/features/dashboard/domain/entities/highlight_item.dart`
    *   `lib/features/dashboard/domain/logic/highlights_logic.dart`
    *   `lib/features/dashboard/presentation/widgets/highlight_card.dart`
    *   `lib/features/dashboard/presentation/widgets/highlights_feed.dart`
    *   `lib/features/astronomy/domain/entities/astronomy_state.dart`
    *   `lib/features/astronomy/presentation/providers/astronomy_provider.dart`
    *   `lib/features/dashboard/presentation/home_screen.dart`
    *   `test/features/dashboard/domain/logic/highlights_logic_test.dart`
    *   `test/features/dashboard/presentation/widgets/highlight_card_test.dart`
    *   `test/features/dashboard/presentation/widgets/highlights_feed_test.dart`

## 7. Change Log
*   2025-11-29: Story drafted by Vansh (AI Agent).
*   2025-11-29: Implementation completed by Amelia (Dev Agent).

## 7. Senior Developer Review (AI)

### Reviewer: Amelia (Dev Agent)
### Date: 2025-11-29
### Outcome: Approve

**Summary:**
The implementation successfully delivers the Top 3 Highlights Feed. The domain logic correctly filters and ranks celestial objects based on visibility and magnitude. The integration with `AstronomyNotifier` ensures data is available for the UI. The UI components (`HighlightCard`, `HighlightsFeed`) match the design aesthetic.

### Key Findings
*   **High:** None.
*   **Medium:** None.
*   **Low:** None.

### Acceptance Criteria Coverage

| AC ID | Description | Status | Evidence |
| :--- | :--- | :--- | :--- |
| **AC-2.3.1** | Filtering Logic (Alt > 10) | **IMPLEMENTED** | `lib/features/dashboard/domain/logic/highlights_logic.dart` |
| **AC-2.3.2** | Ranking Logic (Mag) | **IMPLEMENTED** | `lib/features/dashboard/domain/logic/highlights_logic.dart` |
| **AC-2.3.3** | Top 3 Selection | **IMPLEMENTED** | `lib/features/dashboard/domain/logic/highlights_logic.dart` |
| **AC-2.3.4** | UI Display (Feed) | **IMPLEMENTED** | `lib/features/dashboard/presentation/widgets/highlights_feed.dart` |
| **AC-2.3.5** | Card Content | **IMPLEMENTED** | `lib/features/dashboard/presentation/widgets/highlight_card.dart` |
| **AC-2.3.6** | Interaction (Placeholder) | **IMPLEMENTED** | `lib/features/dashboard/presentation/widgets/highlights_feed.dart` (onTap placeholder) |

**Summary:** 6 of 6 acceptance criteria fully implemented.

### Task Completion Validation

| Task | Marked As | Verified As | Evidence |
| :--- | :--- | :--- | :--- |
| Define CelestialObject entity | [x] | **VERIFIED** | `lib/features/astronomy/domain/entities/celestial_body.dart` (Existing) |
| Implement HighlightsLogic | [x] | **VERIFIED** | `lib/features/dashboard/domain/logic/highlights_logic.dart` |
| Write Unit Tests | [x] | **VERIFIED** | `test/features/dashboard/domain/logic/highlights_logic_test.dart` |
| Create HighlightCard widget | [x] | **VERIFIED** | `lib/features/dashboard/presentation/widgets/highlight_card.dart` |
| Create HighlightsFeed widget | [x] | **VERIFIED** | `lib/features/dashboard/presentation/widgets/highlights_feed.dart` |
| Integrate into HomeScreen | [x] | **VERIFIED** | `lib/features/dashboard/presentation/home_screen.dart` |
| Connect to AstronomyNotifier | [x] | **VERIFIED** | `lib/features/astronomy/presentation/providers/astronomy_provider.dart` |
| Widget Test: Card | [x] | **VERIFIED** | `test/features/dashboard/presentation/widgets/highlight_card_test.dart` |
| Widget Test: Feed | [x] | **VERIFIED** | `test/features/dashboard/presentation/widgets/highlights_feed_test.dart` |

**Summary:** 9 of 9 completed tasks verified.

### Test Coverage and Gaps
*   Unit tests cover the sorting and filtering logic.
*   Widget tests cover the rendering of the card and feed.
*   **Gap:** No integration test verifying the `AstronomyNotifier` correctly feeds data to the UI, but unit/widget tests cover the components separately.

### Architectural Alignment
*   **Domain Logic:** Logic isolated in `HighlightsLogic` (Domain Layer).
*   **State Management:** `AstronomyNotifier` used effectively.
*   **UI:** `GlassPanel` used for consistency.

### Action Items
**Advisory Notes:**
- Note: Currently using `CelestialBody.values` which is a limited set. Future updates might need a larger catalog (Epic 3).
