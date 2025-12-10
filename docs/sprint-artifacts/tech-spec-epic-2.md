# Epic Technical Specification: Epic 2: Dynamic Graphing System Enhancements 📈

Date: 2025-12-03
Author: Vansh
Epic ID: 2
Status: Draft

---

## Overview

Epic 2 focuses on enhancing the existing dynamic graphing system to provide scientifically accurate and actionable data to the user. The primary goals are to standardize all graph timeframes to the relevant observing night (Sunset to Sunrise), implement "Prime View" logic to highlight optimal observing conditions, and add real-time position indicators to visibility graphs.

This epic builds upon the "Core Engine" established in Epic 1, leveraging the offline astronomy engine and reliable weather data to drive these visualizations. The work is strictly additive to the existing `CustomPainter` implementation, preserving the current "Glass UI" aesthetic while improving data utility.

## Objectives and Scope

**In-Scope:**
*   **Timeframe Standardization:** Updating all graphs (Atmospherics, Visibility) to display the X-axis from Sunset (Day N) to Sunrise (Day N+1).
*   **Prime View Logic:** Algorithm to calculate the optimal observing window based on Cloud Cover and Moon interference, and visualizing this on the Atmospherics graph.
*   **Real-Time Indicators:** Adding a "Current Position" indicator (dot) to Visibility graphs that moves in real-time along the altitude curve.
*   **Context-Aware Styling:** Implementing color logic for indicators (Orange for Home, Blue for Catalog).
*   **"Now" Indicator:** Ensuring the vertical "Now" line on the Atmospherics graph is accurate and distinct.

**Out-Scope:**
*   **Graph Redesign:** No changes to the visual style, gradients, or general layout of the graphs.
*   **New Graph Types:** No new types of charts; only enhancements to existing ones.
*   **Rive Integration:** Rive will not be used for these graphs; implementation remains pure Flutter `CustomPainter`.

## System Architecture Alignment

This epic aligns with the **Dart Native, Offline-First** architecture defined in `docs/architecture.md`.
*   **Presentation Layer:** Uses Flutter's `CustomPainter` for high-performance rendering.
*   **State Management:** Uses `Riverpod` to supply data (Weather, Celestial Positions) to the graph widgets.
*   **Performance:** Graph painting logic runs on the UI thread, so calculations must remain lightweight. Heavy lifting (Prime View calculation) should be pre-calculated or optimized to avoid frame drops (NFR: 60fps).
*   **Data Source:** Consumes data from `WeatherService` (Epic 1.4) and `AstronomyEngine` (Epic 1.1).

## Detailed Design

### Services and Modules

| Module/Component | Responsibility | Inputs | Outputs | Owner |
| :--- | :--- | :--- | :--- | :--- |
| `GraphTimeframeProvider` | Calculates the start (Sunset) and end (Sunrise) timestamps for the graph X-axis. | Selected Date, Location | `DateTimeRange` (Sunset -> Sunrise) | UI Team |
| `PrimeViewCalculator` | Determines the optimal observing window. | `List<HourlyWeather>`, `MoonPhase` | `DateTimeRange` (Prime Window) | Logic Team |
| `AtmosphericsPainter` | Renders the cloud/moon graph with Prime View highlight. | Weather Data, Prime Window, Timeframe | Canvas Drawing | UI Team |
| `VisibilityPainter` | Renders object altitude curve with current position indicator. | `List<AltitudePoint>`, Current Time | Canvas Drawing | UI Team |

### Data Models and Contracts

**Prime View Result:**
```dart
class PrimeViewWindow {
  final DateTime start;
  final DateTime end;
  final double score; // 0.0 to 1.0 (quality of window)

  PrimeViewWindow({required this.start, required this.end, required this.score});
}
```

**Graph Data Point:**
```dart
class GraphPoint {
  final DateTime time;
  final double value; // Altitude or Cloud Cover %

  GraphPoint({required this.time, required this.value});
}
```

### APIs and Interfaces

No new external APIs. Internal interfaces for graph data providers:

```dart
abstract class IGraphDataProvider {
  Future<List<GraphPoint>> getAltitudeCurve(CelestialObject object, Location loc, DateTime date);
  Future<PrimeViewWindow?> calculatePrimeView(Location loc, DateTime date);
}
```

### Workflows and Sequencing

