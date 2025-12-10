# Epic Technical Specification: Profile & Personalization

Date: 2025-11-30
Author: Bob (Scrum Master)
Epic ID: epic-5
Status: Draft

---

## Overview

Epic 5 focuses on "Profile & Personalization," enabling users to customize their Astr experience and protecting their safety during stargazing. The core features are **Red Mode**, a global night-vision protection filter, and **Saved Locations**, allowing users to persist their favorite dark-sky spots. This epic transforms the app from a transient utility into a personalized tool.

## Objectives and Scope

**In-Scope:**
*   **Red Mode (Night Vision):** A global, persistent red overlay to preserve dark adaptation.
*   **Saved Locations:** Local persistence of user-selected locations using Hive.
*   **Profile Screen:** A dedicated UI for managing settings and saved data.
*   **Settings:** Toggle for Metric/Imperial units (FR13).

**Out-of-Scope:**
*   User Authentication / Cloud Sync (Post-MVP).
*   Social Sharing of locations.
*   "Best Nearby Spots" recommendations (Future).

## System Architecture Alignment

This epic leverages the existing **Hive** local storage infrastructure defined in the Architecture Document.
*   **Storage:** Uses `hive` boxes `settings` and `locations` for offline-first persistence.
*   **State Management:** Uses **Riverpod** (`NotifierProvider`) to manage global `RedMode` and `SavedLocations` state.
*   **UI Layer:** "Red Mode" will be implemented at the root level (e.g., wrapping `MaterialApp` or `Scaffold` in `AppShell`) to ensure it applies to *all* screens, including dialogs and navigation transitions.

## Detailed Design

### Services and Modules

| Module | Responsibility | Owner |
| :--- | :--- | :--- |
| `features/profile/data` | Hive adapters and repositories for Settings and Locations. | `ProfileRepository` |
| `features/profile/presentation` | Profile Screen UI, Settings Toggles. | `ProfileScreen` |
| `core/providers` | Global state for Red Mode and Unit preferences. | `SettingsNotifier` |
| `core/widgets` | The `RedModeOverlay` widget. | `AppShell` |

### Data Models and Contracts

**Hive Entity: `SavedLocation`**
```dart
@HiveType(typeId: 1)
class SavedLocation {
  @HiveField(0)
  final String id; // UUID
  @HiveField(1)
  final String name;
  @HiveField(2)
  final double latitude;
  @HiveField(3)
  final double longitude;
  @HiveField(4)
  final double? bortleClass;
  @HiveField(5)
  final DateTime createdAt;
}
```

**Hive Entity: `AppSettings`** (Key-Value pairs in `settings` box)
*   `red_mode_enabled` (bool)
*   `units_system` (enum: metric, imperial)
*   `terms_accepted` (bool)

### APIs and Interfaces

*   `ProfileRepository`:
    *   `Future<void> saveLocation(SavedLocation location)`
    *   `Future<List<SavedLocation>> getSavedLocations()`
    *   `Future<void> deleteLocation(String id)`
    *   `Future<void> setRedMode(bool enabled)`
    *   `bool get isRedMode`

### Workflows and Sequencing

1.  **Toggle Red Mode:** User taps "Red Mode" in Profile -> `SettingsNotifier` updates state -> `AppShell` rebuilds -> `ColorFiltered` (or similar) overlay applies red tint globally.
2.  **Save Location:** User is on Dashboard -> Taps "Save Location" (or via Location Sheet) -> `ProfileRepository` writes to Hive -> `SavedLocationsNotifier` updates list -> UI reflects "Saved" state.

## Non-Functional Requirements

### Performance

*   **Red Mode Transition:** Instant (< 100ms) with no lag.
*   **Storage:** Hive reads/writes must be non-blocking (async).

### Security

*   **Data Privacy:** All location data is stored locally on the device. No data is sent to the cloud (since Auth is out of scope).

### Reliability/Availability

*   **Persistence:** Settings must survive app restarts.

### Observability

*   Log errors if Hive initialization fails.

## Dependencies and Integrations

*   **hive_ce / hive_ce_flutter:** For local storage.
*   **flutter_riverpod:** For state management.
*   **uuid:** For generating unique IDs for saved locations.

## Acceptance Criteria (Authoritative)

1.  **Red Mode (Night Vision):**
    *   [ ] Toggle button available in Profile.
    *   [ ] When active, a pure red (`#FF0000`) overlay is applied to the entire app.
    *   [ ] Overlay persists across navigation and app restarts.
    *   [ ] Text and UI elements remain legible under the filter.
2.  **Saved Locations:**
    *   [ ] User can "Save" the current location.
    *   [ ] Profile displays a list of "Saved Locations".
    *   [ ] Tapping a saved location switches the Global Location Context.
    *   [ ] User can delete a saved location.
    *   [ ] Data persists across app restarts (Hive).
3.  **Unit Settings:**
    *   [ ] Toggle for Metric/Imperial units.
    *   [ ] App displays units accordingly (e.g., km vs miles).

## Traceability Mapping

| AC ID | Spec Section | Component | Test Idea |
| :--- | :--- | :--- | :--- |
| AC1.1 | Detailed Design | `ProfileScreen` | Widget Test: Tap toggle, verify state change. |
| AC1.2 | System Arch | `AppShell` | Manual/Golden Test: Verify screen is red. |
| AC2.1 | Detailed Design | `ProfileRepository` | Unit Test: Save item, retrieve item. |
| AC2.2 | Detailed Design | `ProfileScreen` | Widget Test: List renders items. |
| AC2.3 | Detailed Design | `AstrContext` | Integration Test: Tap item -> Context updates. |

## Risks, Assumptions, Open Questions

*   **Risk:** Red Mode might make some UI elements (like blue/green graphs) invisible if not carefully blended.
    *   *Mitigation:* Use `ColorFilter.mode(Colors.red, BlendMode.multiply)` or similar, but test contrast.
*   **Assumption:** Hive is already initialized in `main.dart`.

## Test Strategy Summary

*   **Unit Tests:** `ProfileRepository` (Hive CRUD), `SettingsNotifier`.
*   **Widget Tests:** `ProfileScreen` interaction.
*   **Manual:** Verify Red Mode effectiveness in a dark room.
