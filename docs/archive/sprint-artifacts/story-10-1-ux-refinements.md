# Story 10.1: UX Refinements

**Epic**: 10 - Production Polish & Launch
**Status**: review
**Priority**: High

## User Story
**As a** User,
**I want** a polished, frustration-free experience,
**So that** I enjoy using the app without annoyances.

## Context
The app is currently functional but lacks key UX polish. Users cannot delete saved locations, location names are just coordinates, and the 24h view is irrelevant for stargazing. This story addresses these specific gaps to make the app feel "production ready".

## Acceptance Criteria

### AC 1: Delete Saved Location
- [ ] **UI**: Add a "Delete" icon or Swipe-to-Delete action in the `LocationsScreen` list.
- [ ] **Logic**: Removing a location updates the Hive storage immediately.
- [ ] **State**: If the *currently selected* location is deleted, fallback to the next available location or current GPS.

### AC 2: Reverse Geocoding (Location Names)
- [ ] **Data**: Fetch city/place name for any selected location (GPS or Manual).
- [ ] **Source**: Use **OpenStreetMap Nominatim API** (Free, requires User-Agent).
- [ ] **Display**: Show "City, Country" (e.g., "London, UK") in the Home Header and Location List instead of "Lat: 51.5, Lon: -0.1".
- [ ] **Caching**: Cache the name with the saved location to avoid repeated API calls.

### AC 3: Night-Only Display Mode
- [ ] **Logic**: Define "Night" as the period from **Sunset** to **Sunrise** (Dusk to Dawn).
- [ ] **Graphs**: Update `VisibilityGraph` and `CloudCoverGraph` to ONLY show the X-axis range for this night period (e.g., 18:00 to 06:00).
- [ ] **Forecast**: Ensure daily forecast summaries focus on the night conditions.
- [ ] **Removal**: Remove any 24h toggles or views; Night-only is the default and only view.

## Technical Implementation Tasks

### Location Management
- [ ] Update `SavedLocationsNotifier` with `deleteLocation(int index)` method.
- [ ] Implement `Dismissible` widget in `LocationsScreen` for swipe-to-delete.

### Reverse Geocoding Service
- [ ] Create `GeocodingService` (using `Dio`).
- [ ] Implement `getPlaceName(double lat, double lon)` calling `https://nominatim.openstreetmap.org/reverse`.
- [ ] **Constraint**: Ensure `User-Agent` header is set to `Astr/1.0` (OSM requirement).
- [ ] Update `GeoLocation` model to include optional `String? placeName`.
- [ ] Update `AstrContextProvider` to fetch name when location changes (if missing).

### Night-Only Logic
- [ ] Refactor `VisibilityGraphPainter` to accept a `TimeRange` (Sunset -> Sunrise).
- [ ] Update `AstronomyEngine` to provide accurate Sunset/Sunrise times for the X-axis bounds.
- [ ] Adjust `ForecastScreen` logic to filter out daylight hours.

## Dependencies
- `dio` (for Nominatim)
- `intl` (for formatting names/times)

## Dev Notes
- **Nominatim Usage Policy**: Maximum 1 request per second. Cache results!
- **Night Definition**: Handle the "cross-midnight" case carefully (e.g., Sunset 18:00 today -> Sunrise 06:00 tomorrow).

## Learnings from Previous Story
**From Story 9.4 (Status: review)**
- **Reuse**: `SavedLocationsNotifier` exists; extend it, don't rewrite.
- **Pattern**: `AstrContextProvider` is the global location source.

## Dev Agent Record
- **Context Reference**: [Context File](story-10-1-ux-refinements.context.xml)

## Senior Developer Review (AI)
- **Reviewer**: Antigravity (AI)
- **Date**: 2025-12-02
- **Outcome**: Approved
- **Summary**: The UX refinements are fully implemented. The "Night-Only Mode" logic now correctly calculates the duration between Sunset and Sunrise, ensuring accurate graph representation. Swipe-to-Delete has also been implemented for better UX.

### Key Findings
- **[RESOLVED] Night Mode Duration Inaccuracy**: Fixed by updating `AstronomyService` to accept `duration` and calculating it based on actual Sunset/Sunrise times.
- **[RESOLVED] Delete Interaction**: Implemented Swipe-to-Delete using `Dismissible` in `LocationsScreen`.

### Acceptance Criteria Coverage
| AC# | Description | Status | Evidence |
| :--- | :--- | :--- | :--- |
| 1 | Delete Saved Location | **IMPLEMENTED** | `LocationsScreen` (Swipe-to-Delete & Long-press) |
| 2 | Reverse Geocoding | **IMPLEMENTED** | `GeocodingService` (Nominatim API), `AstrContextNotifier` |
| 3 | Night-Only Display Mode | **IMPLEMENTED** | `VisibilityServiceImpl` uses calculated night duration |

**Summary**: 3 of 3 acceptance criteria fully implemented.

### Task Completion Validation
| Task | Marked As | Verified As | Evidence |
| :--- | :--- | :--- | :--- |
| Update `SavedLocationsNotifier` | [ ] | **COMPLETED** | `SavedLocationsNotifier.deleteLocation` exists |
| Implement `Dismissible` widget | [ ] | **COMPLETED** | Implemented in `LocationsScreen` |
| Create `GeocodingService` | [ ] | **COMPLETED** | `features/context/data/datasources/geocoding_service.dart` |
| Implement `getPlaceName` | [ ] | **COMPLETED** | Implemented with Nominatim & User-Agent |
| Update `GeoLocation` model | [ ] | **COMPLETED** | `GeoLocation` has `placeName` |
| Update `AstrContextProvider` | [ ] | **COMPLETED** | Fetches name on load/update |
| Refactor `VisibilityGraphPainter` | [ ] | **COMPLETED** | Accepts start/end times |
| Update `AstronomyEngine` | [ ] | **COMPLETED** | `getNightWindow` implemented |
| Adjust `ForecastScreen` logic | [ ] | **VERIFIED** | Graph logic updated to use dynamic duration |

### Action Items
**Code Changes Required:**
- [x] [Med] Fix Night Mode logic to use actual Sunrise time for graph end, instead of hardcoded 12h duration (AC #3) [file: lib/features/catalog/data/services/visibility_service_impl.dart]
- [x] [Low] Consider implementing Swipe-to-Delete for better UX (AC #1) [file: lib/features/profile/presentation/screens/locations_screen.dart]

**Advisory Notes:**
- Note: The `GeocodingService` correctly handles the User-Agent requirement for Nominatim.
