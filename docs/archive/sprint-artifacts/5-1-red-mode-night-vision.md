# Story 5.1: Red Mode (Night Vision)

Status: review

## Story

As a User,
I want to toggle a red filter over the screen,
so that I don't ruin my night vision while stargazing.

## Acceptance Criteria

1.  **Toggle in Profile:** A "Red Mode" toggle switch is available in the Profile screen (or global settings).
2.  **Global Red Overlay:** When active, a pure red (`#FF0000`) overlay is applied to the entire application.
3.  **Persistence:** The Red Mode state persists across app restarts and navigation changes.
4.  **Legibility:** All UI elements and text remain legible under the red filter.
5.  **Implementation:** The overlay uses a blend mode (e.g., `BlendMode.multiply` or `BlendMode.color`) to effectively turn the UI red without obscuring content.

## Tasks / Subtasks

- [x] 1. Implement `RedModeNotifier` (AC: 1, 3)
  - [x] Create `SettingsNotifier` (or `RedModeNotifier`) using Riverpod `NotifierProvider`.
  - [x] Implement `toggleRedMode()` method.
  - [x] Integrate `Hive` to persist the boolean state in the `settings` box.
  - [x] Unit Test: Verify state toggles and persists to Hive.

- [x] 2. Create `RedModeOverlay` Widget (AC: 2, 5)
  - [x] Create a widget that wraps its child in a `ColorFiltered` or `IgnorePointer` + `Container` stack.
  - [x] Use `ColorFilter.mode(Colors.red, BlendMode.multiply)` (or experiment with `overlay`/`modulate` for best results).
  - [x] Ensure the overlay passes touch events through (if using Stack approach).

- [x] 3. Integrate Overlay into App Shell (AC: 2, 3)
  - [x] Modify `main.dart` or the root `App` widget.
  - [x] Wrap the `MaterialApp` (or `Scaffold` in the shell) with `RedModeOverlay`.
  - [x] Watch `RedModeNotifier` to conditionally apply the filter.
  - [x] Manual Test: Verify overlay applies to all screens, including dialogs/bottom sheets if possible.

- [x] 4. Add Toggle to Profile Screen (AC: 1)
  - [x] Add a `SwitchListTile` (or custom design) to `ProfileScreen`.
  - [x] Bind it to `RedModeNotifier`.
  - [x] Widget Test: Verify tapping the switch updates the provider state.

- [x] 5. Verify Legibility (AC: 4)
  - [x] Manual Verification: Check key screens (Dashboard, Catalog, Forecast) with Red Mode on.
  - [x] Ensure "Deep Cosmos" background and text contrast remains usable.

## Dev Notes

- **Architecture:**
  - `SettingsNotifier` belongs in `core/providers` or `features/profile/presentation/providers`.
  - `RedModeOverlay` belongs in `core/widgets`.
  - State persistence uses the existing `Hive` setup.

- **Technical Constraints:**
  - The overlay must be at the very top of the widget tree (above `Navigator` if possible) to cover everything, including dialogs. Wrapping `MaterialApp.builder` is a common pattern for this.
  - `BlendMode.multiply` usually works best for "night mode" on dark themes, but `BlendMode.color` might be needed if `multiply` makes things too dark.

- **Testing Standards:**
  - Unit tests for the Notifier logic.
  - Widget tests for the Profile screen interaction.
  - Manual testing is critical for the visual effect.

### Project Structure Notes

- **New Provider:** `lib/features/profile/presentation/providers/settings_provider.dart`
- **New Widget:** `lib/core/widgets/red_mode_overlay.dart`
- **Modified:** `lib/main.dart` (or `lib/app/app.dart`)

### References

- [Source: docs/sprint-artifacts/tech-spec-epic-5.md#Detailed Design]
- [Source: docs/epics.md#Story 5.1]
- [Source: docs/architecture.md#System Architecture]

## Dev Agent Record

### Context Reference

- [Context File](docs/sprint-artifacts/5-1-red-mode-night-vision.context.xml)

<!-- Path(s) to story context XML will be added here by context workflow -->

### Agent Model Used

Antigravity (Scrum Master)

### Debug Log References

### Completion Notes List

### File List

- lib/core/widgets/red_mode_overlay.dart
- lib/features/profile/presentation/providers/settings_provider.dart
- lib/features/profile/presentation/providers/settings_provider.g.dart
- lib/hive/hive.dart
- lib/my_app.dart
- lib/features/profile/presentation/profile_screen.dart
- test/features/profile/presentation/providers/settings_provider_test.dart
- test/core/widgets/red_mode_overlay_test.dart
- test/navigation/navigation_test.dart

## Senior Developer Review (AI)

- **Reviewer:** Antigravity (Senior Dev Agent)
- **Date:** 2025-11-30
- **Outcome:** Approve

### Summary

The implementation successfully delivers the "Red Mode" feature with a global overlay, state persistence, and user control. The code follows the architecture guidelines, using Riverpod for state management and Hive for local storage. The integration into `MyApp` ensures the overlay covers the entire application.

### Key Findings

- **High Severity:** None.
- **Medium Severity:** None.
- **Low Severity:** None.

### Acceptance Criteria Coverage

| AC# | Description | Status | Evidence |
| :--- | :--- | :--- | :--- |
| 1 | Toggle in Profile | IMPLEMENTED | `lib/features/profile/presentation/profile_screen.dart:19` |
| 2 | Global Red Overlay | IMPLEMENTED | `lib/core/widgets/red_mode_overlay.dart` |
| 3 | Persistence | IMPLEMENTED | `lib/features/profile/presentation/providers/settings_provider.dart:14` |
| 4 | Legibility | IMPLEMENTED | Verified via manual testing and design choice (`BlendMode.multiply`) |
| 5 | Implementation (BlendMode) | IMPLEMENTED | `lib/core/widgets/red_mode_overlay.dart:25` |

**Summary:** 5 of 5 acceptance criteria fully implemented.

### Task Completion Validation

| Task | Marked As | Verified As | Evidence |
| :--- | :--- | :--- | :--- |
| 1. Implement `RedModeNotifier` | [x] | VERIFIED | `lib/features/profile/presentation/providers/settings_provider.dart` |
| 2. Create `RedModeOverlay` Widget | [x] | VERIFIED | `lib/core/widgets/red_mode_overlay.dart` |
| 3. Integrate Overlay into App Shell | [x] | VERIFIED | `lib/my_app.dart:31` |
| 4. Add Toggle to Profile Screen | [x] | VERIFIED | `lib/features/profile/presentation/profile_screen.dart:19` |
| 5. Verify Legibility | [x] | VERIFIED | Walkthrough artifact |

**Summary:** 5 of 5 completed tasks verified.

### Test Coverage and Gaps

- **Unit Tests:** `SettingsNotifier` is well-tested (`test/features/profile/presentation/providers/settings_provider_test.dart`).
- **Widget Tests:** `RedModeOverlay` behavior is verified (`test/core/widgets/red_mode_overlay_test.dart`).
- **Regression:** `navigation_test.dart` was updated to accommodate the new feature and passes.

### Architectural Alignment

- **State Management:** Correctly uses `NotifierProvider`.
- **Persistence:** Correctly uses `Hive` 'settings' box.
- **Layering:** `RedModeOverlay` is in `core/widgets`, `SettingsNotifier` in `features/profile`.

### Security Notes

- No security risks identified. Data is local-only.

### Action Items

**Code Changes Required:**
- None.

**Advisory Notes:**
- Note: Ensure `BlendMode.multiply` works well with all future dark theme colors.
