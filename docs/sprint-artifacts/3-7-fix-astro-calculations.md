# Story 3.7: Fix Astro Calculations

Status: review

## Story

As a user,
I want the stars and constellations to appear in their correct positions for my location,
so that I can reliably use the app for real-world observing and navigation.

## Acceptance Criteria

1. **Accuracy Verification:**
   - **Given** a specific location (e.g., Delhi, London) and time, **When** the app displays Alt/Az for known bright stars (Sirius, Arcturus, Polaris), **Then** the values must match trusted reference data (Stellarium, SkySafari, or NOAA calculators) within 1 degree.

2. **Fix Coordinate Conversion:**
   - Identify and fix inaccuracies in the `Local Sidereal Time (LST)` calculation or the `RA/Dec` to `Alt/Az` conversion algorithm in the Dart Engine.
   - **Verification:** Ensure correct handling of Time Zones and Daylight Savings Time (major source of LST errors).

3. **Constellation Lines:**
   - **Given** correct star positions, **When** constellation lines are drawn, **Then** they must connect the correct stars without distortion/mirroring (verifying specific projection logic).

## Tasks / Subtasks

- [x] Audit Time Calculation
  - [x] Verify `Julian Date` calculation.
  - [x] Verify `Local Sidereal Time (LST)` formula, specifically handling of longitude direction (+/- for East/West).
- [x] Audit Coordinate Conversion
  - [x] Verify `EqToHoriz` (Equatorial to Horizon) transformation matrix.
  - [x] Check for Radians vs Degrees mix-ups.
- [x] Create Test Harness
  - [x] Create a unit test with known "Gold Standard" inputs/outputs (e.g., Position of Sirius at 2024-01-01 00:00 UTC at 0,0 Lat/Long).
- [x] Fix Logic & Verify

## Dev Notes

- **Architecture:** Core Engine (`core/engine/algorithms`).
- **Critical:** This is a correctness bug. The app is unusable for science without this.
- **Reference:** Meeus "Astronomical Algorithms" (Chapter 13: Transformation of Coordinates).
- **Potential Pitfall:** Flutter's `Canvas` system often uses an inverted Y-axis (0 at top). Ensure the projection logic accounts for this if the error is visual vs mathematical.

### Context Reference

- [Context XML](3-7-fix-astro-calculations.context.xml)

### References

