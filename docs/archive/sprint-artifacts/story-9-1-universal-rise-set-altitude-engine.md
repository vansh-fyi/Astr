# Story 9.1: Universal Rise/Set & Altitude Engine

**Epic**: 9 - Astronomy Engine & Data Integration
**Status**: done
**Priority**: High

## User Story
As a User, I want accurate Rise, Set, and Transit times for ANY object, so that the "Details" page isn't empty.

## Acceptance Criteria

### AC 1: Astronomy Engine Implementation
- [x] **Class**: Implement `AstronomyService` (Singleton/Provider).
- [x] **Input**: Accept Lat, Long, DateTime, Object Coordinates.
- [x] **Output**: Return Altitude, Azimuth, Rise Time, Set Time, Transit Time.

### AC 2: Swiss Ephemeris Integration
- [x] **Library**: Use `sweph` package.
- [x] **Assets**: Load `.se1` ephemeris files correctly.
- [x] **Offline**: Ensure calculations work without internet.

## Technical Implementation Tasks
- [x] Add `sweph` to `pubspec.yaml`.
- [x] Initialize `Sweph` in `main.dart`.
- [x] Create `AstronomyService` class.
- [x] Implement `calculateCelestialBody` method.
- [x] Implement `calculateMoonPhase` method.

## Senior Developer Review (AI)
- **Reviewer**: Antigravity
- **Date**: 2025-12-01
- **Outcome**: Approve

### Summary
The `AstronomyService` is fully implemented using `sweph`. It powers the entire app's celestial calculations.
