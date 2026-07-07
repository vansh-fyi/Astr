---
phase: "03"
reviewed: 2026-07-05T00:00:00Z
depth: standard
files_reviewed: 40
files_reviewed_list:
  - lib/app/router/scaffold_with_nav_bar.dart
  - lib/app/theme/app_theme.dart
  - lib/core/design/app_colors.dart
  - lib/core/design/app_spacing.dart
  - lib/core/design/app_typography.dart
  - lib/core/engine/models/condition_result.dart
  - lib/core/engine/models/sky_state.dart
  - lib/core/services/qualitative/qualitative_condition_service.dart
  - lib/core/widgets/glass_panel.dart
  - lib/features/dashboard/data/repositories/light_pollution_repository.dart
  - lib/features/dashboard/presentation/home_screen.dart
  - lib/features/dashboard/presentation/widgets/cloud_bar.dart
  - lib/features/dashboard/presentation/widgets/conditions_card.dart
  - lib/features/dashboard/presentation/widgets/hero_condition_label.dart
  - lib/features/dashboard/presentation/widgets/highlights_feed.dart
  - lib/features/dashboard/presentation/widgets/moon_mini_card.dart
  - lib/features/dashboard/presentation/widgets/sky_state_background.dart
  - lib/features/dashboard/presentation/widgets/visibility_mini_card.dart
  - lib/features/data_layer/models/zone_cache_entry.dart
  - lib/features/data_layer/models/zone_cache_entry.g.dart
  - lib/features/data_layer/models/zone_data.dart
  - lib/features/data_layer/repositories/cached_zone_repository.dart
  - lib/features/data_layer/services/remote_zone_service.dart
  - lib/features/splash/domain/services/smart_launch_controller.dart
  - lib/hive_registrar.g.dart
  - test/app/theme/oled_theme_test.dart
  - test/core/design/app_colors_test.dart
  - test/core/services/qualitative/qualitative_condition_service_test.dart
  - test/features/dashboard/data/repositories/light_pollution_repository_test.dart
  - test/features/dashboard/data/services/weather_background_sync_service_test.dart
  - test/features/dashboard/presentation/widgets/conditions_card_test.dart
  - test/features/dashboard/presentation/widgets/highlights_feed_test.dart
  - test/features/dashboard/presentation/widgets/moon_mini_card_test.dart
  - test/features/dashboard/presentation/widgets/sky_state_background_test.dart
  - test/features/dashboard/presentation/widgets/visibility_mini_card_test.dart
  - test/features/data_layer/models/zone_data_test.dart
  - test/features/data_layer/repositories/cached_zone_repository_test.dart
  - test/features/splash/domain/services/smart_launch_controller_test.dart
  - test/navigation/navigation_test.dart
findings:
  critical: 4
  warning: 8
  info: 4
  total: 16
status: issues_found
---

# Phase 03: Code Review Report

**Reviewed:** 2026-07-05
**Depth:** standard
**Files Reviewed:** 40
**Status:** issues_found

## Summary

Phase 03 implemented the design system tokens, home screen scaffold, sky-state background, ConditionsCard, VisibilityMiniCard, MoonMiniCard, HighlightsFeed, GlassPanel, and the SmartLaunchController integration. The overall architecture is sound, Riverpod provider patterns are used correctly, and the test coverage is substantial. Four bugs require attention before shipping: a misleading user-facing toast caused by misrouted error codes, an inverted rating-bar formula in VisibilityMiniCard, a hard layout overflow on iPhone SE and small-Android devices, and an unsafe JSON cast in the zone API parser that throws `TypeError` on perfectly valid server responses.

---

## Critical Issues

### CR-001: Zone-data failure shows misleading "GPS timeout" toast

**File:** `lib/features/splash/domain/services/smart_launch_controller.dart:96-101`
**Also affected:** `lib/features/dashboard/presentation/home_screen.dart:141-148`

**Problem:** When GPS succeeds but the zone-data fetch throws (network outage, timeout, etc.), `SmartLaunchController.executeLaunch()` returns `const LaunchTimeout()`. The `HomeScreen` switch-case for `LaunchTimeout` calls `ToastService.showGPSTimeout(context)`, telling the user their GPS failed when it did not. The class docstring says this is a "silent fail" but the UI path is not silent — it shows a GPS-specific error. The test suite (`smart_launch_controller_test.dart:196-221`) asserts this wrong mapping as expected behaviour, cementing the defect.

**Fix:** Return `LaunchSuccess` with the `pristineDarkSky` default when zone data is unavailable, or introduce a dedicated `LaunchZoneDataUnavailable` variant so `HomeScreen` can show a neutral informational toast instead of a GPS error:

```dart
// smart_launch_controller.dart, in the zone data catch block
} catch (e) {
  debugPrint('[SmartLaunchController] Zone data fetch failed: $e');
  // GPS succeeded — return success with pristine default, not a timeout
  return LaunchSuccess(
    location: location,
    h3Index: h3Index.toString(),
    zoneData: CachedZoneRepository.pristineDarkSky,
  );
}
```

---

### CR-002: VisibilityMiniCard rating-bar formula is inverted

**File:** `lib/features/dashboard/presentation/widgets/visibility_mini_card.dart:21`

**Problem:** The formula `((astrZone - 1) / 2).floor().clamp(0, 5)` produces the following active-bar counts:

| Zone | Sky type | Active bars |
|------|----------|-------------|
| 1–2 | Dark Sky | 0 |
| 3–4 | Rural Sky | 1 |
| 5–6 | Suburban Sky | 2 |
| 7–8 | Urban/Transition | 3 |
| 9 | Inner City | 4 |

A "VISIBILITY" card labelled "Dark Sky" showing zero active rating bars communicates *no visibility*, the opposite of the intended meaning. Zone 1 (pristine dark sky — the best stargazing location) should display maximum bars.

**Fix:** Invert the formula so darker sky = more active bars:

```dart
// 5 bars for Zone 1, scaling down to 1 bar for Zone 9
final int activeBars = (5 - ((astrZone - 1) / 2).floor()).clamp(0, 5);
```

This maps Zone 1 → 5 bars, Zone 3 → 4 bars, Zone 5 → 3 bars, Zone 7 → 2 bars, Zone 9 → 1 bar.

---

### CR-003: ConditionsCard fixed width causes RenderBox overflow on common devices

**File:** `lib/features/dashboard/presentation/widgets/conditions_card.dart:47,59`

**Problem:** The card uses an unconditional fixed width of `AppSpacing.kConditionsCardWidth = 345` logical pixels. The `HomeScreen` places it inside `Padding(horizontal: 24)`, leaving `screenWidth - 48` pixels available. On devices narrower than 393 logical pixels the card overflows its parent:

| Device | Screen width | Available | Overflow |
|--------|-------------|-----------|---------|
| iPhone SE 3rd gen | 375 pt | 327 pt | 18 pt |
| iPhone 14 | 390 pt | 342 pt | 3 pt |
| Small Android (~360 pt) | 360 pt | 312 pt | 33 pt |

The inner `Stack` also contains `Positioned(left: 16, width: 313)` children, whose right edge is 329 pt. On iPhone SE (stack clamped to 327 pt) this causes an additional 2 pt overflow for those children. Both overflows appear as `RenderFlex` / `RenderBox` overflow warnings in debug mode and clip content in release mode.

**Fix:** Replace the fixed width with `double.infinity` and let the Figma-exact inner layout use `LayoutBuilder` or `Flexible` sizing:

```dart
// conditions_card.dart — Container
Container(
  width: double.infinity,        // stretch to available width
  height: AppSpacing.kConditionsCardHeight,
  ...
)

// Inner Positioned children — derive width from available space
// Replace: width: 313
// Use: right: AppSpacing.kCardPadding  (mirrors the left: 16 inset)
Positioned(
  left: AppSpacing.kCardPadding,
  top: AppSpacing.kCardPadding,
  right: AppSpacing.kCardPadding,   // replaces hardcoded width: 313
  child: Row(...),
),
```

---

### CR-004: Unsafe `as int` cast on JSON `bortle` field throws TypeError on valid server responses

**File:** `lib/features/data_layer/services/remote_zone_service.dart:54`

**Problem:** `json['bortle'] as int` will throw `TypeError` at runtime if the Cloudflare Worker returns the field as a JSON number with a decimal point (e.g., `"bortle": 5.0`). Dart's `jsonDecode` maps JSON integers to `int` and JSON floats to `double`; a cast `as int` on a `double` value throws. The sibling fields `ratio` and `sqm` correctly use `(json['x'] as num).toDouble()`, but `bortle` does not follow the same safe pattern.

**Fix:**

```dart
// remote_zone_service.dart:53-56
return ZoneData(
  astrZone: (json['bortle'] as num).toInt(),   // safe: handles int and double
  ratio: (json['ratio'] as num).toDouble(),
  sqm: (json['sqm'] as num).toDouble(),
);
```

---

## Warnings

### WR-001: Hardcoded "Excellent" placeholder text shipped in production UI

**File:** `lib/features/dashboard/presentation/widgets/highlights_feed.dart:142`

