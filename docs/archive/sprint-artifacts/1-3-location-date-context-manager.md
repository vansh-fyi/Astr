# User Story: 1.3 Location & Date Context Manager

> **Epic:** 1 - Foundation & Core Data Engine
> **Story ID:** 1.3
> **Story Title:** Location & Date Context Manager
> **Status:** Done
> **Priority:** High
> **Estimation:** 3 Points

## 1. Story Statement
**As a** User,
**I want** the app to automatically detect my location and default to the current date,
**So that** the astronomy data I see is immediately relevant to where I am right now.

## 2. Context & Requirements
This story establishes the "Context" of the application: **Where** (Location) and **When** (Date/Time). This context drives the Astronomy Engine (Story 1.2) and all subsequent features. We need a global state manager to hold this data and a service to fetch the device's physical location.

### Requirements Source
*   **PRD:** FR2 (Context Persistence), FR15 (Location Awareness), Security (Location Permission).
*   **Tech Spec:** Epic 1, Section 2.1 (ContextManager, LocationService), 2.2 (AstrContext, GeoLocation).
*   **Architecture:** Domain Layer (Entities), Data Layer (Repository), State Management (Riverpod).

## 3. Acceptance Criteria

| AC ID | Criteria | Verification Method |
| :--- | :--- | :--- |
| **AC-1.3.1** | App requests "While Using" Location Permission on first launch. | Manual: Fresh install, verify system dialog. |
| **AC-1.3.2** | `LocationService` returns current GPS coordinates if permission granted. | Unit/Widget Test: Mock Geolocator. |
| **AC-1.3.3** | If permission denied, system defaults to a "Fallback Location" (e.g., (0,0) or last known) without crashing. | Manual: Deny permission, verify app loads. |
| **AC-1.3.4** | `AstrContext` state defaults to "Current Date/Time" on startup. | Unit Test: Verify initial state. |
| **AC-1.3.5** | `AstrContext` is accessible globally via Riverpod Provider. | Code Review. |
| **AC-1.3.6** | `GeoLocation` entity includes latitude, longitude, and optional name. | Code Review. |

## 4. Technical Tasks

### 4.1 Dependency & Setup
- [x] Add `geolocator` and `permission_handler` (if needed) to `pubspec.yaml`.
- [x] Configure Android `AndroidManifest.xml` (Permissions).
- [x] Configure iOS `Info.plist` (Usage Descriptions).

### 4.2 Domain Layer
- [x] Define `GeoLocation` entity.
- [x] Define `AstrContext` entity (immutable state holding Location + Date).
- [x] Define `ILocationService` interface.

### 4.3 Data Layer (Infrastructure)
- [x] Implement `DeviceLocationService` using `geolocator`.
- [x] Handle permission requests and exceptions (Denied, Permanently Denied).

### 4.4 State Management (Application Layer)
- [x] Create `AstrContextNotifier` (Riverpod `Notifier` or `StateNotifier`).
- [x] Implement `loadContext()` logic (Request permission -> Get Location -> Set State).
- [x] Expose `astrContextProvider`.

### 4.5 Testing & Verification
- [x] Create `test/core/services/location_service_test.dart` (Mocking Geolocator).
- [x] Create `test/features/context/astr_context_test.dart` (State logic).
- [x] Manual: Verify permission flow on Emulator/Simulator.

## 5. Dev Notes
*   **State Management:** Use `riverpod` (likely `AsyncNotifier` or `Notifier`) to handle the async nature of fetching location.
*   **Permissions:** Be careful with the "First Run" experience. The app should probably show a "Why we need this" UI before triggering the OS dialog if possible, or just trigger it on the Splash/Home init.
*   **Fallback:** For MVP, if location is denied, default to Null Island (0,0) or a hardcoded "Default" (e.g., Greenwich) so the app remains usable.
*   **Architecture:** `LocationService` belongs in `core/services` or `features/location/data`. `AstrContext` is a global "App State" concept, likely in `core/state` or `features/context`.

### Learnings from Previous Story
**From Story 1.2 (Status: Done)**
*   **Structure:** Continue using `lib/features/` structure.
*   **Type Safety:** Use `fpdart` `Either` for the Location Service to handle "Permission Denied" as a Failure, not an Exception.
*   **Testing:** Unit tests are critical. Mock the `geolocator` platform channel or wrapper.

## 6. Dev Agent Record

### File List
*   `lib/features/context/domain/entities/geo_location.dart`
*   `lib/features/context/domain/entities/astr_context.dart`
*   `lib/core/services/i_location_service.dart`
*   `lib/core/services/device_location_service.dart`
*   `lib/core/services/location_service_provider.dart`
*   `lib/features/context/presentation/providers/astr_context_provider.dart`
*   `test/core/services/location_service_test.dart`
*   `test/features/context/astr_context_test.dart`
*   `lib/core/error/failure.dart` (Modified)
*   `pubspec.yaml` (Modified)
*   `android/app/src/main/AndroidManifest.xml` (Modified)
*   `ios/Runner/Info.plist` (Modified)

