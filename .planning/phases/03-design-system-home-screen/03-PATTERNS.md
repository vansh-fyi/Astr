# Phase 3: Design System + Home Screen - Pattern Map

**Mapped:** 2026-07-05
**Files analyzed:** 18 new/modified files
**Analogs found:** 17 / 18

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/core/design/app_colors.dart` | utility/config | — | `lib/app/theme/app_theme.dart` | role-match |
| `lib/core/design/app_typography.dart` | utility/config | — | `lib/app/theme/app_theme.dart` | role-match |
| `lib/core/design/app_spacing.dart` | utility/config | — | `lib/app/theme/app_theme.dart` | role-match |
| `lib/core/engine/models/sky_state.dart` | model | — | `lib/core/engine/models/condition_quality.dart` | exact |
| `lib/core/engine/models/condition_result.dart` | model | — | `lib/core/engine/models/condition_result.dart` (modify) | exact |
| `lib/core/services/qualitative/qualitative_condition_service.dart` | service | transform | `lib/core/services/qualitative/qualitative_condition_service.dart` (modify) | exact |
| `lib/features/dashboard/presentation/widgets/sky_state_background.dart` | component | request-response | `lib/features/dashboard/presentation/widgets/nebula_background.dart` | role-match |
| `lib/features/dashboard/presentation/widgets/hero_condition_label.dart` | component | request-response | `lib/features/dashboard/presentation/widgets/bortle_bar.dart` | partial |
| `lib/features/dashboard/presentation/widgets/conditions_card.dart` | component | CRUD | `lib/features/dashboard/presentation/widgets/dashboard_grid.dart` | exact |
| `lib/features/dashboard/presentation/widgets/visibility_mini_card.dart` | component | request-response | `lib/features/dashboard/presentation/widgets/bortle_bar.dart` | exact |
| `lib/features/dashboard/presentation/widgets/moon_mini_card.dart` | component | request-response | `lib/features/dashboard/presentation/widgets/dashboard_grid.dart` (moon section) | exact |
| `lib/features/dashboard/presentation/widgets/cloud_bar.dart` | component | request-response | `lib/features/dashboard/presentation/widgets/cloud_bar.dart` (restyle) | exact |
| `lib/features/dashboard/presentation/widgets/highlights_feed.dart` | component | event-driven | `lib/features/dashboard/presentation/widgets/highlights_feed.dart` (restyle) | exact |
| `lib/features/dashboard/presentation/home_screen.dart` | component | CRUD | `lib/features/dashboard/presentation/home_screen.dart` (refactor) | exact |
| `lib/app/router/scaffold_with_nav_bar.dart` | component | request-response | `lib/app/router/scaffold_with_nav_bar.dart` (token migration) | exact |
| `lib/core/widgets/glass_panel.dart` | utility | — | `lib/core/widgets/glass_panel.dart` (token migration) | exact |
| `lib/features/data_layer/models/zone_data.dart` | model | — | `lib/features/data_layer/models/zone_data.dart` (rename) | exact |
| `lib/features/data_layer/models/zone_cache_entry.dart` | model | — | `lib/features/data_layer/models/zone_cache_entry.dart` (rename) | exact |

---

## Pattern Assignments

### `lib/core/design/app_colors.dart` (utility/config)

**Analog:** `lib/app/theme/app_theme.dart`

**Imports pattern** (`app_theme.dart` lines 1-2):
```dart
import 'package:flutter/material.dart';
```

**Core pattern** (`app_theme.dart` lines 4-18):
```dart
class AppTheme {
  const AppTheme._();  // private constructor — static-only class

  static const Color deepCosmos = Color(0xFF020204);
  static const Color oledBlack = Color(0xFF000000);
  static const Color starlight = Color(0xFFFFFFFF);
  static const Color accentPurple = Color(0xFFB5179E);
  static const Color accentCyan = Color(0xFF4CC9F0);

