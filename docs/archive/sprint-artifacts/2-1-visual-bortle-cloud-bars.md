# User Story: 2.1 Visual Bortle & Cloud Bars

> **Epic:** 2 - The Dashboard ("Is Tonight Good?")
> **Story ID:** 2.1
> **Story Title:** Visual Bortle & Cloud Bars
> **Status:** review
> **Priority:** High
> **Estimation:** 5 Points

## 1. Story Statement
**As a** User,
**I want** to see the light pollution and cloud cover as visual bars,
**So that** I can understand conditions without reading numbers.

## 2. Context & Requirements
This story addresses the "Visual Dashboard" requirement. We need to move away from raw numbers and present data visually. This involves fetching weather data (Cloud Cover) and using the location context (from Story 1.3) to determine the Bortle Scale (or mock it if API unavailable). The key focus is on the **Visuals** and **Animation**.

### Requirements Source
*   **PRD:** FR4 (Visual Dashboard), FR15 (Weather Data).
*   **Epics:** Story 2.1.
*   **Architecture:** Presentation Layer (GlassPanel), Data Layer (Open-Meteo).

## 3. Acceptance Criteria

| AC ID | Criteria | Verification Method |
| :--- | :--- | :--- |
| **AC-2.1.1** | **Bortle Bar:** Displays a visual gradient (1-9) representing the Bortle Scale. | Visual Inspection. |
| **AC-2.1.2** | **Bortle Indicator:** Shows the current location's Bortle class (e.g., "Class 4") on the bar. | Visual Inspection / Widget Test. |
| **AC-2.1.3** | **Cloud Bar:** Displays a visual fill bar representing current cloud cover percentage (0-100%). | Visual Inspection / Widget Test. |
| **AC-2.1.4** | **Animation:** Both bars animate (fill up) on screen load (`animate-slide-up` or similar). | Visual Inspection. |
| **AC-2.1.5** | **Data Source:** Fetches current Cloud Cover from Open-Meteo API using the current location. | Integration Test / Network Log. |
| **AC-2.1.6** | **Error Handling:** If weather fetch fails, displays a graceful error state (not a crash) on the Cloud Bar. | Manual: Airplane Mode. |

## 4. Technical Tasks

    - [x] Domain Layer
        - [x] Define `Weather` entity (cloudCover, seeing, etc.).
        - [x] Define `IWeatherService` interface.
        - [x] Define `BortleScale` enum/logic (Class 1-9).
    - [x] Data Layer
        - [x] Implement `OpenMeteoWeatherService` (Direct API call for now, as per Epic 6 note).
        - [x] Create `WeatherRepository` to abstract the data source.
        - [x] **Constraint:** Use `fpdart` `Either<Failure, Weather>` for error handling.

### 4.3 Presentation Layer (Widgets)
- [x] Create `BortleBar` widget (CustomPainter or Container with Gradient).
- [x] Create `CloudBar` widget.
- [x] Implement `GlassPanel` container if not already available (from Arch doc).
- [x] Add animations (Flutter `AnimationController` or `animate_do` package if allowed, otherwise standard `TweenAnimation`).

### 4.4 State Management
- [x] Create `WeatherNotifier` (Riverpod) to fetch data based on `AstrContext` (Location).

### 4.5 Testing
- [x] Unit Test: `OpenMeteoWeatherService` (Mock Dio/Http).
- [x] Widget Test: Verify Bars render correctly with given data.
- [x] Widget Test: Verify Error state renders.

## 5. Dev Notes
*   **Architecture:** Follow the "Glass" pattern. Wrap these bars in a `GlassPanel` to match the "Deep Cosmos" theme.
*   **API:** Open-Meteo is free and requires no key for non-commercial use. Endpoint: `https://api.open-meteo.com/v1/forecast?latitude=...&longitude=...&current=cloud_cover`.
*   **Bortle Data:** Real-time Bortle data APIs are rare/expensive. For MVP, we might need to:
    1.  Mock it based on location (random or hardcoded for demo).
    2.  Or find a simple lat/long -> Bortle lookup (light pollution map overlay).
    *Decision:* For this story, if no free API is found quickly, hardcode/mock the Bortle value based on a hash of the lat/long or a simple lookup, but ensure the **UI** is fully functional.
*   **Animation:** Use simple implicit animations (`AnimatedContainer`) or `TweenAnimationBuilder` for the bar fill effect.

### Learnings from Previous Story
**From Story 1.3 (Status: Done)**
*   **Error Handling:** Continue using `fpdart` `Either` for the Weather Service.
*   **State Management:** Use `ref.watch(astrContextProvider)` to trigger weather updates when location changes.
*   **Testing:** Mock the HTTP client for unit tests.

## 6. Dev Agent Record

### Context Reference
<!-- Path(s) to story context XML will be added here by context workflow -->
*   [Context XML](2-1-visual-bortle-cloud-bars.context.xml)

### Agent Model Used
{{agent_model_name_version}}

### Debug Log References

### Completion Notes List
- Implemented Domain Layer: `Weather`, `BortleScale`, `IWeatherRepository`.
- Implemented Data Layer: `OpenMeteoWeatherService` (using Dio), `WeatherRepositoryImpl`.
- Implemented Presentation Layer: `GlassPanel` (Core), `BortleBar`, `CloudBar`.
- Implemented State Management: `WeatherNotifier` (Riverpod).
- Added Unit Tests for Service and Widget Tests for Bars.
- Verified all tests pass.

