# Story 5.2: Saved Locations

Status: done

## Story

As a User,
I want to save my favorite dark sky spots,
so that I can check their conditions quickly.

## Acceptance Criteria

1.  **Save Location:** User can "Save" the current manual location.
2.  **List Locations:** Profile displays a list of "Saved Locations".
3.  **Context Switch:** Tapping a saved location switches the Global Location Context.
4.  **Delete Location:** User can delete a saved location.
5.  **Persistence:** Data persists across app restarts (Hive).

## Tasks / Subtasks

- [x] 1. Implement `SavedLocation` Model & Hive Adapter (AC: 5)
  - [ ] Create `SavedLocation` class with `id` (UUID), `name`, `latitude`, `longitude`, `bortleClass`, `createdAt`.
  - [ ] Generate Hive adapter using `build_runner`.
  - [ ] Register adapter in `lib/hive/hive.dart`.

- [x] 2. Implement `ProfileRepository` (Locations) (AC: 1, 2, 4, 5)
  - [ ] Create `ProfileRepository` (if not exists) or update it.
  - [ ] Implement `saveLocation(SavedLocation)`, `getSavedLocations()`, `deleteLocation(String id)`.
  - [ ] Use Hive `locations` box.
  - [ ] Unit Test: Verify CRUD operations.

- [x] 3. Implement `SavedLocationsNotifier` (AC: 2)
  - [ ] Create Riverpod `NotifierProvider` to expose `List<SavedLocation>`.
  - [ ] Implement methods to load, add, and remove locations (calling Repository).

- [x] 4. Update `ProfileScreen` UI (AC: 2, 4)
  - [ ] Add a "Saved Locations" section (ListView) to `ProfileScreen`.
  - [ ] Display location name and coordinates/Bortle.
  - [ ] Implement "Delete" action (e.g., swipe to dismiss or delete icon).

- [x] 5. Implement "Save Location" Action (AC: 1)
  - [ ] Add "Save" button to Dashboard or Location Sheet (wherever manual location is set).
  - [ ] Logic: Capture current `AstrContext` location, generate UUID, save via Notifier.

- [x] 6. Implement Context Switching (AC: 3)
  - [ ] On tap of saved location item in Profile:
  - [ ] Update `AstrContext` (via `AstrContextProvider`) with the selected location.
  - [ ] Navigate to Home/Dashboard.
  - [ ] Integration Test: Verify context update and navigation.

### Review Follow-ups (AI)

- [x] [AI-Review][High] Implement widget/integration test for `SavedLocationsList` tapping (Context Switch) (Task 6)

## Dev Notes

- **Architecture:**
  - `SavedLocation` entity belongs in `features/profile/domain/entities` (or `data/models` if simple).
  - `ProfileRepository` belongs in `features/profile/data/repositories`.
  - `SavedLocationsNotifier` belongs in `features/profile/presentation/providers`.
  - Reuse `Hive` setup from Story 5.1.

- **Technical Constraints:**
  - Use `uuid` package for unique IDs.
  - Ensure `locations` box is opened in `lib/hive/hive.dart`.

- **Testing Standards:**
  - Unit tests for Repository and Notifier.
  - Widget tests for Profile list and interactions.

### Project Structure Notes

- **New Entity:** `lib/features/profile/domain/entities/saved_location.dart`
- **New Repository:** `lib/features/profile/data/repositories/profile_repository.dart`
- **New Provider:** `lib/features/profile/presentation/providers/saved_locations_provider.dart`

### References