  static const double glassBlur = 16;
}
```

**New file must follow this pattern exactly** — private constructor, all `static const`, one class per file. Replace legacy constants with the full semantic token table from UI-SPEC (all 17 `AppColors.*` constants) plus:

```dart
static const List<BoxShadow> glowShadow = [
  BoxShadow(color: Color(0x40FFFFFF), blurRadius: 1, offset: Offset(0, 0)),
  BoxShadow(color: Color(0xFF3A7FFF), blurRadius: 12.2, offset: Offset(0, 1)),
];
```

All `Color(0xAARRGGBB)` values come verbatim from `assets/design/color_system.csv` Flutter Color column. No new hex values invented.

---

### `lib/core/design/app_typography.dart` (utility/config)

**Analog:** `lib/app/theme/app_theme.dart`

**Core pattern** — same static-only class structure as `AppTheme`. Import `AppColors` from the same package:

```dart
import 'package:astr/core/design/app_colors.dart';
import 'package:flutter/material.dart';

class AppTypography {
  const AppTypography._();

  static const TextStyle display = TextStyle(
    fontFamily: 'Satoshi', fontSize: 72, fontWeight: FontWeight.w700,
    height: 1.1, color: AppColors.textPrimary,
  );
  // ... all 8 roles from UI-SPEC Typography table
}
```

Nav role uses `GoogleFonts.inter(...)` — not a `const` TextStyle. Define as a static getter:
```dart
static TextStyle get nav => GoogleFonts.inter(
  fontSize: 8, fontWeight: FontWeight.w400, height: 1.3,
  color: AppColors.textPrimary,
);
```

---

### `lib/core/design/app_spacing.dart` (utility/config)

**Analog:** `lib/app/theme/app_theme.dart` (constant block pattern)

**Core pattern:**
```dart
class AppSpacing {
  const AppSpacing._();

  // Base scale (doubles)
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // Figma-exact constants (doubles)
  static const double kPillHeight = 28;
  static const double kPillRadius = 17;
  static const double kCardRadius = 16;
  static const double kInnerRadius = 12;
  static const double kBadgeRadius = 70;
  // ... all kPillHeight through kLogoTopOffset from UI-SPEC Spacing table
}
```

---

### `lib/core/engine/models/sky_state.dart` (model, new file)

**Analog:** `lib/core/engine/models/condition_quality.dart` (lines 1-17)

**Copy this pattern exactly:**
```dart
// lib/core/engine/models/condition_quality.dart — full file (17 lines)
/// Represents the qualitative quality of observing conditions
enum ConditionQuality {
  /// Excellent conditions - ideal for all deep sky objects including faint galaxies
  excellent,
  // ...
  unknown,
}
```

**New file:**
```dart
/// Represents the 6 distinct visual sky states used for background selection and hero display.
///
/// Each state maps to a unique illustrated background asset and hero label.
enum SkyState {
  /// Excellent — Milky Way visible. Asset: assets/img/milky_way.jpg
  milkyWayVisible,

  /// Good — Clear starry sky. Asset: assets/img/starry_sky.jpg
  starrySkies,

  /// Fair — Planets visible. Asset: assets/img/planets.jpg
  planetsVisible,

  /// Poor — Few stars visible (darkness or moon limited). Asset: assets/img/few_stars.jpg
  fewStars,

  /// Blocker — Heavy cloud cover. Asset: assets/img/cloudy.jpg
  cloudy,

  /// Blocker — Excessive light pollution. Asset: assets/img/excessive_light_pollution.jpg
  tooMuchLight,
}
```

No imports needed — pure Dart enum.

---

### `lib/core/engine/models/condition_result.dart` (model, modify in-place)

**Analog:** `lib/core/engine/models/condition_result.dart` (current file, lines 1-29)

**Current constructor** (lines 7-13):
```dart
const ConditionResult({
  required this.quality,
  required this.shortSummary,
  required this.detailedAdvice,
  required this.statusColor,
});
```

**Add `skyState` field** — follow the existing `required this.X` named parameter pattern and add to `props` list:
```dart
// Add to imports (top of file)
import 'sky_state.dart';

// Add parameter to constructor
required this.skyState,

// Add field declaration (after existing fields)
final SkyState skyState;

