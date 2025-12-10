# Astronomy Engine Research

**Date**: 2025-12-01
**Status**: Approved
**Author**: Antigravity

## Objective
Select the best library or method for calculating high-precision celestial coordinates (Altitude, Azimuth, Rise/Set/Transit) within the Astr Flutter app.

## Requirements
1.  **Accuracy**: Must match professional standards (e.g., Stellarium, JPL Horizons).
2.  **Offline Capability**: Must work without internet.
3.  **Performance**: Must be fast enough for real-time graph rendering (hundreds of calculations per frame/second).
4.  **Platform Support**: iOS and Android (Flutter).
5.  **License**: Compatible with our project (Open Source / Permissive).

## Options Evaluated

### 1. `sweph` (Swiss Ephemeris)
-   **Description**: A Dart FFI wrapper around the C implementation of the Swiss Ephemeris (standard in astrology/astronomy).
-   **Pros**:
    -   **Gold Standard Accuracy**: Used by professionals.
    -   **Comprehensive**: Planets, Moon, Stars, Asteroids.
    -   **Performance**: C-based, very fast.
-   **Cons**:
    -   **Setup**: Requires asset management for ephemeris files (`.se1`).
    -   **Size**: Ephemeris files add to app size (though minimal for basic planets).
-   **Verdict**: **Strong Candidate**.

### 2. `calc` (Pure Dart)
-   **Description**: A pure Dart port of astronomical algorithms (e.g., Meeus).
-   **Pros**:
    -   **Pure Dart**: No native code, easy build.
    -   **Lightweight**: No assets.
-   **Cons**:
    -   **Accuracy**: Lower than Swiss Ephemeris (often "low precision" variants).
    -   **Maintenance**: Less active, potentially buggy.
-   **Verdict**: Rejected (Accuracy concerns).

### 3. `hrk_nasa_apis`
-   **Description**: Wrapper for NASA APIs (SSD/Horizons).
-   **Pros**:
    -   **Accuracy**: Perfect (Source of Truth).
-   **Cons**:
    -   **Online Only**: Fails requirement #2.
    -   **Latency**: Too slow for graphs.
-   **Verdict**: Rejected.

## Decision
**Selected: `sweph` (Swiss Ephemeris)**

### Rationale
`sweph` provides the best balance of accuracy and performance. The offline requirement is critical for field use. The Dart wrapper (`sweph` package) is well-maintained and supports Flutter assets.

## Implementation Plan
1.  Add `sweph` to `pubspec.yaml`.
2.  Download essential ephemeris files (`seas_18.se1`, `semmo_18.se1`, `sele18.se1`) and place in `assets/ephe/`.
3.  Initialize `sweph` in `main.dart` using `Sweph.init`.
4.  Create `AstronomyService` to wrap `sweph` calls for easier consumption.
