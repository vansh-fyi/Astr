# Story 9.0: Astronomy Engine & Math Research

**Epic**: 9 - Astronomy Engine & Data Integration
**Status**: done
**Priority**: High

## User Story
As a Developer, I want to verify the mathematical formulas and libraries for celestial calculations, so that we don't implement incorrect physics.

## Acceptance Criteria

### AC 1: Research Deliverable
- [x] **Document**: Create `docs/astronomy-engine-research.md`.
- [x] **Comparison**: Evaluate `swisseph` vs `calc` vs `hrk_nasa_apis`.
- [x] **Decision**: Select the best library for offline, high-precision calculations.

### AC 2: Formula Definition
- [x] **Algorithms**: Define approach for Rise/Set, Altitude/Azimuth.
- [x] **Data Mapping**: Map Open-Meteo fields to UI requirements.

## Technical Implementation Tasks
- [x] Research available Dart packages for astronomy.
- [x] Verify `sweph` (Swiss Ephemeris) capabilities and asset requirements.
- [x] Write research document.

## Senior Developer Review (AI)
- **Reviewer**: Antigravity
- **Date**: 2025-12-01
- **Outcome**: Approve

### Summary
Research complete. `sweph` selected as the engine. Document created at `docs/astronomy-engine-research.md`.
