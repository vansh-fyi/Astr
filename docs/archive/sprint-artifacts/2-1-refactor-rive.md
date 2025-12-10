# User Story: 2.1 Refactor - Rive Visuals

> **Epic:** 2 - The Dashboard ("Is Tonight Good?")
> **Story ID:** 2.1-refactor
> **Story Title:** Refactor Visuals to Rive
> **Status:** review
> **Priority:** High
> **Estimation:** 3 Points

## 1. Story Statement
**As a** User,
**I want** the Dashboard visuals (Bortle & Cloud bars) to be animated using Rive,
**So that** they look "premium" and match the new design system.

## 2. Context & Requirements
The initial implementation used standard Flutter widgets. We are now switching to **Rive** for all graph/bar interactions to enable complex animations and better performance. This story covers replacing the existing `BortleBar` and `CloudBar` widgets with Rive implementations.

### Requirements Source
*   **PRD:** Rive Animations (Innovation Section).
*   **Architecture:** The "Rive" Pattern.

## 3. Acceptance Criteria

| AC ID | Criteria | Verification Method |
| :--- | :--- | :--- |
| **AC-2.1-R.1** | **Rive Integration:** `BortleBar` uses `dashboard_bars.riv` (Artboard: `Bortle`). | Visual Inspection. |
| **AC-2.1-R.2** | **Bortle Data Binding:** Binds `bortleLevel` (1-9) to Rive input. | Widget Test / Visual. |
| **AC-2.1-R.3** | **Cloud Data Binding:** `CloudBar` uses `dashboard_bars.riv` (Artboard: `Cloud`) and binds `cloudCover` (0-100). | Widget Test / Visual. |
| **AC-2.1-R.4** | **Cleanup:** Old CustomPainter/Container implementations are removed. | Code Review. |
| **AC-2.1-R.5** | **Tests:** Existing tests are updated to verify Rive widget presence (mocking Rive if needed). | `flutter test`. |

## 4. Rive Asset Specifications

**Asset Name:** `assets/rive/dashboard_bars.riv`

### Artboard: `Bortle`
| Property | Value | Description |
| :--- | :--- | :--- |
| **Size** | **350 x 30** | **Bar Only.** |
| **State Machine** | `State Machine 1` | Primary controller. |
| **Input: Number** | `bortleLevel` | 1-9. Controls the indicator position. |
| **Input: String** | `Bortle` | **CRITICAL:** Text value for the indicator number. Must update simultaneously with level. |
| **Design** | -- | **Star Image** background track. Indicator with text. |

### Artboard: `Cloud`
| Property | Value | Description |
| :--- | :--- | :--- |
| **Size** | **350 x 30** | **Bar Only.** |
| **State Machine** | `State Machine 1` | Primary controller. |
| **Input: Number** | `cloudCover` | 0-100. Controls the bar fill percentage. |
| **Design** | -- | Gradient fill. No text. |

## 5. Technical Tasks

### 5.1 Setup
- [x] Add `rive` dependency to `pubspec.yaml`.
- [x] Create `assets/rive/` directory.
- [x] **User Action:** Place `dashboard_bars.riv` in `assets/rive/`.

### 5.2 Implementation
- [x] Refactor `BortleBar` to use `RiveAnimation.asset`.
- [x] Refactor `CloudBar` to use `RiveAnimation.asset`.
- [x] **Responsiveness:** Ensure widgets scale correctly on Web/Desktop (use `BoxFit.contain` or `fit: BoxFit.fitWidth`).
- [x] Wire up `WeatherNotifier` state to Rive inputs.

### 5.3 Cleanup & Testing
- [x] Remove old widget code.
- [x] Update tests to check for `RiveAnimation` widgets.

## 6. Dev Notes
*   **Dependency:** `rive: ^0.13.0` (or latest).
*   **Testing:** Rive widgets can be tricky to test. Use `find.byType(RiveAnimation)` for basic verification.

