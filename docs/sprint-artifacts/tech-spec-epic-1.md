# Epic Technical Specification: Foundation & Offline Engine Overhaul

Date: 2025-12-03
Author: Vansh
Epic ID: 1
Status: Draft

---

## Overview

This epic establishes the core "Offline-First" capability of Astr. It involves replacing the legacy `sweph` dependency with a pure Dart implementation of astronomical algorithms (Meeus), integrating a local SQLite database for star/DSO catalogs, and implementing a hybrid Light Pollution system. This foundation is critical for enabling the app to function without an internet connection, a key value proposition.

## Objectives and Scope

**In Scope:**
*   Implementation of `IAstroEngine` using Dart Native algorithms (Meeus).
*   Integration of `sqflite` with a pre-populated `astr.db` (Stars, DSOs).
*   Hybrid Light Pollution service (API + WebP Fallback).
*   Reliable Weather fetching on mobile devices.
*   Isolate-based background processing for heavy calculations.

**Out of Scope:**
*   UI changes (strictly limited to Data/Domain layers).
*   Graph rendering logic (handled in Epic 2).
*   AR features.

## System Architecture Alignment

This epic directly implements the "Offline-First" and "Dart Native" architectural decisions.
*   **Database:** Adheres to the decision to use **SQLite** for relational queries of the star catalog.
*   **Concurrency:** Implements the **Dart Isolates** pattern for heavy math to ensure 60fps UI.
*   **Assets:** Uses **WebP Lossless** for the LP map as specified.
*   **Structure:** Introduces the `lib/core/engine` and `lib/core/services` directories.

## Detailed Design

### Services and Modules

| Module | Responsibility | Inputs | Outputs | Owner |
| :--- | :--- | :--- | :--- | :--- |
| `AstroEngine` | Core calculations (Alt/Az, Rise/Set) | Date, Location, Object | Coordinates, Times | Backend/Core |
| `DatabaseService` | Local DB access | Query Params | List<Star>, List<DSO> | Backend/Core |
| `IsolateManager` | Offloads math to background threads | CalculationRequest | CalculationResult | Core |
| `LightPollutionService` | Hybrid LP data fetching | Lat/Long | Bortle Class | Core |
| `WeatherService` | Fetch weather data | Lat/Long | Cloud Cover, Seeing | Core |

### Data Models and Contracts

**Entity: `Star`**
```dart
class Star {
  final int id;
  final int hipId;
  final double ra;
  final double dec;
  final double mag;
  final String name;
  final String constellation;
  // ...
}
```

**Entity: `DSO`**
```dart
class DSO {
  final int id;
  final String messierId;
  final String type;
  final double ra;
  final double dec;
  final double mag;
  // ...
}
```

**Interface: `IAstroEngine`**
```dart
abstract class IAstroEngine {
  Future<Result<EquatorialCoordinates>> calculatePosition(CelestialObject obj, Location loc, DateTime time);
  Future<Result<RiseSetTimes>> calculateRiseSet(CelestialObject obj, Location loc, DateTime date);
}
```

### APIs and Interfaces

*   **Light Pollution API:** `GET /api/light-pollution?lat={lat}&lon={lon}`
*   **Weather API:** `GET /api/weather?lat={lat}&lon={lon}`

### Workflows and Sequencing

1.  **Engine Initialization:**
    *   App Start -> `DatabaseService` initializes SQLite -> `IsolateManager` spawns worker -> `AstroEngine` ready.
2.  **Calculation Flow:**
    *   UI Request -> `AstroEngine` -> `IsolateManager` -> Worker Thread (Meeus Algo) -> Result -> UI.
3.  **LP Fallback:**
    *   Request LP -> Check Connectivity -> (If Online) Call API -> (If Fail/Offline) Load `world_lp.webp` -> Map Lat/Long to Pixel -> Read Color -> Return Bortle.

## Non-Functional Requirements

### Performance
*   **Calculation Latency:** Single object position < 5ms (Main Thread) or < 50ms (Isolate roundtrip).
*   **Database Query:** Star search < 100ms.
*   **App Size:** Total bundle increase < 20MB (DB + WebP).

### Security
*   **Data Privacy:** User location never persisted on backend.
*   **API Security:** HTTPS for all external calls.

### Reliability/Availability
*   **Offline Parity:** 100% of calculation features available offline.
*   **Fallback Consistency:** Offline LP data matches Online API > 90% of the time.

### Observability
*   **Error Tracking:** Capture Isolate errors and DB failures in Crashlytics.
*   **Logs:** Log fallback activations (e.g., "Switched to Offline LP").

## Dependencies and Integrations

*   `sqflite`: Local Database.
*   `path_provider`: File system access.
*   `http`: Network requests.
*   `image`: Pixel reading for LP map (if needed for raw byte access).
*   `flutter_isolate` (or native `Isolate` API): Concurrency.

## Acceptance Criteria (Authoritative)

1.  **Engine Accuracy:** `calculatePosition()` returns Alt/Az within 1 degree of Stellarium.
2.  **Rise/Set Accuracy:** Rise/Set times are within 2 minutes of verified sources.
3.  **Offline DB:** Searching "Andromeda" offline returns correct DSO data from SQLite.
4.  **LP Hybrid:** Disconnecting internet and updating location returns valid Bortle data from WebP map.
5.  **Weather:** Weather fetch succeeds on physical iOS/Android devices.
6.  **Performance:** UI does not freeze during heavy star catalog loading/calculation.

## Traceability Mapping

| AC ID | Description | Spec Section | Component | Test Idea |
| :--- | :--- | :--- | :--- | :--- |
| AC1 | Engine Accuracy | Detailed Design | `AstroEngine` | Unit Test vs Gold Standard CSV |
| AC2 | Rise/Set Accuracy | Detailed Design | `AstroEngine` | Unit Test vs Gold Standard CSV |
| AC3 | Offline DB | Data Models | `DatabaseService` | Integration Test (Mock Offline) |
| AC4 | LP Hybrid | Workflows | `LightPollutionService` | Manual Test (Airplane Mode) |
| AC5 | Weather | Services | `WeatherService` | Device Test |
| AC6 | Performance | NFR/Performance | `IsolateManager` | Profiling/Frame Timing |

## Risks, Assumptions, Open Questions

*   **Risk:** Isolate communication overhead might outweigh calculation benefits for single objects.
    *   *Mitigation:* Batch calculations where possible.
*   **Assumption:** `world_lp.webp` projection matches the coordinate mapping logic.
*   **Question:** Do we need a specific `image` library for pixel reading, or can we use `dart:ui`?

## Test Strategy Summary

*   **Unit Tests:** Extensive testing of `AstroEngine` algorithms against a "Gold Standard" dataset (generated from `sweph` or Stellarium).
*   **Integration Tests:** Verify SQLite DB loading and querying.
*   **Manual Verification:** Test LP fallback by toggling network. Verify Weather on physical devices.