**Rendering a Visibility Graph:**
1.  User selects an object and date.
2.  UI requests `GraphTimeframe` (Sunset to Sunrise) for that date.
3.  UI requests `AltitudeCurve` points from `AstronomyEngine` for that timeframe.
4.  `VisibilityPainter` draws the curve.
5.  `VisibilityPainter` calculates the Y-position (Altitude) for `DateTime.now()`.
6.  `VisibilityPainter` draws the "Current Position" indicator at that (X, Y) coordinate.

## Non-Functional Requirements

### Performance
*   **Frame Rate:** Graph rendering must not drop frames during scrolling (Target: 60fps).
*   **Calculation:** Prime View calculation should take < 10ms on the main thread, or be offloaded to an Isolate if complex.

### Security
*   No specific security requirements for this UI-focused epic.

### Reliability/Availability
*   **Graceful Degradation:** If weather data is missing, the Atmospherics graph should show a "No Data" state or fallback to clear skies (with visual indication) rather than crashing.

### Observability
*   Log errors in `PrimeViewCalculator` if data is insufficient to determine a window.

## Dependencies and Integrations

*   **Flutter SDK:** `CustomPainter` API.
*   **Riverpod:** For accessing `WeatherState` and `LocationState`.
*   **Intl:** For time formatting on graph axes.
*   **Epic 1 Components:** `WeatherService`, `AstronomyEngine`.

## Acceptance Criteria (Authoritative)

1.  **Standardize Graph Timeframes (Story 2.1)**
    *   **AC1:** All graphs (Atmospherics, Visibility) display an X-axis spanning from Sunset of the selected date to Sunrise of the following day.
    *   **AC2:** If the current time is outside this window (e.g., noon), the graph still shows the upcoming/previous night context relevant to the user's selection.

2.  **Atmospherics Graph & Prime View (Story 2.2)**
    *   **AC1:** The graph visually highlights the time window with the lowest combined Cloud Cover and Moon interference ("Prime View").
    *   **AC2:** A vertical "Now" indicator (Orange line) is drawn at the correct X-position for the current time.
    *   **AC3:** If no Prime View window meets the quality threshold, no highlight is shown (or a "Conditions Poor" message is displayed).

3.  **Visibility Graph Indicators (Story 2.3)**
    *   **AC1:** A "Current Position" indicator (circle) is drawn on the altitude curve corresponding to `DateTime.now()`.
    *   **AC2:** The indicator's position updates in real-time (or refreshes every minute).
    *   **AC3:** The indicator stroke color is **Orange** on the Home Screen and **Blue** on Catalog/Details screens.

## Traceability Mapping

| AC ID | Spec Section | Component | Test Idea |
| :--- | :--- | :--- | :--- |
| 2.1.AC1 | Detailed Design / Workflows | `GraphTimeframeProvider` | Unit test: Verify start/end times for a given date/location. |
| 2.2.AC1 | Detailed Design / Models | `PrimeViewCalculator` | Unit test: Mock weather data and verify calculated window. |
| 2.2.AC2 | Detailed Design / Services | `AtmosphericsPainter` | Widget test: Verify "Now" line X-offset matches current time. |
| 2.3.AC1 | Detailed Design / Services | `VisibilityPainter` | Widget test: Verify indicator Y-value matches altitude at `now`. |
| 2.3.AC3 | Objectives / Scope | `VisibilityPainter` | Visual inspection / Golden test: Verify color changes based on context. |

## Risks, Assumptions, Open Questions

*   **Risk:** Complex `CustomPainter` logic could cause jank on older devices.
    *   *Mitigation:* Optimize painting commands; cache path objects where possible.
*   **Assumption:** Weather data (Cloud Cover) is available for the entire night window.
    *   *Mitigation:* Handle gaps in weather data gracefully (interpolation or "no data" segments).
*   **Question:** What is the exact threshold for "Prime View"? (e.g., Cloud < 20% AND Moon Illumination < 50%?)
    *   *Next Step:* Define default thresholds in `PrimeViewCalculator` and allow for future tuning.

## Test Strategy Summary

*   **Unit Tests:** Validate `PrimeViewCalculator` logic and `GraphTimeframeProvider` date math.
*   **Widget Tests:** Verify that `CustomPainter` draws the expected elements (lines, dots, highlights) at correct coordinates.
*   **Manual Testing:** Verify visual smoothness (60fps) and correct color context (Orange vs Blue) on a physical device.
