# Epic Technical Specification: Celestial Catalog & Visibility Graph

Date: 2025-11-29
Author: Vansh
Epic ID: 3
Status: Draft

---

## Overview

This epic introduces the core "Deep Precision" features of Astr. It transforms the app from a simple dashboard into a powerful planning tool. The centerpiece is the **Universal Visibility Graph**, a novel visualization that plots an object's altitude against moon interference over time, giving users a clear "Prime View" window. It also establishes the **Celestial Catalog**, allowing users to browse and select specific targets (Planets, Stars, Constellations).

## Objectives and Scope

### In-Scope
*   **Celestial Catalog (Story 3.1):** A browsable list of celestial objects categorized by type.
*   **Object Detail Page (Story 3.2):** A dedicated "Deep Cosmos" themed page for each object.
*   **Universal Visibility Graph (Story 3.3):** An interactive Rive-based graph showing Altitude vs. Time and Moon Interference.
*   **Data Source:** Offline database of major celestial objects.

### Out-of-Scope
*   **AR Star Map:** Augmented reality navigation is a future growth feature.
*   **Search:** Full text search is not required for MVP (browsing by category is sufficient).
*   **Deep Sky Objects (DSO):** MVP focuses on Planets, Major Stars, and Constellations. Fainter DSOs are post-MVP.

## System Architecture Alignment

This epic builds upon the **Foundation (Epic 1)** and **Dashboard (Epic 2)**.
*   **Presentation:** Heavily relies on the **"Rive Pattern"** for the Visibility Graph (Story 3.3) to ensure 60fps performance and fluid interactivity. The **"Glass Pattern"** is used for the Catalog UI.
*   **Domain:** Leverages the **Astronomy Engine (`IAstroEngine`)** established in Story 1.2 to perform real-time calculations for the graph (Altitude/Azimuth over time).
*   **Data:** Introduces a local **Catalog Repository** to store static object data (Name, Type, Magnitude) which is then enriched with dynamic data from the Engine.

## Detailed Design

### Services and Modules

| Module | Responsibility | Inputs | Outputs |
| :--- | :--- | :--- | :--- |
| **CatalogRepository** | Provides static data for celestial objects. | Category (Planet, Star, etc.) | `List<CelestialObject>` |
| **VisibilityService** | Calculates the visibility curve for a specific object and location over a time range. | `CelestialObject`, `GeoLocation`, `DateTime` | `VisibilityGraphData` (Points) |
| **MoonInterferenceLogic** | Calculates the "Moon Wash" factor based on Moon Phase and Altitude. | `MoonPosition`, `ObjectPosition` | `double` (0.0 - 1.0) |

### Data Models and Contracts

**CelestialObject**
```dart
enum CelestialType { planet, star, constellation, galaxy }

class CelestialObject {
  final String id;
  final String name;
  final CelestialType type;
  final double magnitude; // Base magnitude
  final String iconPath; // Asset path
  // ... other static data
}
```

**VisibilityGraphData**
```dart
class VisibilityGraphData {
  final List<GraphPoint> objectCurve; // Altitude over time
  final List<GraphPoint> moonCurve;   // Interference over time
  final List<TimeRange> optimalWindows; // Time ranges where viewing is best
}

class GraphPoint {
  final DateTime time;
  final double value; // Altitude (deg) or Interference (%)
}
```

### APIs and Interfaces

**ICatalogRepository**
```dart
Future<Either<Failure, List<CelestialObject>>> getObjectsByType(CelestialType type);
Future<Either<Failure, CelestialObject>> getObjectById(String id);
```

**IVisibilityService**
```dart
Future<Either<Failure, VisibilityGraphData>> calculateVisibility({
  required CelestialObject object,
  required GeoLocation location,
  required DateTime date,
});
```

### Workflows and Sequencing

