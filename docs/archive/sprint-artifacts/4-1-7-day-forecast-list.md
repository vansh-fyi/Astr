# Story 4.1: 7-Day Forecast List

**Status:** review

## Story

As a User,
I want to see a list of the next 7 days with summary conditions,
so that I can pick the best night for stargazing.

## Acceptance Criteria

1. **7-Day Forecast List:**
   - [ ] Displays 7 days starting from "Today".
   - [ ] Each item shows: Date, Weather Icon, Cloud Cover %, Star Rating (1-5).
   - [ ] Star Rating logic considers both Cloud Cover and Moon Phase.

## Tasks / Subtasks

- [x] Task 1: Create `features/planner` module structure (AC: 1)
  - [x] Create `features/planner/data`, `domain`, `presentation` folders.
  - [x] Define `DailyForecast` model in `domain`.

- [x] Task 2: Implement `PlannerRepository` (AC: 1, 2)
  - [x] Implement method to fetch 7-day forecast from Open-Meteo API.
  - [x] *Note:* Use direct API call for now (Epic 6 Proxy is in backlog).
  - [x] Map API response to `DailyForecast` domain entities.
  - [x] Unit Test: Verify API response parsing.

- [x] Task 3: Implement `PlannerLogic` (AC: 3)
  - [x] Implement logic to calculate "Star Rating" (1-5) based on Cloud Cover and Moon Phase.
  - [x] Integrate `AstronomyEngine` (from Epic 1) to calculate moon phase for future dates.
  - [x] Unit Test: Verify rating logic with various cloud/moon combinations.

- [x] Task 4: Implement `ForecastScreen` UI (AC: 1, 2)
  - [x] Create `ForecastScreen` widget.
  - [x] Implement `ForecastList` using `ListView.builder`.
  - [x] Use `GlassPanel` for list items to match "Astr Aura" theme.
  - [x] Display Date, Weather Icon, Cloud %, and Star Rating.
  - [x] Widget Test: Verify list renders correct number of items and data.

## Dev Notes

- **Architecture:** Follow Clean Architecture (Data/Domain/Presentation).
- **State Management:** Use Riverpod for `plannerProvider`.
- **UI Components:** Reuse `GlassPanel` from `core/widgets`.
- **Dependencies:**
  - `open_meteo` (or `http`/`dio` for direct call).
  - `swisseph` (via `AstronomyEngine`) for moon calculations.
- **Testing:**
  - Unit tests for Logic and Repository.
  - Widget tests for Screen.

### Project Structure Notes

- New module: `lib/features/planner`
- Reuse `lib/features/astronomy` for moon calculations.

### References

- [Tech Spec: Epic 4](docs/sprint-artifacts/tech-spec-epic-4.md)
- [PRD: Epic 4](docs/PRD.md#epic-4-planning--forecast)
- [Architecture: System Architecture](docs/architecture.md#4-system-architecture)

## Dev Agent Record

### Context Reference

<!-- Path(s) to story context XML will be added here by context workflow -->
- [Story Context](docs/sprint-artifacts/4-1-7-day-forecast-list.context.xml)

### Agent Model Used

PLACEHOLDER_M8

### Debug Log References

### Completion Notes List

### File List

- lib/features/planner/domain/entities/daily_forecast.dart
- lib/features/planner/domain/repositories/i_planner_repository.dart
- lib/features/planner/data/repositories/planner_repository_impl.dart
- lib/features/planner/domain/logic/planner_logic.dart
- lib/features/planner/presentation/providers/planner_provider.dart
- lib/features/planner/presentation/pages/forecast_screen.dart
- test/features/planner/data/repositories/planner_repository_impl_test.dart
- test/features/planner/domain/logic/planner_logic_test.dart
- test/features/planner/presentation/pages/forecast_screen_test.dart

## Senior Developer Review (AI)

- **Reviewer:** Antigravity (AI)
- **Date:** 2025-11-30
- **Outcome:** Approve

### Summary
The implementation fully satisfies the requirements for the 7-Day Forecast List. The architecture follows the project's Clean Architecture standards, separating Data, Domain, and Presentation layers. The logic for calculating Star Ratings is sound and well-tested, correctly integrating Cloud Cover and Moon Phase penalties. The UI leverages the shared `GlassPanel` component, ensuring consistency with the "Astr Aura" design system.

### Key Findings
- **High Severity:** None.
- **Medium Severity:** None.
- **Low Severity:**
  - `PlannerRepositoryImpl` calculates a preliminary `starRating` which is later overwritten by `PlannerLogic`. This is harmless but slightly redundant.
  - `ForecastScreen` uses a simple hardcoded mapping for weather icons. This is acceptable for MVP but should be moved to a dedicated mapper in the future.

### Acceptance Criteria Coverage

| AC# | Description | Status | Evidence |
| :--- | :--- | :--- | :--- |
| 1.1 | Displays 7 days starting from "Today" | **IMPLEMENTED** | `PlannerRepositoryImpl.dart:22` (forecast_days=7), `ForecastScreen.dart:40` |
| 1.2 | Each item shows: Date, Icon, Cloud%, Star Rating | **IMPLEMENTED** | `ForecastScreen.dart:31-103` |
| 1.3 | Star Rating logic considers Cloud & Moon | **IMPLEMENTED** | `PlannerLogic.dart:57-75` |

**Summary:** 3 of 3 acceptance criteria fully implemented.

### Task Completion Validation

| Task | Marked As | Verified As | Evidence |
| :--- | :--- | :--- | :--- |
| Task 1 | [x] | **VERIFIED** | `features/planner` structure created, `DailyForecast` defined. |
| Task 2 | [x] | **VERIFIED** | `PlannerRepositoryImpl` implemented and tested. |
| Task 3 | [x] | **VERIFIED** | `PlannerLogic` implemented and tested. |
| Task 4 | [x] | **VERIFIED** | `ForecastScreen` implemented and tested. |

**Summary:** 4 of 4 completed tasks verified.

### Test Coverage and Gaps
- **Unit Tests:** `PlannerRepositoryImpl` and `PlannerLogic` have comprehensive unit tests covering success/failure paths and logic variations.
- **Widget Tests:** `ForecastScreen` has widget tests verifying the loading state and list rendering.
- **Gaps:** None identified for this scope.

### Architectural Alignment
- **Clean Architecture:** Adhered to (Data/Domain/Presentation).
- **State Management:** Riverpod used correctly (`PlannerProvider`).
- **UI:** Consistent with Design System (`GlassPanel`).

### Security Notes
- No PII handled.
- API calls are direct to Open-Meteo (as per task note, proxy is backlog).

### Action Items

**Advisory Notes:**
- Note: Consider moving the weather icon mapping to a separate `WeatherIconMapper` class in the future for better reusability.
- Note: The redundant star rating calculation in `PlannerRepositoryImpl` can be removed when refactoring.

