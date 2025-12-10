# Story 6.2: Terms of Service & Liability Disclaimer

Status: review

## Story

As a User,
I want to see a disclaimer upon first launch,
so that I understand the risks of visiting remote locations.

## Acceptance Criteria

1.  **First Launch Check:**
    -   App checks `tos_accepted` flag in Hive (`settings` box) on startup.
    -   Default value is `false` (not accepted).
2.  **Blocking UI:**
    -   If `tos_accepted` is false, the user is redirected to a blocking `ToSScreen`.
    -   Navigation to other routes is prevented until accepted.
3.  **Content Display:**
    -   Screen displays clear text stating:
        -   "Astr is not liable for accidents or injuries."
        -   "Stargazing locations are suggestions only; verify safety yourself."
    -   **UX:** Uses "Astr Aura" theme (GlassPanel, Deep Cosmos background).
4.  **Acceptance Action:**
    -   User taps "I Agree" button.
    -   System saves `tos_accepted = true` to Hive.
5.  **Navigation:**
    -   Upon acceptance, user is automatically navigated to the Home screen.
    -   Subsequent app launches skip this screen.

## Tasks / Subtasks

- [x] Task 1: Implement ToS Persistence (AC: 1, 4)
    - [x] Update `SettingsRepository` (or create `ToSRepository`) to handle `tos_accepted` key.
    - [x] Create `ToSNotifier` (Riverpod) to expose state.
- [x] Task 2: Create ToS Screen UI (AC: 3)
    - [x] Build `ToSScreen` widget using `GlassPanel`.
    - [x] Add Disclaimer Text (Liability, Safety).
    - [x] Add "I Agree" button (Primary Action Style).
- [x] Task 3: Implement Navigation Guard (AC: 2, 5)
    - [x] Update `GoRouter` configuration (`app_router.dart`).
    - [x] Add redirect logic: `if (!tosAccepted) return '/tos';`.
    - [x] Ensure state changes trigger router refresh.
- [x] Task 4: Verification
    - [x] Verify fresh install shows screen.
    - [x] Verify acceptance persists after restart.

## Dev Notes

- **Architecture:**
    -   Use existing `settings` Hive box (from Epic 5).
    -   State Management: Use a Riverpod provider to watch the Hive setting and drive the Router redirect.
- **Routing:**
    -   `GoRouter`'s `redirect` callback is the standard place for this.
    -   Ensure the provider used in redirect is listened to by the router (`refreshListenable`).

### Project Structure Notes

-   `lib/features/profile/data/` - Good place for ToS persistence logic if part of "Settings", or a new `features/onboarding/` module if preferred. Given Epic 5 "Profile & Personalization" owns settings, keep it there or in `core`.
-   **Decision:** Let's put `ToSScreen` in `features/onboarding/presentation/` or `features/profile/presentation/`. Since it's a "legal" check, `features/legal` or `core/presentation` works. Let's stick to **`features/profile`** (Settings) to avoid folder sprawl, as it's a "Setting".

### References

-   [Source: docs/sprint-artifacts/tech-spec-epic-6.md#Detailed-Design]
-   [Source: docs/epics.md#Story-6.2]
-   [Source: docs/architecture.md#Local-Storage-Hive]

## Dev Agent Record

### Context Reference

- [Context XML](story-6-2-terms-of-service-liability-disclaimer.context.xml)

### Agent Model Used

Gemini 2.0 Flash

### Debug Log References

### Completion Notes List

- Implemented `SettingsRepository` with `tos_accepted` key in `settings` Hive box.
- Created `ToSNotifier` provider.
- Created `ToSScreen` with "Astr Aura" theme.
- Updated `AppRouter` with redirect logic to enforce ToS acceptance.
- Added unit tests for repository and widget tests for screen.

### File List

- lib/features/profile/data/repositories/settings_repository.dart
- lib/features/profile/presentation/providers/tos_provider.dart
- lib/features/profile/presentation/screens/tos_screen.dart
- lib/app/router/app_router.dart
- test/features/profile/data/repositories/settings_repository_test.dart
- test/features/profile/presentation/screens/tos_screen_test.dart

## Code Review - 2025-11-30

### Outcome: Approved

### Validation Checklist

- [x] **AC 1: First Launch Check** - Verified `SettingsRepository` defaults to false.
- [x] **AC 2: Blocking UI** - Verified `AppRouter` redirect logic blocks navigation.
- [x] **AC 3: Content Display** - Verified `ToSScreen` uses "Astr Aura" theme and correct text.
- [x] **AC 4: Acceptance Action** - Verified "I Agree" button updates Hive and State.
- [x] **AC 5: Navigation** - Verified router redirects to Home upon acceptance.

### Findings

- **Code Quality:** Excellent separation of concerns. Riverpod provider correctly drives the router.
- **Testing:** Unit tests cover persistence logic. Widget tests cover UI.
- **UX:** Blocking flow is implemented correctly using GoRouter redirects.

### Next Steps

- Merge to main branch (if applicable).
- Mark story as `done`.