- [Source: docs/epics.md#Story 1.1](#story-11-dart-native-engine-implementation) - Relates to the original engine implementation.

---

## Senior Developer Review (AI)

**Reviewer:** Vansh  
**Date:** 2025-12-09  
**Outcome:** ⚠️ **CHANGES REQUESTED**

### Summary

The core astronomy algorithms are **well-implemented and architecturally sound**. All 41 unit tests pass, covering Julian Date, GMST, LST, and coordinate transformations. Gold standard tests for Sirius and Polaris exist and verify accuracy within AC tolerances. However, the **story tasks are not marked complete**, and **AC #1 requires external validation** against Stellarium/SkySafari that has not been documented. AC #3 (constellation lines) lacks test coverage.

---

### Acceptance Criteria Coverage

| AC# | Description | Status | Evidence |
|-----|------------|--------|----------|
| AC 1 | Accuracy within 1° for Sirius, Arcturus, Polaris | **PARTIAL** | Gold standard tests exist for Sirius & Polaris (`coordinate_transformations_test.dart:9-42`, `203-234`). No test for Arcturus. No documented comparison to Stellarium/SkySafari. |
| AC 2 | Fix LST and RA/Dec→Alt/Az conversion | **IMPLEMENTED** | `time_utils.dart:84-120` (GMST/LST), `coordinate_transformations.dart:18-61` (EqToHoriz). Tests verify Meeus formulas. Timezone handled via UTC conversion (`time_utils.dart:14`). |
| AC 3 | Constellation lines connect correct stars | **NOT VERIFIED** | No tests or evidence for constellation line rendering logic. This is a UI/projection concern not addressed in algorithm tests. |

**Summary:** 1 of 3 ACs fully verified, 1 partial, 1 not verified.

---

### Task Completion Validation

| Task | Marked As | Verified As | Evidence |
|------|-----------|-------------|----------|
| Audit Time Calculation | `[ ]` (Incomplete) | **DONE** | `time_utils_test.dart:7-93` covers JD and LST |
| Verify Julian Date | `[ ]` (Incomplete) | **DONE** | `time_utils_test.dart:7-33` |
| Verify LST formula | `[ ]` (Incomplete) | **DONE** | `time_utils_test.dart:74-114`, longitude correctly added |
| Audit Coordinate Conversion | `[ ]` (Incomplete) | **DONE** | `coordinate_transformations_test.dart:8-96` |
| Verify EqToHoriz | `[ ]` (Incomplete) | **DONE** | `coordinate_transformations_test.dart:8-96`, Sirius gold standard |
| Check Radians vs Degrees | `[ ]` (Incomplete) | **DONE** | `time_utils.dart:141-149` (conversions), `coordinate_transformations.dart:32-34` (consistent usage) |
| Create Test Harness | `[ ]` (Incomplete) | **DONE** | `coordinate_transformations_test.dart:9` "Gold Standard" test exists |
| Fix Logic & Verify | `[ ]` (Incomplete) | **QUESTIONABLE** | Tests pass, but no changelog documenting what was "fixed" |

**Summary:** 7 of 8 tasks verified complete but NOT MARKED. Task boxes need updating.

---

### Test Coverage and Gaps

**Covered:**
- ✅ Julian Date calculation (edge cases, J2000.0, round-trip)
- ✅ GMST calculation (Meeus Example 12.a verification)
- ✅ LST calculation (East/West longitude handling)
- ✅ Equatorial to Horizontal conversion (Sirius, Polaris, zenith objects)
- ✅ Rise/Set calculations

**Gaps:**
- ❌ No test for **Arcturus** (mentioned in AC #1)
- ❌ No test for **Delhi or London locations** (mentioned in AC #1)
- ❌ No constellation line rendering tests (AC #3)
- ❌ No documented comparison with **Stellarium/SkySafari** (AC #1 verification)

---

### Architectural Alignment

✅ **Compliant with Architecture:**
- Pure Dart implementation (no native dependencies for core engine)
- Isolate-ready: algorithms are stateless static methods
- Result pattern not used in algorithms (acceptable for pure math functions)
- File structure matches `core/engine/algorithms/` pattern

---

### Security Notes

No security concerns identified. Calculations are pure math with no external dependencies or user input handling.

---

### Best-Practices and References

- [Meeus "Astronomical Algorithms" Ch. 7 (JD), Ch. 12 (Sidereal Time), Ch. 13 (Coordinate Transformation)](https://www.willbell.com/math/mc1.htm)
- [Stellarium](https://stellarium.org/) - Recommended for AC #1 validation
- [NOAA Solar Calculator](https://gml.noaa.gov/grad/solcalc/) - Alternative validation source

---

### Action Items

**Code Changes Required:**
- [ ] [Med] Add gold standard test for **Arcturus** (AC #1) [file: test/core/engine/algorithms/coordinate_transformations_test.dart]
- [ ] [Med] Add test cases for **Delhi (28.6139°N, 77.2090°E)** and **London (51.5074°N, 0.1278°W)** locations (AC #1) [file: test/core/engine/algorithms/coordinate_transformations_test.dart]
- [ ] [High] Document external validation results against Stellarium/SkySafari in story file or Dev Notes (AC #1 verification)
- [ ] [Med] Add or reference constellation line rendering tests (AC #3) [file: test/ui/ or test/features/]
- [ ] [Low] Update task checkboxes to `[x]` for completed tasks [file: docs/sprint-artifacts/3-7-fix-astro-calculations.md]

**Advisory Notes:**
- Note: Consider adding a "Fix Logic" section to Dev Notes documenting what was changed (if anything)
- Note: The existing tests demonstrate the algorithm is correct; formal validation against external sources would strengthen confidence

---

## Change Log

| Date | Version | Description |
|------|---------|-------------|
| 2025-12-09 | 1.1 | Senior Developer Review notes appended |
