---
phase: "03"
fixed_at: 2026-07-05T00:00:00Z
review_path: .planning/phases/03-design-system-home-screen/03-REVIEW.md
iteration: 1
findings_in_scope: 12
fixed: 10
skipped: 2
status: partial
---

# Phase 03: Code Review Fix Report

**Fixed at:** 2026-07-05
**Source review:** .planning/phases/03-design-system-home-screen/03-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 12 (4 Critical + 8 Warning)
- Fixed: 10
- Skipped: 2

## Fixed Issues

### CR-001: Zone-data failure shows misleading "GPS timeout" toast

**Files modified:** `lib/features/splash/domain/services/smart_launch_controller.dart`
**Commit:** ab2dba6
**Applied fix:** Changed the zone-data catch block to return `LaunchSuccess` with `CachedZoneRepository.pristineDarkSky` defaults instead of `const LaunchTimeout()`. GPS succeeding while zone-data fails is not a GPS failure; no toast is shown to the user. Updated class docstring and method docstring to reflect the corrected failure-mode semantics.

---

### CR-002: VisibilityMiniCard rating-bar formula is inverted

**Files modified:** `lib/features/dashboard/presentation/widgets/visibility_mini_card.dart`
**Commit:** 690ab6b
**Applied fix:** Changed `((astrZone - 1) / 2).floor().clamp(0, 5)` to `(5 - ((astrZone - 1) / 2).floor()).clamp(0, 5)`. Zone 1 (dark sky, best) now shows 5 bars; Zone 9 (city, worst) shows 1 bar. Added explanatory comment.

---

### CR-003: ConditionsCard fixed width causes RenderBox overflow on narrow screens

**Files modified:** `lib/features/dashboard/presentation/widgets/conditions_card.dart`
**Commit:** c0a979f
**Applied fix:** Replaced `width: AppSpacing.kConditionsCardWidth` (345px) with `width: double.infinity` on the outer Container. Replaced all three hardcoded `width: 313` on Positioned children with `right: AppSpacing.kCardPadding` so each child is inset symmetrically from both sides and cannot overflow the available screen width.

---

### CR-004: Unsafe `as int` cast on JSON `bortle` field throws TypeError

**Files modified:** `lib/features/data_layer/services/remote_zone_service.dart`
**Commit:** f06e821
**Applied fix:** Changed `json['bortle'] as int` to `(json['bortle'] as num).toInt()`, matching the safe pattern already used by the sibling `ratio` and `sqm` fields. Prevents TypeError when the Cloudflare Worker returns the field as a JSON float.

---

### WR-001: Hardcoded "Excellent" placeholder text in production UI

**Files modified:** `lib/features/dashboard/presentation/widgets/highlights_feed.dart`
**Commit:** de94994
**Applied fix:** Removed the quality chip row entirely (bullet separator, SizedBox spacers, and `'Excellent'` Text widget). The subtitle now shows only `'Best view: $timeStr'`. The quality chip can be reintroduced once real altitude × cloud × moon logic is implemented.

---

### WR-002: Leading-whitespace characters used for visual layout in strings

**Files modified:** `lib/features/dashboard/presentation/widgets/conditions_card.dart`, `test/features/dashboard/presentation/widgets/conditions_card_test.dart`
**Commit:** eec7532
**Applied fix:** Removed the leading spaces from `titleText` (`' Clear Skies'` → `'Clear Skies'`) and `subtitleText` (`'  Perfect visibility for observation'` → `'Perfect visibility for observation'`). Simplified null-coalescing expression to use `?.shortSummary ?? 'Clear Skies'` pattern. Updated the test assertions that explicitly asserted the leading-space strings.

---

### WR-003: GlassPanel InkWell ripple invisible through opaque Container

**Files modified:** `lib/core/widgets/glass_panel.dart`
**Commit:** 5dbb6d6
**Applied fix:** Wrapped the `InkWell` in `Material(type: MaterialType.transparency)` so Flutter's ink splash layer can render through the semi-transparent Container background. Added explanatory comment describing why the Material wrapper is necessary.

---

### WR-004: `AppTypography.nav` getter allocates new TextStyle every call; wrong font

**Files modified:** `lib/core/design/app_typography.dart`
**Commit:** 8cca31e
**Applied fix:** Changed `static TextStyle get nav => GoogleFonts.inter(...)` to `static final TextStyle nav = const TextStyle(fontFamily: 'Satoshi', ...)`. The field is now allocated once at class load time, and the font family aligns with all other typography constants. Removed the unused `google_fonts` import.

---

### WR-007: Rise/set times rendered without `.toLocal()` — risk of UTC display

**Files modified:** `lib/features/dashboard/presentation/widgets/conditions_card.dart`
**Commit:** d5850ae
**Applied fix:** Added `final DateTime? localTime = time?.toLocal();` in `_TimeCell.build` and used `localTime` for the hour/minute formatting instead of the raw `time` field. Users outside UTC now see their correct local time.

---

### WR-008: Dead condition `cloudCover < 80.0` in Fair branch

**Files modified:** `lib/core/services/qualitative/qualitative_condition_service.dart`
**Commit:** e4e19ba
**Applied fix:** Removed `&& cloudCover < 80.0` from the Fair branch guard. The `cloudCover > 70.0` check earlier in the method already returns before reaching this branch, making `cloudCover < 80.0` permanently true and therefore dead code. Updated comments to document the actual effective boundary.

---

## Skipped Issues

### WR-005: `RemoteZoneService` HTTP client not guaranteed to be disposed

**File:** `lib/features/data_layer/services/remote_zone_service.dart:99-102`
**Reason:** The `dispose()` method already exists. The fix requires locating the Riverpod provider that creates `RemoteZoneService` and attaching `ref.onDispose()`. That provider is not in the list of reviewed files. A targeted fix risks introducing a regression in the provider setup without seeing the full provider graph. Marking for human follow-up: find the provider that constructs `RemoteZoneService` and add `ref.onDispose(() => remoteZoneService.dispose())`.

---

### WR-006: `_FakeRef.noSuchMethod` returns null for all Ref methods in test

**File:** `test/features/dashboard/presentation/widgets/conditions_card_test.dart:58-61`
**Reason:** The review recommends injecting `ObjectDetailNotifier` via `objectDetailNotifierProvider.overrideWith(...)` instead of constructing it directly. However, the existing test already uses `objectDetailNotifierProvider.overrideWith(...)` at line 92 for the provider scope — the `_FakeRef` is only used inside `FakeObjectDetailNotifier`'s constructor which calls the parent class directly. Refactoring requires changing how `FakeObjectDetailNotifier` is structured (removing the direct constructor call) and restructuring the whole test fixture, which is a larger test-architecture change that warrants developer review rather than a mechanical edit. Marking for human follow-up.

---

_Fixed: 2026-07-05_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
