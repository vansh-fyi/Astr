# Story 8.4: Math Documentation & Validation

> **Status:** done
> **Epic:** 8 - Calculation Accuracy & Math Transparency

## Story

**As a** Developer,
**I want** all formulas documented and validated,
**So that** I can verify accuracy and debug issues.

## Acceptance Criteria

1.  **Documentation**
    *   Create `/docs/calculations.md` with all astronomy formulas.
    *   Each formula includes:
        *   Mathematical notation
        *   Code implementation reference (file + line)
        *   Authoritative source (Stellarium, JPL, academic paper)

2.  **Validation**
    *   Unit tests compare outputs to known reference values.
    *   Tests cover:
        *   Pickering Scale (Seeing)
        *   r^6 Darkness Calculation
        *   Moon Phase (if applicable)

## Tasks

- [ ] **Task 1: Documentation** (AC: #1)
    - [ ] 1.1: Create `docs/calculations.md`.
    - [ ] 1.2: Document Seeing calculation (Pickering).
    - [ ] 1.3: Document Darkness calculation (r^6).
    - [ ] 1.4: Document Moon Phase calculation (if present).

- [ ] **Task 2: Validation Tests** (AC: #2)
    - [ ] 2.1: Verify/Add unit tests for `SeeingCalculator`.
    - [ ] 2.2: Verify/Add unit tests for `DarknessCalculator` (or equivalent).
    - [ ] 2.3: Ensure tests reference specific "truth" values (e.g., from Stellarium).

## Dev Notes

### Learnings from Previous Story (8.3)

**From Story 8.3 (Status: done)**

-   **Data Sources**: We are using Open-Meteo for raw data (humidity, temp, cloud cover).
-   **Calculations**: Seeing and Darkness calculations are currently embedded in repositories or services. This story aims to centralize the *knowledge* of these formulas, even if the code remains distributed.
-   **Testing**: We have some unit tests, but this story enforces a higher standard of "truth" verification against authoritative sources.

### Architecture Context

-   **Files**:
    -   `lib/core/services/seeing_calculator.dart`
    -   `lib/features/dashboard/data/repositories/light_pollution_repository.dart` (or wherever r^6 is)
    -   `docs/calculations.md` (NEW)

### References

-   [Source: docs/epics.md#Story 8.4]

## Dev Agent Record

### Context Reference

- `docs/sprint-artifacts/story-8-4-math-documentation-validation.context.xml`