## 7. File List
*   `pubspec.yaml`
*   `lib/core/widgets/astr_rive_animation.dart`
*   `lib/features/dashboard/presentation/widgets/bortle_bar.dart`
*   `lib/features/dashboard/presentation/widgets/cloud_bar.dart`
*   `test/features/dashboard/presentation/widgets/bortle_bar_test.dart`
*   `test/features/dashboard/presentation/widgets/cloud_bar_test.dart`

## Senior Developer Review (AI)

*   **Reviewer:** Vansh (AI Agent)
*   **Date:** 2025-11-29
*   **Outcome:** Approve

### Summary
The refactor successfully replaces the legacy Flutter widgets with Rive animations as specified. The implementation correctly binds the data inputs (`bortleLevel`, `Bortle` string, `cloudCover`) to the Rive state machines. The introduction of `AstrRiveAnimation` is a smart architectural decision to handle the Rive FFI testing limitations without compromising the production code.

### Key Findings
*   **High Severity:** None.
*   **Medium Severity:** None.
*   **Low Severity:** None.

### Acceptance Criteria Coverage
| AC ID | Criteria | Status | Evidence |
| :--- | :--- | :--- | :--- |
| **AC-2.1-R.1** | **Rive Integration:** `BortleBar` uses `dashboard_bars.riv` (Artboard: `Bortle`). | **IMPLEMENTED** | `lib/features/dashboard/presentation/widgets/bortle_bar.dart:77` |
| **AC-2.1-R.2** | **Bortle Data Binding:** Binds `bortleLevel` (1-9) to Rive input. | **IMPLEMENTED** | `lib/features/dashboard/presentation/widgets/bortle_bar.dart:52` |
| **AC-2.1-R.3** | **Cloud Data Binding:** `CloudBar` uses `dashboard_bars.riv` (Artboard: `Cloud`) and binds `cloudCover` (0-100). | **IMPLEMENTED** | `lib/features/dashboard/presentation/widgets/cloud_bar.dart:43` |
| **AC-2.1-R.4** | **Cleanup:** Old CustomPainter/Container implementations are removed. | **IMPLEMENTED** | Verified in `bortle_bar.dart` and `cloud_bar.dart`. |
| **AC-2.1-R.5** | **Tests:** Existing tests are updated to verify Rive widget presence (mocking Rive if needed). | **IMPLEMENTED** | `test/features/dashboard/presentation/widgets/bortle_bar_test.dart:28` |

**Summary:** 5 of 5 acceptance criteria fully implemented.

### Task Completion Validation
| Task | Marked As | Verified As | Evidence |
| :--- | :--- | :--- | :--- |
| Add `rive` dependency | [x] | **VERIFIED** | `pubspec.yaml` |
| Create `assets/rive/` directory | [x] | **VERIFIED** | Directory exists. |
| Place `dashboard_bars.riv` | [x] | **VERIFIED** | User confirmed action. |
| Refactor `BortleBar` | [x] | **VERIFIED** | `bortle_bar.dart` |
| Refactor `CloudBar` | [x] | **VERIFIED** | `cloud_bar.dart` |
| Responsiveness | [x] | **VERIFIED** | `fit: BoxFit.fitWidth` used in both widgets. |
| Wire up `WeatherNotifier` | [x] | **VERIFIED** | Widgets accept data from parent (which is wired to notifier). |
| Remove old widget code | [x] | **VERIFIED** | Code removed. |
| Update tests | [x] | **VERIFIED** | Tests updated. |

**Summary:** 9 of 9 completed tasks verified.

### Test Coverage and Gaps
*   **Coverage:** Widget tests cover the presence of the Rive animation and correct data passing.
*   **Gaps:** None. The `AstrRiveAnimation` wrapper ensures tests run without FFI crashes.

### Architectural Alignment
*   **Rive Pattern:** Follows the "Rive Pattern" defined in `architecture.md`.
*   **Glass Pattern:** Retains `GlassPanel` wrapper as required.

### Action Items
*   None.

### Change Log
*   2025-11-29: Senior Developer Review notes appended. Outcome: Approve.