// Add to props list (line 27)
List<Object?> get props => <Object?>[quality, shortSummary, detailedAdvice, statusColor, skyState];
```

---

### `lib/core/services/qualitative/qualitative_condition_service.dart` (service, modify)

**Analog:** `lib/core/services/qualitative/qualitative_condition_service.dart` (lines 38-43 show return pattern)

Each `ConditionResult(...)` constructor call already has named parameters. Add `skyState:` to each call site. The branching conditions (`cloudCover > 70`, `mpsas < 17.5`, score thresholds) already separate the 6 states — each branch just needs the `skyState:` argument added.

**Pattern to follow** (add `skyState:` to every `ConditionResult(...)` call in `_determineQualityAndAdvice`):
```dart
return ConditionResult(
  quality: ConditionQuality.excellent,
  shortSummary: 'Excellent',
  detailedAdvice: 'Milky Way Visible',
  statusColor: Colors.green,
  skyState: SkyState.milkyWayVisible,  // ADD THIS
);
```

---

### `lib/features/dashboard/presentation/widgets/sky_state_background.dart` (component, new file)

**Analog:** `lib/core/widgets/glass_panel.dart` lines 1-82 — full-bleed `Stack` + `RepaintBoundary` + `BackdropFilter` pattern. Also `lib/features/dashboard/presentation/widgets/dashboard_grid.dart` for `Image.asset` usage.

**Imports pattern** (from glass_panel.dart lines 1-2):
```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:astr/core/design/app_colors.dart';
import 'package:astr/core/engine/models/sky_state.dart';
```

**Core pattern** — `StatelessWidget`, `StackFit.expand`, layered Stack:
```dart
class SkyStateBackground extends StatelessWidget {
  const SkyStateBackground({super.key, required this.skyState});
  final SkyState skyState;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.surface),
        Image.asset(
          SkyStateAssets.pathFor(skyState),
          fit: BoxFit.cover,
          opacity: const AlwaysStoppedAnimation(0.5),  // per Pitfall 3 — never use Opacity widget
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x33448AFF), Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }
}

