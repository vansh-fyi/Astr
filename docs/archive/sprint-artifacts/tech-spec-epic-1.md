# Technical Specification: Epic 1 - Foundation & Core Data Engine

> **Epic ID:** 1
> **Title:** Foundation & Core Data Engine
> **Author:** Vansh & SM Agent
> **Status:** Draft
> **Date:** 2025-11-29

## 1. Overview
This epic establishes the fundamental "skeleton" of the Astr application. It includes setting up the Flutter project with the chosen Clean Architecture template, implementing the navigation shell (GoRouter), and integrating the critical "Astronomy Engine" (Swiss Ephemeris via Dart) that powers all future features. It also handles the global "Context" (Location + Date) that drives the app's data.

### Objectives
*   Initialize the Flutter project using `Erengun/Flutter-Riverpod-Quickstart-Template`.
*   Implement the persistent Bottom Navigation Bar with "Glassmorphism" styling.
*   Integrate `swisseph` (or Dart equivalent) for offline astronomical calculations.
*   Create a global `ContextManager` (Riverpod) to manage Location and Date state.

### Scope
*   **In-Scope:** Project setup, Navigation Shell, Theme implementation, Swiss Ephemeris integration, Location/Date state management.
*   **Out-of-Scope:** UI for Dashboard, Catalog, or Profile (placeholders only). Weather API integration (Epic 2).

## 2. Detailed Design

### 2.1 Services & Modules

| Module | Responsibility | Key Inputs | Key Outputs |
| :--- | :--- | :--- | :--- |
| **AppShell** | Main UI container, Bottom Nav, Routing. | User Tap | Active Screen |
| **AstroEngine** | Core calculation service. | Time, Lat, Long | Altitude, Azimuth, Phase |
| **ContextManager** | Global state for "Where & When". | GPS, Date Picker | `AstrContext` object |
| **LocationService** | Hardware GPS access. | Permission | `Position` (Lat/Long) |

### 2.2 Data Models

#### `AstrContext` (Immutable State)
```dart
class AstrContext {
  final DateTime selectedDate;
  final GeoLocation location;
  final bool isCurrentLocation; // True if using GPS, False if manual
}
```

#### `GeoLocation`
```dart
class GeoLocation {
  final double latitude;
  final double longitude;
  final String? name; // Optional, e.g., "Joshua Tree"
}
```

#### `CelestialPosition` (Engine Output)
```dart
class CelestialPosition {
  final CelestialBody body; // Enum: Sun, Moon, Planet...
  final double altitude;
  final double azimuth;
  final double distance;
  final double magnitude;
}
```

### 2.3 API & Interfaces

#### `IAstroEngine` (Repository Interface)
```dart
abstract class IAstroEngine {
  Future<Either<Failure, CelestialPosition>> getPosition({
    required CelestialBody body,
    required DateTime time,
    required GeoLocation location,
  });
}
```

### 2.4 Navigation Structure (GoRouter)
*   `/` -> `HomeRoute` (Dashboard)
*   `/catalog` -> `CatalogRoute`
*   `/forecast` -> `ForecastRoute`
*   `/profile` -> `ProfileRoute`
*   **ShellRoute:** Wraps all above routes with the `Scaffold` containing the BottomNavBar.

## 3. Non-Functional Requirements

### 3.1 Performance
*   **App Launch:** < 2 seconds to interactive shell.
*   **Calculation:** Ephemeris calculations must take < 50ms per object to ensure smooth UI updates.

### 3.2 Security
*   **Location:** Request `WhenInUse` permission only. Handle "Denied" gracefully (Default to Null Island or user prompt).

### 3.3 Reliability
*   **Offline:** The `AstroEngine` MUST work 100% offline. No API calls for star positions.

## 4. Dependencies

*   `flutter_riverpod`: State Management.
*   `go_router`: Navigation.
*   `swisseph` (or `sweph`): Astronomy calculations.
*   `geolocator`: GPS access.
*   `fpdart`: Functional error handling (`Either<L, R>`).
*   `flex_color_scheme`: Theming.
*   `logger`: Structured logging.

## 5. Acceptance Criteria & Traceability

| AC ID | Description | Source Story | Component | Test Idea |
| :--- | :--- | :--- | :--- | :--- |
| **AC-1.1.1** | App launches to "Home" tab by default. | Story 1.1 | `AppRouter` | Launch app, verify Home widget is visible. |
| **AC-1.1.2** | Bottom Nav persists across all tabs. | Story 1.1 | `ScaffoldWithNavBar` | Switch tabs, verify Nav Bar remains. |
| **AC-1.1.3** | UI uses "Deep Cosmos" background (`#020204`). | Story 1.1 | `AppTheme` | Screenshot test / Visual inspection. |
| **AC-1.2.1** | Engine returns valid Altitude/Azimuth for Sun/Moon. | Story 1.2 | `AstroEngine` | Unit test: Compare output with Stellarium data for known time/loc. |
| **AC-1.2.2** | Calculations work without internet. | Story 1.2 | `AstroEngine` | Run unit tests with network disabled. |
| **AC-1.3.1** | App requests Location Permission on first launch. | Story 1.3 | `LocationService` | Fresh install, verify system permission dialog. |
| **AC-1.3.2** | `AstrContext` defaults to Current Date/Time. | Story 1.3 | `ContextManager` | Verify initial state of provider. |

## 6. Risks & Assumptions

*   **Risk:** `swisseph` Dart bindings might be complex to configure on iOS/Android (C++ FFI).
    *   *Mitigation:* Use a pure Dart port if available (e.g., `dart_periphery` or specific astronomy algo packages) OR ensure FFI build scripts are robust. *Decision: Prefer Pure Dart implementation if accuracy is sufficient to avoid build complexity.*
*   **Assumption:** User grants location permission.
    *   *Fallback:* If denied, app must not crash; default to (0,0) or prompt user.

## 7. Test Strategy

*   **Unit Tests:** Heavy focus on `AstroEngine`. Validate calculations against known data points (e.g., "Where was the Moon on Jan 1, 2024 at Greenwich?").
*   **Widget Tests:** Verify Navigation Shell and Bottom Bar interactions.
*   **Manual:** Verify "Deep Cosmos" theme look-and-feel on actual device.