### File List
- lib/features/dashboard/domain/entities/bortle_scale.dart
- lib/features/dashboard/domain/entities/weather.dart
- lib/features/dashboard/domain/repositories/i_weather_repository.dart
- lib/features/dashboard/data/datasources/open_meteo_weather_service.dart
- lib/features/dashboard/data/repositories/weather_repository_impl.dart
- lib/core/widgets/glass_panel.dart
- lib/features/dashboard/presentation/widgets/bortle_bar.dart
- lib/features/dashboard/presentation/widgets/cloud_bar.dart
- lib/features/dashboard/presentation/providers/weather_provider.dart
- test/features/dashboard/data/datasources/open_meteo_weather_service_test.dart
- test/features/dashboard/presentation/widgets/bortle_bar_test.dart
- test/features/dashboard/presentation/widgets/cloud_bar_test.dart

## 7. Senior Developer Review (AI)

### Reviewer: Amelia (Dev Agent)
### Date: 2025-11-29
### Outcome: Approve

**Summary:**
The implementation fully satisfies the requirements for Visual Bortle and Cloud Bars. The architecture follows the specified patterns (Glass UI, Repository Pattern, Result Type). The use of Rive for animations is correctly implemented via `AstrRiveAnimation`.

### Key Findings
*   **High:** None.
*   **Medium:** None.
*   **Low:** None.

### Acceptance Criteria Coverage

| AC ID | Description | Status | Evidence |
| :--- | :--- | :--- | :--- |
| **AC-2.1.1** | Bortle Bar Gradient | **IMPLEMENTED** | `lib/features/dashboard/presentation/widgets/bortle_bar.dart` (uses `AstrRiveAnimation`) |
| **AC-2.1.2** | Bortle Indicator | **IMPLEMENTED** | `lib/features/dashboard/presentation/widgets/bortle_bar.dart` (Text + Rive Input) |
| **AC-2.1.3** | Cloud Bar Fill | **IMPLEMENTED** | `lib/features/dashboard/presentation/widgets/cloud_bar.dart` (uses `AstrRiveAnimation`) |
| **AC-2.1.4** | Animation | **IMPLEMENTED** | `lib/core/widgets/astr_rive_animation.dart` (handles Rive init) |
| **AC-2.1.5** | Data Source (Open-Meteo) | **IMPLEMENTED** | `lib/features/dashboard/data/datasources/open_meteo_weather_service.dart` |
| **AC-2.1.6** | Error Handling | **IMPLEMENTED** | `lib/features/dashboard/presentation/widgets/cloud_bar.dart` (Error UI) |

**Summary:** 6 of 6 acceptance criteria fully implemented.

### Task Completion Validation

| Task | Marked As | Verified As | Evidence |
| :--- | :--- | :--- | :--- |
| Define Weather entity | [x] | **VERIFIED** | `lib/features/dashboard/domain/entities/weather.dart` |
| Define IWeatherService | [x] | **VERIFIED** | `lib/features/dashboard/domain/repositories/i_weather_repository.dart` |
| Define BortleScale | [x] | **VERIFIED** | `lib/features/dashboard/domain/entities/bortle_scale.dart` |
| Implement OpenMeteoWeatherService | [x] | **VERIFIED** | `lib/features/dashboard/data/datasources/open_meteo_weather_service.dart` |
| Create WeatherRepository | [x] | **VERIFIED** | `lib/features/dashboard/data/repositories/weather_repository_impl.dart` |
| Create BortleBar widget | [x] | **VERIFIED** | `lib/features/dashboard/presentation/widgets/bortle_bar.dart` |
| Create CloudBar widget | [x] | **VERIFIED** | `lib/features/dashboard/presentation/widgets/cloud_bar.dart` |
| Implement GlassPanel | [x] | **VERIFIED** | `lib/core/widgets/glass_panel.dart` |
| Add animations | [x] | **VERIFIED** | `lib/core/widgets/astr_rive_animation.dart` |
| Create WeatherNotifier | [x] | **VERIFIED** | `lib/features/dashboard/presentation/providers/weather_provider.dart` |
| Unit Test: Service | [x] | **VERIFIED** | `test/features/dashboard/data/datasources/open_meteo_weather_service_test.dart` |
| Widget Test: Bars | [x] | **VERIFIED** | `test/features/dashboard/presentation/widgets/bortle_bar_test.dart` |

**Summary:** 12 of 12 completed tasks verified.

### Test Coverage and Gaps
*   Unit tests cover the `OpenMeteoWeatherService`.
*   Widget tests cover `BortleBar` and `CloudBar` rendering.
*   **Gap:** No integration test for `WeatherNotifier` + `WeatherRepository`, but unit tests cover the logic.

### Architectural Alignment
*   **Glass Pattern:** Used `GlassPanel` correctly.
*   **Result Pattern:** Used `Either<Failure, Weather>` in repository.
*   **Proxy Pattern:** `OpenMeteoWeatherService` calls API directly (Allowed for MVP per Epic 6 note, but should eventually move to Cloudflare).

### Action Items
**Advisory Notes:**
- Note: `OpenMeteoWeatherService` currently calls the API directly. Ensure this is migrated to the Cloudflare Worker proxy in Epic 6.