### Change Log
*   Added `geolocator` and `permission_handler` dependencies.
*   Configured location permissions for Android and iOS.
*   Implemented Domain Layer: `GeoLocation`, `AstrContext`, `ILocationService`.
*   Implemented Data Layer: `DeviceLocationService` with error handling.
*   Implemented State Management: `AstrContextNotifier` with Riverpod.
*   Added unit tests for Service and Notifier.

### Completion Notes
*   Implemented full location flow with permission handling.
*   Used `fpdart` `Either` for robust error handling in `DeviceLocationService`.
*   Mocked `GeolocatorPlatform` manually in tests to avoid platform interface issues.
*   All tests passed.

### Context Reference
*   [Context XML](1-3-location-date-context-manager.context.xml)

## 7. Senior Developer Review (AI)

### Reviewer: Vansh
### Date: 2025-11-29
### Outcome: Approve
**Justification:** The implementation is solid, follows the architecture strictly, and includes robust error handling and testing. All acceptance criteria are met.

### Summary
The `Location & Date Context Manager` has been implemented successfully. The code is clean, well-structured, and adheres to the project's Clean Architecture and Functional Error Handling patterns. The use of `fpdart` for the Location Service and `Riverpod` for state management is correctly applied.

### Key Findings
*   **High Quality:** The `DeviceLocationService` correctly handles all permission states (Granted, Denied, DeniedForever, ServiceDisabled) using `Either`.
*   **Robustness:** The `AstrContextNotifier` gracefully handles location failures by defaulting to a safe state (Null Island/Default), ensuring the app doesn't crash on startup.
*   **Testing:** The manual mocking of `GeolocatorPlatform` in tests is a smart move to avoid common FFI/Platform Channel issues during unit testing.

### Acceptance Criteria Coverage

| AC ID | Description | Status | Evidence |
| :--- | :--- | :--- | :--- |
| **AC-1.3.1** | App requests "While Using" Location Permission on first launch. | **IMPLEMENTED** | `DeviceLocationService.dart`, `AndroidManifest.xml`, `Info.plist` |
| **AC-1.3.2** | `LocationService` returns current GPS coordinates if permission granted. | **IMPLEMENTED** | `DeviceLocationService.dart:34` |
| **AC-1.3.3** | If permission denied, system defaults to a "Fallback Location". | **IMPLEMENTED** | `astr_context_provider.dart:18` (Handles Failure -> Default) |
| **AC-1.3.4** | `AstrContext` state defaults to "Current Date/Time" on startup. | **IMPLEMENTED** | `astr_context_provider.dart:13` |
| **AC-1.3.5** | `AstrContext` is accessible globally via Riverpod Provider. | **IMPLEMENTED** | `astr_context_provider.dart:44` |
| **AC-1.3.6** | `GeoLocation` entity includes latitude, longitude, and optional name. | **IMPLEMENTED** | `geo_location.dart` |

**Summary:** 6 of 6 acceptance criteria fully implemented.

### Task Completion Validation

| Task | Marked As | Verified As | Evidence |
| :--- | :--- | :--- | :--- |
| Dependency & Setup | [x] | **VERIFIED** | `pubspec.yaml`, `AndroidManifest.xml`, `Info.plist` |
| Domain Layer | [x] | **VERIFIED** | `geo_location.dart`, `astr_context.dart`, `i_location_service.dart` |
| Data Layer | [x] | **VERIFIED** | `device_location_service.dart` |
| State Management | [x] | **VERIFIED** | `astr_context_provider.dart` |
| Testing | [x] | **VERIFIED** | `location_service_test.dart`, `astr_context_test.dart` |

**Summary:** All tasks verified complete.

### Test Coverage and Gaps
*   **Unit Tests:** Excellent coverage for `DeviceLocationService` (mocking platform) and `AstrContextNotifier` (mocking service).
*   **Manual Verification:** Recommended to verify the actual permission dialog on a real device/emulator as unit tests only mock the platform channel.

### Architectural Alignment
*   **Layering:** Correct separation of Domain (Entities), Data (Service Implementation), and Presentation/Application (Notifier).
*   **Patterns:** "Result Pattern" (`Either<Failure, Success>`) correctly implemented.

### Action Items
*   **Advisory Notes:**
    *   - Note: When implementing the UI (Epic 2/3), ensure the user can manually override the location if GPS is flaky or they want to plan for a different location.
    *   - Note: Consider adding a "Retry Location" button in the UI if the initial fetch fails, calling `ref.read(astrContextProvider.notifier).refreshLocation()`.