class SkyStateAssets {
  const SkyStateAssets._();
  static String pathFor(SkyState state) => switch (state) {
    SkyState.milkyWayVisible => 'assets/img/milky_way.jpg',
    SkyState.starrySkies     => 'assets/img/starry_sky.jpg',
    SkyState.planetsVisible  => 'assets/img/planets.jpg',
    SkyState.fewStars        => 'assets/img/few_stars.jpg',
    SkyState.cloudy          => 'assets/img/cloudy.jpg',
    SkyState.tooMuchLight    => 'assets/img/excessive_light_pollution.jpg',
  };
}
```

Default sky state while loading: `SkyState.starrySkies` (per Pitfall 5 in RESEARCH.md).

---

### `lib/features/dashboard/presentation/widgets/conditions_card.dart` (component, new file)

**Analog:** `lib/features/dashboard/presentation/widgets/dashboard_grid.dart` lines 78-178 — existing conditions card panel + cloud bar + rise/set Consumer pattern.

**Imports pattern** (dashboard_grid.dart lines 1-20):
```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:astr/core/design/app_colors.dart';
import 'package:astr/core/design/app_typography.dart';
import 'package:astr/core/design/app_spacing.dart';
import '../../../catalog/presentation/providers/rise_set_provider.dart';
import 'atmospherics_sheet.dart';
import 'cloud_bar.dart';
```

**Glass card pattern** (from `glass_panel.dart` lines 71-81, adapted to 2px blur per RESEARCH Pattern 2):
```dart
RepaintBoundary(
  child: ClipRRect(
    borderRadius: BorderRadius.circular(AppSpacing.kCardRadius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),   // 2px per Figma — NOT GlassPanel's 20px
      child: Container(
        width: AppSpacing.kConditionsCardWidth,
        height: AppSpacing.kConditionsCardHeight,
        decoration: BoxDecoration(
          color: AppColors.surfaceOverlay,
          border: Border.all(color: AppColors.borderPrimary),
          borderRadius: BorderRadius.circular(AppSpacing.kCardRadius),
        ),
        child: /* card contents */,
      ),
    ),
  ),
)
```

**Explore button pattern** (dashboard_grid.dart showed plain `onTap` → `showModalBottomSheet`):
```dart
GestureDetector(
  onTap: () => showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const AtmosphericsSheet(),
  ),
  child: Container(
    width: AppSpacing.kExploreButtonWidth,
    height: AppSpacing.kExploreButtonHeight,
    decoration: BoxDecoration(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(AppSpacing.kExploreButtonRadius),
    ),
    alignment: Alignment.center,
    child: Text('Explore', style: AppTypography.labelMd),
  ),
)
```

**Rise/set Consumer pattern** (dashboard_grid.dart lines 135-174):
```dart
Consumer(
  builder: (context, ref, child) {
    final sunState = ref.watch(objectDetailNotifierProvider('sun'));
    final moonState = ref.watch(objectDetailNotifierProvider('moon'));
    // ... get rise/set times from riseSetProvider
    return Row(children: [
      Expanded(child: TimeCard(label: 'SUNRISE', time: sunRise)),
      // ...
    ]);
  },
)
```

Use `AppSpacing.kSunMoonCellWidth` / `kSunMoonCellHeight` for each time cell. Replace `TimeCard` with inline sun/moon cell using `AppColors.surfaceGlass`, `AppColors.borderSubtle`, `AppTypography.micro` for label, `AppTypography.labelMd` for value.

---

### `lib/features/dashboard/presentation/widgets/visibility_mini_card.dart` (component, new file)

**Analog:** `lib/features/dashboard/presentation/widgets/bortle_bar.dart` lines 1-141

**Imports pattern** (bortle_bar.dart lines 1-3):
```dart
import 'package:flutter/material.dart';
import 'package:astr/core/design/app_colors.dart';
import 'package:astr/core/design/app_typography.dart';
import 'package:astr/core/design/app_spacing.dart';
import '../../domain/entities/light_pollution.dart';
```

**Constructor pattern** (bortle_bar.dart lines 6-12) — `StatelessWidget` (no tap handler per D-14):
```dart
class VisibilityMiniCard extends StatelessWidget {
  const VisibilityMiniCard({super.key, required this.lightPollution});
  final LightPollution lightPollution;
```

**Zone pill pattern** (bortle_bar.dart lines 46-69 — restyle with tokens):
```dart
Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 11, vertical: 4,
  ),
  decoration: BoxDecoration(
    color: AppColors.zonePillFill,          // 0x333A96FF
    borderRadius: BorderRadius.circular(AppSpacing.kBadgeRadius),
    border: Border.all(color: AppColors.accent),
  ),
  child: Text(
    'Zone ${lightPollution.zone}',
    style: AppTypography.micro.copyWith(
      color: AppColors.zonePillText,        // 0xFFB0D5FF
      fontWeight: FontWeight.w700,
    ),
  ),
)
```

**Rating bars pattern** (bortle_bar.dart lines 106-128 — restyle with tokens + glow shadow):
```dart
Row(
  children: List.generate(5, (index) {
    final int activeBars = ((lightPollution.visibilityIndex - 1) / 2).floor().clamp(0, 5);
    final bool isActive = index < activeBars;
    return Container(
      width: (AppSpacing.kRatingBarsWidth - 4 * AppSpacing.kRatingBarGap) / 5,
      height: AppSpacing.kRatingBarHeight,
      margin: index < 4 ? const EdgeInsets.only(right: AppSpacing.kRatingBarGap) : null,
      decoration: BoxDecoration(
        color: isActive ? AppColors.ratingBarActive : AppColors.ratingBarInactive,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive ? AppColors.glowShadow : null,
      ),
    );
  }),
)
```

**Sky type label** — replace `_getShortLabel` with the same logic, output matches UI-SPEC (e.g., "Rural Sky"):
```dart
String _getSkyLabel(int visibilityIndex) {
  if (visibilityIndex <= 2) return 'Dark Sky';
  if (visibilityIndex <= 4) return 'Rural Sky';
  if (visibilityIndex <= 6) return 'Suburban Sky';
  return 'Urban Sky';
}
```

Confirm exact label from `figma/home/Home.png` before finalizing (Open Question #2 in RESEARCH.md).

---

### `lib/features/dashboard/presentation/widgets/moon_mini_card.dart` (component, new file)

**Analog:** `lib/features/dashboard/presentation/widgets/dashboard_grid.dart` lines 201-268 (moon panel section)

**Core pattern** — extract the moon section from `DashboardGrid._DashboardGridState` into a standalone `StatelessWidget`:

```dart
class MoonMiniCard extends StatelessWidget {
  const MoonMiniCard({super.key, required this.moonPhaseInfo});
  final MoonPhaseInfo moonPhaseInfo;