1.  **Catalog Load:** User opens "Celestial Bodies" tab -> `CatalogNotifier` calls `CatalogRepository.getObjectsByType` -> UI renders list.
2.  **Detail Open:** User taps object -> App navigates to `ObjectDetailPage` passing `CelestialObject`.
3.  **Graph Calculation:** `ObjectDetailNotifier` calls `VisibilityService.calculateVisibility` -> Service iterates from `Now` to `Now + 12h` (e.g., 15-min intervals) -> Calls `IAstroEngine` for each point -> Returns `VisibilityGraphData`.
4.  **Rendering:** UI passes data to `AstrRiveAnimation` (Visibility Graph) -> Rive State Machine animates the curves.

## Non-Functional Requirements

### Performance
*   **Graph Calculation:** Generating 12 hours of data points (approx 48 points) must take **< 200ms** on mid-range devices.
*   **Animation:** The Visibility Graph must render at **60fps**.

### Security
*   No specific security concerns (offline data).

### Reliability/Availability
*   **Offline First:** All features in this epic must work 100% offline.

### Observability
*   Log any calculation errors in `VisibilityService`.

## Dependencies and Integrations

*   **Rive:** `rive` package for the Visibility Graph.
*   **Swiss Ephemeris:** `swisseph` (via `IAstroEngine`) for position calculations.
*   **fpdart:** For `Either` result types.

## Acceptance Criteria (Authoritative)

1.  **Catalog Browsing:** Users can view a list of objects categorized by Planet, Star, Constellation, Galaxy.
2.  **Object Detail:** Tapping an object opens a full-screen detail page with "Deep Cosmos" theme.
3.  **Visibility Graph (X-Axis):** Graph shows time from Now to +12 hours.
4.  **Visibility Graph (Y-Axis):** Graph shows Altitude (0-90°).
5.  **Moon Interference:** Graph visually indicates moon interference (e.g., opacity or separate curve).
6.  **Prime Window:** Logic identifies and highlights time ranges where Object Altitude > 30° AND Moon Interference is low.
7.  **Rive Integration:** The graph is implemented using Rive with inputs for `objectAltitude`, `moonInterference`, `timeScrubber`.

## Traceability Mapping

| AC ID | Spec Section | Component | Test Idea |
| :--- | :--- | :--- | :--- |
| AC-3.1.1 | Catalog Browsing | `CatalogRepository`, `CatalogScreen` | Widget Test: Verify tabs and list rendering. |
| AC-3.2.1 | Object Detail | `ObjectDetailPage` | Widget Test: Verify navigation and argument passing. |
| AC-3.3.1 | Visibility Graph | `VisibilityService`, `RiveGraph` | Unit Test: Verify calculation logic returns correct points. |
| AC-3.3.6 | Prime Window | `VisibilityService` | Unit Test: Verify "Optimal" flag is true only when conditions met. |

## Risks, Assumptions, Open Questions

*   **Risk:** Calculating graph points for 12 hours might be slow if `swisseph` calls are expensive.
    *   *Mitigation:* Use `compute` (Isolate) if main thread jank occurs. Optimize interval (e.g., every 30 mins instead of 15).
*   **Assumption:** We have a static list of "Major Stars" and "Constellations" available to populate the catalog.
*   **Question:** Do we need to handle "Set" times explicitly in the graph (i.e., cut off the line)?
    *   *Decision:* Yes, Altitude < 0 should be clamped or hidden.

## Test Strategy Summary

*   **Unit Tests:** Extensive testing of `VisibilityService` to ensure the "Prime Window" logic is accurate. Mock `IAstroEngine`.
*   **Widget Tests:** Verify the Catalog list filters correctly. Verify the Detail Page loads without error.

### Post-Review Follow-ups

- **Advisory:** Consider adding haptic feedback to the scrubber in a future polish story (Story 5.3?).
- **Advisory:** Monitor performance on very old devices if the graph complexity increases (e.g., adding more celestial bodies).