**Problem:** Every entry in the HighlightsFeed renders the string `'Excellent'` unconditionally. The comment acknowledges this is a placeholder, but the code was shipped as-is. Users see "Excellent" for every object regardless of actual sky conditions, which is actively misleading.

**Fix:** Replace the placeholder with logic that derives the quality label from the observing conditions (altitude, cloud cover, moon) or remove the quality chip until the logic is implemented.

---

### WR-002: Leading-whitespace characters used for visual alignment in strings

**File:** `lib/features/dashboard/presentation/widgets/conditions_card.dart:34-38`

**Problem:** `titleText` is prefixed with one space and `subtitleText` with two spaces to nudge text visually. This is fragile: it depends on the renderer not collapsing leading whitespace, breaks accessability tools that read raw string content, and leaks into tests (`conditions_card_test.dart:115-116` explicitly asserts `' Clear Skies'`).

**Fix:** Remove the leading spaces from the strings and apply the desired left offset with `Padding` or `TextAlign`:

```dart
final String titleText = conditionQualityAsync.valueOrNull?.shortSummary ?? 'Clear Skies';
final String subtitleText = conditionQualityAsync.valueOrNull?.detailedAdvice
    ?? 'Perfect visibility for observation';
```

Use a `Padding(padding: EdgeInsets.only(left: X))` around the text if a specific offset is required.

---

### WR-003: GlassPanel InkWell ripple invisible through opaque Container background

**File:** `lib/core/widgets/glass_panel.dart:60-67`

**Problem:** The `InkWell` wraps a `Container` that has a background color of `resolvedBgColor` (alpha 0xCC ≈ 80% or 0xF2 ≈ 95%). Flutter's ink ripple is rendered on the `Material` layer behind the widget tree; the opaque `Container` background sits on top of the `Material` splash and hides it. As a result, none of the tappable `GlassPanel` instances in the app (nav header location pill, date arrows, date pill) show any visual press feedback.

**Fix:** Wrap the `Container` in a `Material(type: MaterialType.transparency)` so the ripple renders through the semi-transparent background:

```dart
if (onTap != null || onLongPress != null) {
  content = Material(
    type: MaterialType.transparency,
    child: InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: radius,
      child: content,
    ),
  );
}
```

---

### WR-004: `AppTypography.nav` getter allocates a new `TextStyle` on every call and uses a different font family

**File:** `lib/core/design/app_typography.dart:66-71`

**Problem:** `nav` is declared as a getter (`get nav =>`) backed by `GoogleFonts.inter(...)`. Every access to `AppTypography.nav` constructs a fresh `TextStyle` object. All other typography constants use `const TextStyle` with the 'Satoshi' font. The nav bar labels therefore use Inter (a different font family downloaded via Google Fonts) instead of the app's design-system font, creating a visible typographic inconsistency.

**Fix:** Cache the style once and align the font with the design system:

```dart
static final TextStyle nav = const TextStyle(
  fontFamily: 'Satoshi',
  fontSize: 8,
  fontWeight: FontWeight.w400,
  height: 1.3,
  color: AppColors.textPrimary,
);
```

If Inter is intentional per Figma specs, change `static TextStyle get nav` to `static final TextStyle nav` so it is only computed once.

---

### WR-005: `RemoteZoneService` HTTP client not guaranteed to be disposed

**File:** `lib/features/data_layer/services/remote_zone_service.dart:99-102`

**Problem:** The service accepts an optional `http.Client` and creates a default one when none is provided. A `dispose()` method exists but is never called from a Riverpod provider `onDispose` or anywhere else in the reviewed files. Each default `http.Client()` holds an open connection pool; if the service is re-created or the DI container swaps it out, connections leak.

**Fix:** Wherever the service is provided via Riverpod, attach a dispose callback:

```dart
// in the provider that creates RemoteZoneService
ref.onDispose(() => remoteZoneService.dispose());
```

---

### WR-006: `_FakeRef.noSuchMethod` returns `null` for all Riverpod Ref methods in test

**File:** `test/features/dashboard/presentation/widgets/conditions_card_test.dart:58-61`

**Problem:**

```dart
class _FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
```

This class satisfies the `Ref` interface at compile time but returns `null` for every method call at runtime. If `ObjectDetailNotifier` internally calls any `Ref` method that returns a non-nullable type (e.g., `ref.read(someProvider)` where `someProvider` has a non-nullable state), the call silently returns `null`, which can cause NPEs or silent incorrect state. This makes the test unreliable as a correctness signal.

**Fix:** Override and inject `ObjectDetailNotifier` via the Riverpod provider override system rather than constructing it directly with a fake `Ref`. Use `objectDetailNotifierProvider.overrideWith(...)` only, and let Riverpod supply the real `Ref`.