  @override
  Widget build(BuildContext context) {
    // No tap handler — display only per D-14
    // Glass card wrapper: same RepaintBoundary + ClipRRect + BackdropFilter(sigmaX:2) as ConditionsCard
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.kCardRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Container(
            width: AppSpacing.kMiniCardWidth,
            height: AppSpacing.kMiniCardHeight,
            decoration: BoxDecoration(
              color: AppColors.surfaceOverlay,
              border: Border.all(color: AppColors.borderPrimary),
              borderRadius: BorderRadius.circular(AppSpacing.kCardRadius),
            ),
            child: /* moon content */,
          ),
        ),
      ),
    );
  }
}
```

**Moon asset + label helpers** (dashboard_grid.dart lines 275-324) — copy `_getMoonAsset` and `_getMoonPhaseLabel` methods verbatim; convert to static methods in the new widget class.

---

### `lib/features/dashboard/presentation/widgets/cloud_bar.dart` (component, restyle)

**Analog:** `lib/features/dashboard/presentation/widgets/cloud_bar.dart` (current file, lines 1-95)

**Preserve:** Constructor signature (`cloudCoverPercentage`, `isLoading`, `errorMessage`), `StatefulWidget` structure, `_CloudBarState` class.

**Replace** (hardcoded → token):

| Current (line) | Replace with |
|----------------|-------------|
| `GlassPanel(child: ...)` (line 25) | Custom glass inner container: `Container(decoration: BoxDecoration(color: AppColors.surfaceGlass, border: Border.all(color: AppColors.borderSubtle), borderRadius: BorderRadius.circular(AppSpacing.kInnerRadius)))` |
| `Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white)` (line 33) | `AppTypography.labelMd` |
| `Colors.white.withOpacity(0.1)` track (line 62) | `color: AppColors.cloudTrack` |
| `colors: [Colors.blue, Colors.blueAccent]` gradient fill (lines 75-77) | `color: AppColors.accentSecondary` (solid, no gradient) + `boxShadow: AppColors.glowShadow` |
| `BorderRadius.circular(4)` (lines 63, 74) | `BorderRadius.circular(AppSpacing.kInnerRadius)` for outer; `12` for fill |
| `height: 8` track (line 60) | `AppSpacing.kCloudTrackHeight` |

---

### `lib/features/dashboard/presentation/widgets/highlights_feed.dart` (component, restyle)

**Analog:** `lib/features/dashboard/presentation/widgets/highlights_feed.dart` (current file, lines 1-161)

**Preserve:** `ConsumerWidget` structure, `astronomyProvider` watch, `HighlightsLogic.selectTop3`, `highlightTimeProvider`, `showModalBottomSheet(CelestialDetailSheet(...))` tap handler.

**Replace** (hardcoded → token):

| Current | Replace with |
|---------|-------------|
| `Colors.white.withOpacity(0.5)` section label (line 38) | `AppColors.textMuted` |
| `fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5` (lines 39-41) | `AppTypography.micro.copyWith(letterSpacing: 1.5)` |
| `GlassPanel(enableBlur: false, ...)` per row (line 71) | Replace with token glass card: `Container(decoration: BoxDecoration(color: AppColors.surfaceOverlay, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(AppSpacing.kCardRadius)))` |
| `Colors.orange.withOpacity(0.1)` icon box (line 93) | Keep orange tint (no token for this) — use `Colors.orange.withValues(alpha: 0.1)` |
| `Colors.white` object name (line 113) | `AppColors.textPrimary` |
| `fontSize: 14, fontWeight: FontWeight.w600` (lines 114-115) | `AppTypography.labelMd` |
| `Colors.white.withOpacity(0.7)` time text (line 128) | `AppColors.textMuted` |
| `fontSize: 12` (line 129) | `AppTypography.labelMd` |
| `Colors.white.withOpacity(0.3)` chevron (line 154) | `AppColors.textMuted` |

---

### `lib/features/dashboard/presentation/home_screen.dart` (component, in-place refactor)

**Analog:** `lib/features/dashboard/presentation/home_screen.dart` (current file, lines 1-343)

**Preserve** (lines 37-98 class fields + initState + _handleDateChange):
- `_bannerController`, `_bannerTimer`, `_lastSelectedDate`, `_isFutureDate`
- `_hasHandledLaunchToast`, `_hasHandledLaunchLocation`
- `SystemChrome.setSystemUIOverlayStyle(...)` in `initState` (lines 50-60)
- `_handleDateChange` method (lines 74-97)
- `LaunchResult` switch + `addPostFrameCallback` blocks (lines 114-179)
- `ref.listen(astrContextProvider, ...)` (lines 182-188)
- `ref.read(astrContextProvider.notifier).refreshLocation()` and `ref.read(weatherProvider.notifier).refresh()` in refresh handler

**Replace widget tree** (lines 190-342) with new Stack layout per UI-SPEC Home Screen Layout Order:
```dart
return Scaffold(
  extendBody: true,
  extendBodyBehindAppBar: true,
  backgroundColor: AppColors.surface,
  body: Stack(
    children: [
      // z=0: Background
      conditionAsync.when(
        data: (result) => SkyStateBackground(skyState: result.skyState),
        loading: () => const SkyStateBackground(skyState: SkyState.starrySkies),
        error: (_, __) => const SkyStateBackground(skyState: SkyState.starrySkies),
      ),
      // z=1: Scrollable content
      SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.only(
            top: AppSpacing.kHeaderContentOffset,
            bottom: 70 + MediaQuery.of(context).padding.bottom + AppSpacing.md,
          ),
          child: Column(children: [
            // Hero section
            HeroConditionLabel(conditionResult: conditionAsync.valueOrNull),
            SizedBox(height: AppSpacing.lg),
            // Conditions card
            ConditionsCard(),
            SizedBox(height: AppSpacing.md),
            // Mini-cards row
            Row(children: [VisibilityMiniCard(...), SizedBox(width: AppSpacing.md), MoonMiniCard(...)]),
            SizedBox(height: AppSpacing.md),
            // Highlights
            const HighlightsFeed(),
          ]),
        ),
      ),
    ],
  ),
);
```

**Date banner** — restyle `Colors.indigo` → `AppColors.accent`, preserve `SizeTransition` animation logic.

---

### `lib/app/router/scaffold_with_nav_bar.dart` (component, token migration)

**Analog:** `lib/app/router/scaffold_with_nav_bar.dart` (current file, lines 1-473)

**Preserve:** All logic — `NavigationShell`, `_onTap`, `NavBarClipper`, `NotchShinePainter`, `_NavBarItem`, date picker, `showGlassToast`, `showModalBottomSheet(LocationSheet)`.

**Replace** (hardcoded → token):

| Current | Line | Replace with |
|---------|------|-------------|
| `AppTheme.deepCosmos.withOpacity(0.7)` header bg | 66 | `AppColors.surfaceGlass` |
| `Colors.white.withOpacity(0.1)` header border | 68-70 | `AppColors.borderSurface` |
| `Colors.blueAccent` location icon (saved) | 96 | `AppColors.accent` |
| `Colors.white.withOpacity(0.9)` / `Colors.blueAccent` location text | 103-107 | `AppColors.textPrimary` / `AppColors.accent` |
| `Colors.white70` chevron icons | 146, 220 | `AppColors.textMuted` |
| `Colors.blueAccent` date pill (non-today) | 193 | `AppColors.accent` |
| `Colors.white.withOpacity(0.9)` date pill (today) | 193 | `AppColors.textPrimary` |
| `Colors.blueAccent` date picker primary | 176 | `AppColors.accent` |
| `AppTheme.deepCosmos.withOpacity(0.8)` nav bar bg | 260 | `AppColors.surfaceGlass` |
| `AppTheme.glassBlur` nav bar blur | 255-256 | `16.0` (explicit constant — `glassBlur` being removed from AppTheme) |
| `Colors.blueAccent` FAB bg | 244 | `AppColors.accent` |
| `Colors.blueAccent.withOpacity(...)` notch shine | 390-394 | `AppColors.accent.withValues(alpha: ...)` |
| `Colors.white.withOpacity(0.5)` inactive tab | 444 | `AppColors.textPrimary.withValues(alpha: 0.5)` |
| `fontSize: 10` tab label | 464 | `AppTypography.labelSm` (apply as style) — note: nav uses Inter via `GoogleFonts.inter()` |

GlassPanel header pills: update `GlassPanel` border to use `AppColors.borderSurface`; add optional `backgroundColor` parameter to `GlassPanel` for pill vs card contexts.

---

### `lib/features/data_layer/models/zone_data.dart` (model, rename)

**Analog:** `lib/features/data_layer/models/zone_data.dart` (current file, lines 22-135)

**Rename field** `bortleClass` → `astrZone` in:
- Constructor parameter (line 29): `required this.bortleClass` → `required this.astrZone`
- Field declaration (line 91): `final int bortleClass;` → `final int astrZone;`
- `copyWith` method (line 107): parameter + fallback `this.bortleClass` → `this.astrZone`
- `==` operator (lines 121-125): `other.bortleClass == bortleClass` → `other.astrZone == astrZone`
- `hashCode` (line 129): `Object.hash(bortleClass, ratio, sqm)` → `Object.hash(astrZone, ratio, sqm)`
- `toString` (line 132): update string template
- `fromBytes` factory (lines 54-77): `bortleClass: bortleClass` → `astrZone: bortleClass` (variable still named `bortleClass` in method body is fine; change constructor call key)

Update all doc comments from "Bortle" language to "Astr Zone" language.

---

## Shared Patterns

### Glassmorphism Card (2px blur) — for ConditionsCard, VisibilityMiniCard, MoonMiniCard

**Source:** `lib/core/widgets/glass_panel.dart` lines 71-81 (structure), adapted for 2px blur per RESEARCH.md Pattern 2.

**Apply to:** `conditions_card.dart`, `visibility_mini_card.dart`, `moon_mini_card.dart`

```dart
import 'dart:ui';

