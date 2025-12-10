# Epic Technical Specification: Planning & Forecast

Date: 2025-11-30
Author: Vansh
Epic ID: epic-4
Status: Draft

---

## Overview

Epic 4 focuses on extending the Astr experience beyond the "now" by enabling users to plan stargazing sessions up to 7 days in advance. This feature allows users to view a weekly forecast and simulate the dashboard state for future dates, ensuring they can identify the best upcoming nights for observation. This aligns with the "Direct Answer" philosophy by providing clear, forward-looking data.

## Objectives and Scope

**In-Scope:**
*   Implementation of a 7-Day Forecast List view showing daily weather and stargazing ratings.
*   Logic to calculate moon phase and visibility scores for future dates.
*   "Future Date Context Switching" mechanism to update the global app state (Location/Date) to a selected future date.
*   Integration with Open-Meteo API for 7-day weather data.
*   UI updates to the Home Dashboard to reflect the selected future date's data.

**Out-of-Scope:**
*   Historical weather data.
*   Saving trips or favorites (Part of Epic 5).
*   Notifications for upcoming good nights (Post-MVP).

## System Architecture Alignment

This epic leverages the existing `Location` and `Date` context providers established in Epic 1. It introduces a new `Planner` feature module (`features/planner`) following the Clean Architecture pattern. It interacts with the `AstronomyEngine` (Epic 1) for future moon/planet calculations and the `WeatherRepository` (via Cloudflare Proxy, Epic 6) for forecast data. The UI will reuse the `GlassPanel` and `NebulaBackground` components.

## Detailed Design

### Services and Modules

| Module | Responsibility | Owner |
| :--- | :--- | :--- |
| `features/planner/data` | Fetching 7-day forecast data from Open-Meteo. | `PlannerRepository` |
| `features/planner/domain` | Logic for "Star Rating" of future nights (Cloud + Moon). | `PlannerLogic` |
| `features/planner/presentation` | UI for the Forecast List and Day Detail interaction. | `ForecastScreen` |
| `core/providers` | Managing Global Date Context (`dateProvider`). | `DateNotifier` |

### Data Models and Contracts

```dart
class DailyForecast {
  final DateTime date;
  final double cloudCoverAvg;
  final double moonIllumination;
  final String weatherCode; // Open-Meteo code
  final int starRating; // 1-5 scale
  
  // Computed
  bool get isGoodNight => starRating >= 4;
}
```

### APIs and Interfaces

*   `GET /api/weather/forecast?lat=...&long=...&days=7` (Proxied to Open-Meteo)
    *   Response: JSON with daily cloud cover, precipitation probability, and weather codes.

### Workflows and Sequencing

1.  **View Forecast:** User taps "Forecast" tab -> App fetches 7-day weather -> App calculates Moon Phase for each day -> App combines data into `DailyForecast` list -> UI displays list.
2.  **Select Date:** User taps a Day -> `dateProvider` updates to selected date -> Router navigates to Home (or stays on Planner with Home-like view) -> Home Dashboard listens to `dateProvider` and refreshes all widgets with new date context.

## Non-Functional Requirements

### Performance

*   Forecast list load time < 1s (cached).
*   Date switch transition < 200ms.

### Security

*   No PII sent to weather API.
*   API keys for weather service must be proxied (as per Epic 6).

### Reliability/Availability

*   Graceful degradation if weather API fails (show "Offline Mode" with just Moon/Astro data).

### Observability

*   Log API failures and empty data states.

## Dependencies and Integrations

*   **Open-Meteo API:** For weather forecast.
*   **Swiss Ephemeris (Dart):** For future moon phase calculations.
*   **Riverpod:** For global state management (`dateProvider`).

## Acceptance Criteria (Authoritative)

1.  **7-Day Forecast List:**
    *   [ ] Displays 7 days starting from "Today".
    *   [ ] Each item shows: Date, Weather Icon, Cloud Cover %, Star Rating (1-5).
    *   [ ] Star Rating logic considers both Cloud Cover and Moon Phase.
2.  **Future Date Context:**
    *   [ ] Tapping a forecast item updates the global `dateProvider`.
    *   [ ] App navigates to a view showing the Dashboard for that specific date.
    *   [ ] The Dashboard clearly indicates it is showing "Future Data" (e.g., distinct header or banner).
    *   [ ] "Top 3 Objects" and "Bortle/Cloud" bars update to reflect the future date's conditions.

## Traceability Mapping

| AC ID | Spec Section | Component | Test Idea |
| :--- | :--- | :--- | :--- |
| AC1.1 | Detailed Design | `PlannerRepository` | Mock API response, verify list parsing. |
| AC1.2 | Detailed Design | `PlannerLogic` | Unit test rating logic with various cloud/moon combos. |
| AC2.1 | Detailed Design | `DateNotifier` | Widget test: Tap item, verify provider state change. |
| AC2.2 | Detailed Design | `HomeScreen` | Widget test: Verify UI updates when provider changes. |

## Risks, Assumptions, Open Questions

*   **Assumption:** Open-Meteo provides reliable 7-day cloud cover forecasts.
*   **Risk:** Weather forecasts > 3 days are often inaccurate. *Mitigation:* Display a "Low Confidence" indicator for days 4-7.
*   **Question:** Should we cache the forecast? *Decision:* Yes, cache for 1 hour to prevent API spam.

## Test Strategy Summary

*   **Unit Tests:** `PlannerLogic` (Rating calculation), `PlannerRepository` (Parsing).
*   **Widget Tests:** Forecast List rendering, Date switching interaction.
*   **Manual:** Compare app forecast with other weather apps.