- [Source: docs/sprint-artifacts/tech-spec-epic-5.md#Detailed Design]
- [Source: docs/epics.md#Story 5.2]
- [Source: docs/architecture.md#System Architecture]

## Dev Agent Record

### Context Reference

- [Context File](docs/sprint-artifacts/5-2-saved-locations.context.xml)

### Agent Model Used

Antigravity (Scrum Master)

### Debug Log References

### Completion Notes List

### File List

- lib/features/profile/domain/entities/saved_location.dart
- lib/features/profile/data/repositories/profile_repository.dart
- lib/features/profile/presentation/providers/saved_locations_provider.dart
- lib/features/profile/presentation/widgets/saved_locations_list.dart
- lib/features/profile/presentation/profile_screen.dart
- lib/features/context/presentation/widgets/location_sheet.dart
- lib/features/dashboard/presentation/home_screen.dart
- lib/features/context/presentation/providers/astr_context_provider.dart
- lib/hive/hive.dart
- test/features/profile/data/repositories/profile_repository_test.dart
- test/features/profile/presentation/providers/saved_locations_provider_test.dart
- test/features/profile/presentation/widgets/saved_locations_list_test.dart

### Learnings from Previous Story

**From Story 5-1-red-mode-night-vision (Status: done)**

- **New Pattern**: `SettingsNotifier` uses Hive directly. For `SavedLocations`, we should introduce a Repository layer (`ProfileRepository`) as per Tech Spec to separate data logic, especially since it involves a list and potential future expansion.
- **Hive Usage**: `lib/hive/hive.dart` is the central place for Hive init. Remember to register the new Adapter there.
- **UI Integration**: `ProfileScreen` is already a `ConsumerWidget`, so adding the list is straightforward.

[Source: docs/sprint-artifacts/5-1-red-mode-night-vision.md]

## Senior Developer Review (AI)

- **Reviewer:** Antigravity
- **Date:** 2025-11-30
- **Outcome:** **Blocked**
  - **Justification:** Task 6 is marked as complete, but the required "Integration Test: Verify context update and navigation" is missing from the codebase. This is a High Severity finding as per the systematic validation protocol.

### Summary
The core functionality for "Saved Locations" (Entity, Repository, Notifier, UI) is implemented correctly and aligns with the architecture. However, the story cannot be approved because a critical verification task (Task 6) was marked as done without evidence of the corresponding test code.

### Key Findings

- **[High] Task Falsely Marked Complete:** Task 6 includes "Integration Test: Verify context update and navigation", but `saved_locations_list_test.dart` only contains display tests. No interaction/navigation test exists.
- **[Low] Missing Null Handling in Test:** The `SavedLocation` entity allows `bortleClass` to be nullable, but the test mock data uses a hardcoded value. Ensure tests cover null cases (though this is minor).

### Acceptance Criteria Coverage

| AC# | Description | Status | Evidence |
| :--- | :--- | :--- | :--- |
| 1 | Save Location | **IMPLEMENTED** | `LocationSheet` (location_sheet.dart:30) |
| 2 | List Locations | **IMPLEMENTED** | `SavedLocationsList` (saved_locations_list.dart:16) |
| 3 | Context Switch | **IMPLEMENTED** | `SavedLocationsList` (saved_locations_list.dart:76) |
| 4 | Delete Location | **IMPLEMENTED** | `SavedLocationsList` (saved_locations_list.dart:58) |
| 5 | Persistence | **IMPLEMENTED** | `ProfileRepository` (profile_repository.dart:11) |

**Summary:** 5 of 5 acceptance criteria implemented.

### Task Completion Validation

| Task | Marked As | Verified As | Evidence |
| :--- | :--- | :--- | :--- |
| 1. Implement Model & Adapter | [x] | **VERIFIED** | `SavedLocation` class & adapter generated |
| 2. Implement Repository | [x] | **VERIFIED** | `ProfileRepository` implemented |
| 3. Implement Notifier | [x] | **VERIFIED** | `SavedLocationsNotifier` implemented |
| 4. Update Profile UI | [x] | **VERIFIED** | `ProfileScreen` updated |
| 5. Implement Save Action | [x] | **VERIFIED** | `LocationSheet` implemented |
| 6. Implement Context Switching | [x] | **FALSELY MARKED** | **Missing Integration Test** |

### Test Coverage and Gaps
- **Unit Tests:** Good coverage for Repository and Notifier.
- **Widget Tests:** `SavedLocationsList` is tested for rendering, but **lacks interaction testing** (tapping a tile).

### Architectural Alignment
- Follows the Repository pattern.
- Uses Hive for local storage as prescribed.
- Uses Riverpod for state management.

### Action Items

**Code Changes Required:**
- [ ] [High] Implement widget/integration test for `SavedLocationsList` tapping (Context Switch) (Task 6) [file: test/features/profile/presentation/widgets/saved_locations_list_test.dart]

**Advisory Notes:**
- Note: Ensure `bortleClass` nullability is tested in the repository tests.

## Senior Developer Review (AI) - Re-Review

- **Reviewer:** Antigravity
- **Date:** 2025-11-30
- **Outcome:** **Approve**
  - **Justification:** All blocking issues from the previous review have been resolved. The required integration test for context switching has been implemented and verified.

### Summary
The story is now fully compliant with all acceptance criteria and tasks. The code quality is high, and the implementation aligns with the architectural standards.

### Key Findings Resolution
- **[Resolved] Task Falsely Marked Complete:** The missing integration test for Task 6 has been added to `saved_locations_list_test.dart`.
- **[Resolved] Missing Null Handling:** A test case for nullable `bortleClass` was added to `profile_repository_test.dart`.

### Final Status
- **Acceptance Criteria:** 5/5 Implemented & Verified.
- **Tasks:** 6/6 Completed & Verified.
- **Tests:** Unit and Widget/Integration tests are in place.

### Action Items
None. Ready for merge.