RepaintBoundary(
  child: ClipRRect(
    borderRadius: BorderRadius.circular(AppSpacing.kCardRadius),  // 16px
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),  // Figma spec — NOT GlassPanel's 20px
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceOverlay,              // 0x800C0F11
          border: Border.all(color: AppColors.borderPrimary, width: 1),  // Blue/800
          borderRadius: BorderRadius.circular(AppSpacing.kCardRadius),
        ),
        child: child,
      ),
    ),
  ),
)
```

**Critical:** Do NOT use `GlassPanel` for home screen cards. `GlassPanel` uses 20px blur and `Color(0xFF121212)`. Home screen cards need 2px blur and `AppColors.surfaceOverlay`.

### `.withValues(alpha: x)` over `.withOpacity(x)`

**Source:** `lib/features/dashboard/presentation/widgets/dashboard_grid.dart` line 115

**Apply to:** Every file in Phase 3 migration. `withOpacity()` is deprecated in Flutter 3.x.

```dart
// WRONG — deprecated
Colors.white.withOpacity(0.5)

// CORRECT
Colors.white.withValues(alpha: 0.5)
AppColors.textPrimary.withValues(alpha: 0.5)
```

### `showModalBottomSheet` pattern

**Source:** `lib/features/dashboard/presentation/widgets/dashboard_grid.dart` lines 84-90 and `lib/app/router/scaffold_with_nav_bar.dart` lines 82-87

**Apply to:** Explore button → AtmosphericsSheet, highlights row → CelestialDetailSheet, location pill → LocationSheet

```dart
showModalBottomSheet(
  context: context,
  useRootNavigator: true,
  backgroundColor: Colors.transparent,
  isScrollControlled: true,
  builder: (BuildContext context) => const AtmosphericsSheet(),
);
```

### Token import block

**Apply to:** Every new or modified file in `lib/` that uses design tokens

```dart
import 'package:astr/core/design/app_colors.dart';
import 'package:astr/core/design/app_typography.dart';
import 'package:astr/core/design/app_spacing.dart';
```

### Riverpod AsyncValue.when + loading default

**Source:** `lib/features/dashboard/presentation/home_screen.dart` lines 284-300, and `lib/features/dashboard/presentation/widgets/highlights_feed.dart` lines 21-52

**Apply to:** `SkyStateBackground` consumer, `HeroConditionLabel` consumer

```dart
conditionAsync.when(
  data: (result) => /* real widget */,
  loading: () => /* placeholder — use SkyState.starrySkies or "--" text */,
  error: (_, __) => /* same placeholder as loading */,
)
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/features/dashboard/presentation/widgets/hero_condition_label.dart` | component | request-response | No existing "large hero text + subtitle + badge pill" pattern; closest is `bortle_bar.dart` mid-section text but structurally different. Use RESEARCH.md Code Examples §Hero Section Assembly as the authoritative pattern. |

---

## Metadata

**Analog search scope:** `lib/app/`, `lib/core/`, `lib/features/dashboard/`, `lib/features/data_layer/`
**Files scanned:** 11 analog files read directly
**Pattern extraction date:** 2026-07-05