---

### WR-007: Rise/set times displayed using `DateTime.hour/minute` without timezone awareness

**File:** `lib/features/dashboard/presentation/widgets/conditions_card.dart:193-195`

**Problem:**

```dart
final String timeStr = time != null
    ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
    : '--:--';
```

If the `DateTime` values returned by `riseSetProvider` are in UTC (common for astronomical calculations), the displayed times will be wrong for every timezone other than UTC. The test in `conditions_card_test.dart` uses `DateTime(2025, 1, 1, 6, 0)` (a local-time constructor) and therefore does not catch this defect.

**Fix:** Ensure the `DateTime` objects from `riseSetProvider` are converted to local time before rendering, or explicitly convert at the display site:

```dart
final DateTime localTime = time!.toLocal();
final String timeStr =
    '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
```

---

### WR-008: Dead condition `cloudCover < 80.0` in Fair branch of `QualitativeConditionService`

**File:** `lib/core/services/qualitative/qualitative_condition_service.dart:124`

**Problem:** The Fair branch guard reads `cloudCover < 80.0`, implying it could match cloud cover between 70 and 80. However, the first branch at line 76 (`if (cloudCover > 70.0)`) already returns `poor/cloudy` for that range. By the time execution reaches the Fair check, `cloudCover` is guaranteed to be ≤ 70, making the `< 80.0` sub-condition permanently true and therefore dead code. This misleads maintainers into thinking the boundary is 80 when it is actually 70.

**Fix:** Remove the dead sub-condition or replace it with the correct effective boundary:

```dart
// Before (misleading):
if (overallScore > 0.25 && cloudCover < 80.0 && mpsas > 17.3)

// After (accurate):
if (overallScore > 0.25 && cloudCover <= 70.0 && mpsas > 17.3)
// Or simply omit the cloud check since it is always true at this point:
if (overallScore > 0.25 && mpsas > 17.3)
```

---

## Info

### IN-001: Magic number `55` in `ScaffoldWithNavBar` should use named constant

**File:** `lib/app/router/scaffold_with_nav_bar.dart:47`

**Problem:** `const EdgeInsets.only(top: 55)` hard-codes the header content offset that is already defined as `AppSpacing.kHeaderContentOffset = 55`. The value is used consistently via the constant elsewhere (e.g., `home_screen.dart:229`) but not here.

**Fix:**

```dart
padding: const EdgeInsets.only(top: AppSpacing.kHeaderContentOffset),
```

---

### IN-002: Mixed mocking libraries across the test suite

**Files:** `test/features/dashboard/data/repositories/light_pollution_repository_test.dart`, `test/features/dashboard/data/services/weather_background_sync_service_test.dart` (use mocktail) vs `test/features/data_layer/repositories/cached_zone_repository_test.dart`, `test/features/splash/domain/services/smart_launch_controller_test.dart` (use mockito + `@GenerateMocks`)

**Problem:** Both `mockito` and `mocktail` are active in the test suite. They have different APIs (`when(() => ...)` vs `when(mock.method())`), different stub registration patterns, and different codegen requirements. New contributors must learn both.

**Fix:** Pick one library and migrate all tests to it. `mocktail` is the simpler choice since it requires no codegen.

---

### IN-003: Unreachable fallback return in `MoonMiniCard` phase-mapping methods

**File:** `lib/features/dashboard/presentation/widgets/moon_mini_card.dart:100,113`

**Problem:** Both `_getMoonAsset` and `_getMoonPhaseLabel` end with a default `return` that is dead code. The combined angle ranges cover all possible `double` values (the `>= 355 || <= 5` branch captures angles outside `[5, 355)`, so the final `return` after the last `if` is unreachable). This misleads readers into thinking there are unhandled cases.

**Fix:** Replace the trailing `return` with an assertion to make the unreachability explicit and help detect future regressions:

```dart
// Should never be reached — all angles are covered
assert(false, 'Unhandled phaseAngle: $angle');
return 'assets/img/moon_new.webp'; // satisfy Dart's non-nullable return requirement
```

---

### IN-004: `CloudBar` is a `StatefulWidget` with zero state

**File:** `lib/features/dashboard/presentation/widgets/cloud_bar.dart:20-25`

**Problem:** `_CloudBarState` has no instance fields, no `initState`, and no `dispose`. The `AnimatedContainer` inside `build` manages its own animation state internally. `CloudBar` should be a `StatelessWidget`.

**Fix:**

```dart
class CloudBar extends StatelessWidget {
  const CloudBar({...});
  // ... all other fields
  @override
  Widget build(BuildContext context) { ... }
}
```

---

_Reviewed: 2026-07-05_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
