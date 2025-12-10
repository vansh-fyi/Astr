# Story 4.1: 7-Day Forecast List

Status: review

## Story

As a User,
I want to see a list of the next 7 days with summary conditions,
so that I can pick the best night.

## Acceptance Criteria

1. **7-Day Forecast List:**
   - [ ] Displays 7 days starting from "Today".
   - [ ] Each item shows: Date, Weather Icon, Cloud Cover %, Star Rating (1-5).
   - [ ] Star Rating logic considers: Cloud Cover, Moon Phase, and **Light Pollution (Bortle Scale)**.

## Tasks / Subtasks

- [x] Task 1: Data Layer & Logic (AC: 1)
  - [x] Implement `PlannerRepository` to fetch 7-day forecast from Open-Meteo.
  - [x] **Refactor:** Update `PlannerLogic` to include Bortle Scale in calculation.
  - [x] Implement `PlannerLogic` (or `StarRatingService`) to calculate 1-5 rating based on Cloud Cover and Moon Phase.
  - [x] **Test:** Update unit tests for new logic.
  - [x] Unit Test: Verify rating logic with various weather/moon combinations.
  - [x] Unit Test: Verify API response parsing.

- [x] Task 2: UI Implementation (AC: 1)
  - [x] Create `ForecastScreen` (or `PlannerScreen`) in `features/planner`.
  - [x] Implement `ForecastListItem` widget using `GlassPanel`.
  - [x] Integrate `WeatherRepository` (or `PlannerRepository`) provider.
  - [x] Widget Test: Verify list renders 7 items and displays correct data.

### Review Follow-ups (AI)
- [ ] [AI-Review][Low] Move `_getWeatherIcon` logic to a shared utility class for better reusability. (AC #2)

## Dev Notes

- **Architecture:**
  - **Module:** `features/planner`
  - **Pattern:** Clean Architecture (Data/Domain/Presentation).
  - **State Management:** Riverpod.
  - **UI:** Use `GlassPanel` for consistency.

- **Learnings from Previous Story:**
  - [Source: docs/sprint-artifacts/story-4-2-future-date-context-switching.md]
  - **Context:** `AstrContext` is the source of truth for Date/Location.
  - **Data:** `WeatherRepository` is already set up; `PlannerRepository` might share logic or be a separate provider.
  - **UI:** `GlassPanel` is the standard container.

### Project Structure Notes

- `features/planner` already exists (verified).
- Ensure `PlannerRepository` follows the `Result` pattern (`Either<Failure, T>`).

### References

- [Tech Spec: Epic 4](docs/sprint-artifacts/tech-spec-epic-4.md)
- [Architecture Document](docs/architecture.md)
- [UI Design System](docs/ui-design-system.md)

## Dev Agent Record

### Context Reference

- [Context File](docs/sprint-artifacts/story-4-1-7-day-forecast-list.context.xml)

### Agent Model Used

Antigravity (AI)

### Debug Log References

### Completion Notes List

### File List

- lib/features/planner/data/repositories/planner_repository.dart
- lib/features/planner/domain/entities/daily_forecast.dart
- lib/features/planner/domain/logic/planner_logic.dart
- lib/features/planner/domain/repositories/i_planner_repository.dart
- lib/features/planner/presentation/providers/planner_provider.dart
- lib/features/planner/presentation/screens/forecast_screen.dart
- lib/features/planner/presentation/widgets/forecast_list_item.dart
- test/features/planner/data/repositories/planner_repository_test.dart
- test/features/planner/domain/logic/planner_logic_test.dart
- test/features/planner/presentation/screens/forecast_screen_test.dart

## Change Log

- 2025-12-02: v0.1 - Initial Draft
- 2025-12-02: v0.2 - Added Bortle Scale requirements
- 2025-12-02: v0.3 - Senior Developer Review notes appended

## Senior Developer Review (AI)

### Reviewer: Antigravity
### Date: 2025-12-02
### Outcome: Approve

### Summary
The implementation successfully delivers the 7-Day Forecast List with the required Star Rating logic, including the newly identified requirement for Light Pollution (Bortle Scale). The code follows Clean Architecture principles, uses the Design System (`GlassPanel`), and is well-tested.

### Key Findings

- **High Severity:** None.
- **Medium Severity:** None.
- **Low Severity:**
  - `ForecastListItem`: Weather icon mapping logic (`_getWeatherIcon`) is currently private within the widget. Consider moving this to a shared `WeatherIconMapper` utility in the future for reuse across the app.

### Acceptance Criteria Coverage

| AC# | Description | Status | Evidence |
| :--- | :--- | :--- | :--- |
| 1 | Displays 7 days starting from "Today" | **IMPLEMENTED** | `ForecastScreen.dart` (ListView), `PlannerRepository.dart` (Loop 0..6) |
| 2 | Each item shows: Date, Weather Icon, Cloud Cover %, Star Rating | **IMPLEMENTED** | `ForecastListItem.dart` |
| 3 | Star Rating logic considers: Cloud Cover, Moon Phase, and Bortle Scale | **IMPLEMENTED** | `PlannerLogic.dart` (calculateStarRating), `PlannerRepository.dart` (Passes Bortle) |

**Summary:** 3 of 3 acceptance criteria fully implemented.

### Task Completion Validation

| Task | Marked As | Verified As | Evidence |
| :--- | :--- | :--- | :--- |
| Task 1: Data Layer & Logic | [x] | **VERIFIED** | `PlannerRepository.dart`, `PlannerLogic.dart` |
| - Implement PlannerRepository | [x] | **VERIFIED** | `lib/features/planner/data/repositories/planner_repository.dart` |
| - Refactor PlannerLogic (Bortle) | [x] | **VERIFIED** | `lib/features/planner/domain/logic/planner_logic.dart` |
| - Implement PlannerLogic | [x] | **VERIFIED** | `lib/features/planner/domain/logic/planner_logic.dart` |
| - Test: Update unit tests | [x] | **VERIFIED** | `test/features/planner/domain/logic/planner_logic_test.dart` |
| Task 2: UI Implementation | [x] | **VERIFIED** | `ForecastScreen.dart`, `ForecastListItem.dart` |
| - Create ForecastScreen | [x] | **VERIFIED** | `lib/features/planner/presentation/screens/forecast_screen.dart` |
| - Implement ForecastListItem | [x] | **VERIFIED** | `lib/features/planner/presentation/widgets/forecast_list_item.dart` |
| - Integrate Provider | [x] | **VERIFIED** | `lib/features/planner/presentation/providers/planner_provider.dart` |
| - Widget Test | [x] | **VERIFIED** | `test/features/planner/presentation/screens/forecast_screen_test.dart` |

**Summary:** 8 of 8 completed tasks verified.

### Test Coverage and Gaps
- **Unit Tests:** `PlannerLogic` is thoroughly tested, including edge cases for Cloud, Moon, and Bortle combinations. `PlannerRepository` is tested with mocks.
- **Widget Tests:** `ForecastScreen` is tested for Loading, Data, and Error states.

### Architectural Alignment
- Follows Clean Architecture (Data/Domain/Presentation).
- Uses Riverpod for state management.
- Uses `fpdart` for error handling (`Either<Failure, T>`).
- Consistent with UI Design System (`GlassPanel`).

### Security Notes
- No specific security concerns. Data is read-only from Open-Meteo and internal calculations.

### Action Items

**Advisory Notes:**
- [ ] [Low] Move `_getWeatherIcon` logic to a shared utility class for better reusability. (AC #2) [file: lib/features/planner/presentation/widgets/forecast_list_item.dart:82]
