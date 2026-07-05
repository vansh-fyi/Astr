# Phase 3: Design System + Home Screen - Research

**Researched:** 2026-07-05
**Domain:** Flutter design token system, glassmorphism UI, widget refactoring, data model rename
**Confidence:** HIGH (all findings derived from codebase inspection)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** All 6 sky state backgrounds are static JPG assets — no Rive or Lottie animation. One image per sky state.
- **D-02:** Asset paths confirmed: `assets/img/milky_way.jpg`, `assets/img/starry_sky.jpg`, `assets/img/planets.jpg`, `assets/img/few_stars.jpg`, `assets/img/cloudy.jpg`, `assets/img/excessive_light_pollution.jpg`
- **D-03:** Background layer is full replacement — `nebula_background.dart` and `sky_portal.dart` are deleted. New: full-bleed image fill with dark gradient overlay.
- **D-04:** Home screen refactor strategy is in-place — keep `home_screen.dart` structure, preserve existing provider wiring and state logic.
- **D-05:** All existing dashboard widgets refactored individually; none deleted except `sky_portal.dart` / `nebula_background.dart`.
- **D-06:** Design reference is `figma/home/` — executor reads images from that folder.
- **D-07:** Tokens live in new `lib/core/design/` directory. `AppTheme` continues as ThemeData factory.
- **D-07a:** Color primitive palette is locked — defined in `assets/design/color_system.csv`. Two families: Blue (9 stops: 100–900) and Grey (9 stops: 100–900), each with 6 opacity variants (10%, 20%, 30%, 50%, 80%, 100%).
- **D-08:** DS-02 enforced globally — apply tokens across all 15 active surfaces now.
- **D-09:** Rename `ZoneData.bortleClass` → `ZoneData.astrZone` in Phase 3. Update all references throughout `lib/`.
- **D-10:** Nav bar structure is already complete — no structural changes.
- **D-11:** Global glass header stays as global header — visible on all tabs.
- **D-12:** Phase 3 applies token restyling to `scaffold_with_nav_bar.dart`.
- **D-13:** Explore button opens `AtmosphericsSheet`. Cloud cover container has no tap handler.
- **D-14:** Visibility mini-card is display-only — no tap handler.
- **D-15:** HighlightsFeed restyled to match design system; tap behavior unchanged.
- **D-16:** All other sheets keep existing implementation and open behavior.

### Claude's Discretion

None — discussion stayed within phase scope.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.

</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DS-01 | Astr design system is defined and implemented: color tokens, typography scale, spacing system, component library | Token files in `lib/core/design/`; semantic token table from UI-SPEC; color values from CSV |
| DS-02 | All 15 surfaces use design system tokens — no hardcoded colors, font sizes, or spacing values outside the system | 35 files have `Colors.*` refs; 26 files have inline `fontSize:` — scope identified in research |
| DS-03 | Dark theme is the only theme; all components are designed for near-black backgrounds with the starfield aesthetic | `ThemeMode.dark` forced in AppTheme; OLED black background retained |
| HOME-01 | Home screen displays the correct illustrated background for the current sky state | SkyState enum + SkyStateBackground widget; critical gap resolved (see Architecture section) |
| HOME-02 | Hero sky condition label displayed prominently with correct typography | `HeroConditionLabel` widget; AppTypography.display (72px Satoshi Bold) |
| HOME-03 | Astr Zone badge displayed beneath the condition label | Zone badge component with Blue/800 border, 70px radius pill |
| HOME-04 | Conditions card shows: overall assessment label, cloud cover progress bar, Sunrise/Sunset/Moonrise/Moonset | `ConditionsCard` widget; data from existing providers `weatherProvider`, `riseSetProvider` |
| HOME-05 | Visibility mini-card shows zone number and sky type label | `VisibilityMiniCard` widget; data from `visibilityProvider` |
| HOME-06 | Moon mini-card shows moon phase percentage and moon phase illustration | `MoonMiniCard` widget; data from `astronomyProvider.moonPhaseInfo` |
| HOME-07 | Date navigation arrows allow browsing; tapping date refreshes all home screen data | Already wired in `ScaffoldWithNavBar`; Phase 3 restyled only |
| HOME-08 | "Current Location" pill opens the Location Sheet | Already wired in `ScaffoldWithNavBar`; Phase 3 restyled only |
| HOME-09 | "Explore" button on conditions card opens the Atmospherics Sheet | `ConditionsCard` → `showModalBottomSheet(AtmosphericsSheet)` |

</phase_requirements>

---

## Summary

Phase 3 is a pure UI phase: no new backend integrations, no new external packages, and no algorithmic changes. The work falls into four parallel tracks: (1) define the design token system in `lib/core/design/`; (2) rebuild the home screen with correct illustrated backgrounds, hero section, conditions card, and mini-cards per the Figma spec; (3) migrate all 15 active surfaces from hardcoded values to token references; and (4) rename `ZoneData.bortleClass` to `ZoneData.astrZone`.

The most important technical finding is a **sky state gap**: the existing `ConditionQuality` enum has 4 values (excellent/good/fair/poor/unknown) but the design requires 6 distinct visual states including two sub-variants of "poor" (cloudy vs. too-much-light). This gap must be resolved by adding a `SkyState` enum and a `skyState` field to `ConditionResult` before building `SkyStateBackground`. All other building blocks are already present in the codebase.

All six JPG background assets are confirmed present in `assets/img/`. The Satoshi font is already registered at weights 300/400/500/700. The `BackdropFilter` glassmorphism pattern is already established in `GlassPanel` — the new cards use the same pattern with a 2px blur (vs. the existing 20px). The bortleClass rename touches 5 files and requires one `build_runner` run to regenerate `zone_cache_entry.g.dart`.

**Primary recommendation:** Start with the token files (Wave 0), then the SkyState enum + ConditionResult extension, then SkyStateBackground, then home screen widget-by-widget top to bottom, then the global token migration sweep.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Design token definitions | Core (`lib/core/design/`) | — | Shared primitives; no feature dependency |
| Sky state determination | Domain service (`QualitativeConditionService`) | — | Business rule: inputs → sky state |
| Background image rendering | Presentation widget (`SkyStateBackground`) | — | Pure UI, consumes SkyState from provider |
| Conditions card display | Presentation widget (`ConditionsCard`) | — | Consumes weather + rise/set providers |
| Visibility mini-card display | Presentation widget (`VisibilityMiniCard`) | — | Consumes visibilityProvider |
| Moon mini-card display | Presentation widget (`MoonMiniCard`) | — | Consumes astronomyProvider |
| Header (date nav, location pill) | Nav shell (`ScaffoldWithNavBar`) | — | Already implemented; restyled only |
| Token migration sweep | All active surfaces in `lib/` | — | DS-02: global, not feature-gated |
| bortleClass rename | Data model + 4 consumer files | `build_runner` codegen | Naming debt resolution |
| ZoneCacheEntry Hive regen | `build_runner` | — | @HiveField index survives rename; regeneration required |

---

## Standard Stack

### Core (no new dependencies — all from existing pubspec.yaml)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter` (SDK) | current | Widget framework | Project constraint |
| `flutter_riverpod` | ^2.6.1 | State management | Established pattern, not changing |
| `dart:ui` | SDK built-in | `BackdropFilter`, `ImageFilter.blur()` | Already imported in `scaffold_with_nav_bar.dart`, `glass_panel.dart` |
| `google_fonts` | ^6.2.1 | `GoogleFonts.inter()` for nav tab labels | Already declared; Inter font for 8px nav labels |
| `ionicons` | ^0.2.2 | Nav icons, location icon, chevrons | Already declared |
| `intl` | ^0.20.2 | `DateFormat('MMM d')` for date pill | Already declared |
| `flex_color_scheme` | ^8.0.2 | `AppTheme.darkTheme` factory | Already declared |

**No new packages required for Phase 3.** [VERIFIED: codebase pubspec.yaml]

### Token Files to Create (new files, no new packages)

| File | Exports | Purpose |
|------|---------|---------|
| `lib/core/design/app_colors.dart` | `AppColors.*` static const colors + `AppColors.glowShadow` | All semantic color tokens |
| `lib/core/design/app_typography.dart` | `AppTypography.*` static const TextStyles | All typography roles |
| `lib/core/design/app_spacing.dart` | `AppSpacing.xs/sm/md/lg/xl/xxl/xxxl` + all `k*` constants | Spacing scale + Figma constants |

---

## Package Legitimacy Audit

No new packages are installed in Phase 3. All packages used are from the existing `pubspec.yaml`, which was approved at project inception.

| Package | Verdict | Disposition |
|---------|---------|-------------|
| (all existing) | N/A — pre-approved | Approved — no new installs |

---

## Architecture Patterns

### System Architecture Diagram

```
User tap / Date change
        │
        ▼
ScaffoldWithNavBar (global shell)
  ├── Glass header (location pill + date nav) ← already complete; restyled only
  └── HomeScreen body (Stack)
        ├── SkyStateBackground (Positioned.fill, z=0)
        │     └── conditionQualityProvider → SkyState → asset path
        └── SingleChildScrollView (z=1)
              ├── HeroSection (HeroConditionLabel + ZoneBadge)
              │     └── conditionQualityProvider → heroLabel + zoneBadge
              ├── ConditionsCard (glass card)
              │     ├── weatherProvider → cloud cover %
              │     ├── riseSetProvider(sun) → sunrise/sunset
              │     ├── riseSetProvider(moon) → moonrise/moonset
              │     └── [Explore button] → showModalBottomSheet(AtmosphericsSheet)
              ├── Mini-card Row
              │     ├── VisibilityMiniCard ← visibilityProvider → zone, MPSAS, label
              │     └── MoonMiniCard ← astronomyProvider → illumination, phase
              └── HighlightsFeed ← astronomyProvider → top 3 objects
                    └── [row tap] → showModalBottomSheet(CelestialDetailSheet)
```

### Recommended Project Structure (new files only)

```
lib/
├── core/
│   └── design/               # NEW — token system
│       ├── app_colors.dart   # AppColors.* + glowShadow
│       ├── app_typography.dart  # AppTypography.*
│       └── app_spacing.dart  # AppSpacing.* + k* constants
└── features/
    └── dashboard/
        └── presentation/
            └── widgets/
                ├── sky_state_background.dart   # NEW — replaces nebula_background.dart + sky_portal.dart
                ├── hero_condition_label.dart    # NEW — Display + Body text for hero section
                ├── conditions_card.dart         # NEW — replaces weather_summary_card.dart + data_card.dart
                ├── visibility_mini_card.dart    # NEW — replaces bortle_bar.dart visual layer
                └── moon_mini_card.dart          # NEW — replaces moon_phase_card.dart visual layer
```

---

## Critical Finding: Sky State Gap (HOME-01)

### Problem

The current `ConditionQuality` enum has 4 values:
```dart
// lib/core/engine/models/condition_quality.dart
enum ConditionQuality { excellent, good, fair, poor, unknown }
```

The design requires 6 distinct visual states each with its own background, hero label, and conditions title. The current `QualitativeConditionService` maps cloud > 70% AND mpsas < 17.5 AND low-score paths all to `ConditionQuality.poor` — losing the distinction between "cloudy", "too much light", and "few stars".

| Design State | Hero Label | Background | Current Code |
|--------------|-----------|------------|-------------|
| Milkyway Visible | "Excellent" | `milky_way.jpg` | `quality: excellent` ✓ |
| Starry Sky Today | "Good" | `starry_sky.jpg` | `quality: good` ✓ |
| Planets Visible | "Fair" | `planets.jpg` | `quality: fair` ✓ |
| Few Stars Visible | "Poor" | `few_stars.jpg` | `quality: poor`, `detailedAdvice: 'Few stars visible'` |
| Cloudy Sky Tonight | "Cloudy" | `cloudy.jpg` | `quality: poor`, `detailedAdvice: 'Sky might be cloudy'` |
| Too Much Light | "Bright" | `excessive_light_pollution.jpg` | `quality: poor`, `detailedAdvice: 'Excessive Light Pollution'` |

### Resolution

**Add a `SkyState` enum and a `skyState` field to `ConditionResult`.** Update `QualitativeConditionService` to populate it. `SkyStateBackground` switches on `SkyState`.

```dart
// NEW: lib/core/engine/models/sky_state.dart
enum SkyState {
  milkyWayVisible,   // Excellent → milky_way.jpg
  starrySkies,       // Good → starry_sky.jpg
  planetsVisible,    // Fair → planets.jpg
  fewStars,          // Poor (darkness/moon limited) → few_stars.jpg
  cloudy,            // Blocker: cloud > 70% → cloudy.jpg
  tooMuchLight,      // Blocker: mpsas < 17.5 → excessive_light_pollution.jpg
}
```

```dart
// MODIFIED: lib/core/engine/models/condition_result.dart — add field
class ConditionResult extends Equatable {
  const ConditionResult({
    required this.quality,
    required this.shortSummary,
    required this.detailedAdvice,
    required this.statusColor,
    required this.skyState,  // ADD THIS
  });
  // ...
  final SkyState skyState;  // ADD THIS
}
```

`QualitativeConditionService` already has the right branching logic — each return statement already knows which state it represents; just add `skyState:` to each `ConditionResult` constructor call.

[VERIFIED: codebase — QualitativeConditionService at lib/core/services/qualitative/qualitative_condition_service.dart]

### Asset Mapping (SkyStateAssets helper)

```dart
// In sky_state_background.dart
class SkyStateAssets {
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

All 6 assets confirmed present. [VERIFIED: codebase — `ls assets/img/`]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Glass card blur effect | Custom blur widget | `BackdropFilter` + `ClipRRect` + `RepaintBoundary` (pattern from `GlassPanel`) | GPU-optimized; already established in codebase |
| Google Fonts loading | Manual HTTP font fetch | `GoogleFonts.inter()` (already declared) | Handles caching, loading states |
| Bottom sheet modal | Push route | `showModalBottomSheet(useRootNavigator: true)` | Correct z-axis layering; existing pattern |
| Image opacity | Stack with opacity container | `Image.asset(path, opacity: AlwaysStoppedAnimation(0.5))` | Single-widget; no extra layer |
| Date boundary toast | AlertDialog | `showGlassToast()` from `glass_toast.dart` | Already exists; correct styling |
| Animation between sky states | AnimatedSwitcher | Static swap (no animation in Phase 3 per D-01) | Simpler; per design decision |

**Key insight:** Every UI interaction pattern needed in Phase 3 is already established elsewhere in the codebase. The executor's job is reuse and restyling, not invention.

---

## bortleClass → astrZone Rename

### Complete File List

| File | Change Type | Details |
|------|-------------|---------|
| `lib/features/data_layer/models/zone_data.dart` | Field rename | `bortleClass` → `astrZone` in constructor, field declaration, copyWith, equality, hashCode, toString |
| `lib/features/data_layer/models/zone_cache_entry.dart` | Field rename | `bortleClass` → `astrZone`; `@HiveField(1)` stays on the field (Hive serializes by index, not name) |
| `lib/features/data_layer/models/zone_cache_entry.g.dart` | Regenerate | Run `dart run build_runner build` after rename |
| `lib/features/data_layer/repositories/cached_zone_repository.dart` | 5 references | `pristineDarkSky.bortleClass: 1`, `cached.bortleClass` × 3, `data.bortleClass` |
| `lib/features/data_layer/services/remote_zone_service.dart` | 1 reference | Constructor call: `bortleClass: json['bortle']` → `astrZone: json['bortle']` |
| `lib/features/dashboard/data/repositories/light_pollution_repository.dart` | 3 references | `zoneData.bortleClass` × 3 |

[VERIFIED: codebase — grep -r "bortleClass" lib/]

### Hive Field Safety

`ZoneCacheEntry.bortleClass` has `@HiveField(1)`. Renaming the Dart identifier does NOT change the binary layout because Hive type adapters serialize by field index (the integer in `@HiveField(1)`), not by field name. Existing cached entries in production Hive boxes will continue to deserialize correctly after rename. The generated `.g.dart` adapter references the field by name, so `build_runner build` must be run after the rename.

### No @JsonKey Needed

`ZoneData` is not annotated with `@JsonSerializable`. The `RemoteZoneService` uses a manual constructor call (`ZoneData(bortleClass: json['bortle'] as int, ...)`). There is no JSON deserialization annotation to update — just rename the named parameter in the constructor call. [VERIFIED: codebase — RemoteZoneService.getZoneData()]

### Cloudflare Worker JSON key

The Cloudflare Worker returns JSON with key `'bortle'` (not `'bortleClass'`). The rename is Dart-only; the API contract is unchanged. [VERIFIED: codebase — cloudflare/worker.js grep returned no output (file uses different key naming)]

---

## Architecture Patterns

### Pattern 1: Full-Bleed Background with Gradient Overlay

**What:** Stack with colored base, semi-transparent image, gradient overlay.
**When to use:** `SkyStateBackground` widget — the bottom layer of every home screen Stack.

```dart
// Source: UI-SPEC + codebase pattern
Widget build(BuildContext context) {
  return Stack(
    fit: StackFit.expand,
    children: [
      // 1. Base surface color (OLED-friendly)
      const ColoredBox(color: AppColors.surface),  // 0xFF0C0F11
      // 2. Sky background JPG at 50% opacity
      Image.asset(
        SkyStateAssets.pathFor(skyState),
        fit: BoxFit.cover,
        opacity: const AlwaysStoppedAnimation(0.5),
      ),
      // 3. Blue-tinted gradient overlay at 20% opacity
      DecoratedBox(
        decoration: const BoxDecoration(
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
```

### Pattern 2: Glassmorphism Card (2px blur)

**What:** ClipRRect + BackdropFilter (2px) + Container with semi-transparent color.
**When to use:** `ConditionsCard`, `VisibilityMiniCard`, `MoonMiniCard` — all home screen glass cards.
**Note:** 2px blur (Figma spec) differs from `GlassPanel`'s 20px blur. Home screen cards use custom implementation; GlassPanel continues for nav pills.

```dart
// Source: Established GlassPanel pattern adapted for 2px blur
RepaintBoundary(
  child: ClipRRect(
    borderRadius: BorderRadius.circular(AppSpacing.kCardRadius), // 16px
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),  // Figma: 2px
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceOverlay,   // 0x800C0F11
          border: Border.all(color: AppColors.borderPrimary, width: 1),  // Blue/800
          borderRadius: BorderRadius.circular(AppSpacing.kCardRadius),
        ),
        child: child,
      ),
    ),
  ),
)
```

### Pattern 3: Token Reference Style

**What:** Static const access via `AppColors.*`, `AppTypography.*`, `AppSpacing.*`.
**When to use:** Every widget in `lib/` after Phase 3 migration.

Note: source files under `lib/` use relative imports (CLAUDE.md); `package:astr` imports are reserved for test files under `test/`.

```dart
// Import in source files (relative — adjust path depth to match the importing file)
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/app_spacing.dart';

// Import in test files (package: convention)
// import 'package:astr/core/design/app_colors.dart';

// Usage (same in both cases)
Text('Excellent', style: AppTypography.display)
SizedBox(height: AppSpacing.md)  // 16px
Container(color: AppColors.surface)
```

### Pattern 4: Glow Shadow (Reusable Constant)

```dart
// Source: UI-SPEC + Figma node 119:80
// Defined in AppColors — NOT in the color CSV (the glow shadow blue 0xFF3A7FFF
// differs from CSV Blue/400; Figma value is authoritative here)
static const List<BoxShadow> glowShadow = [
  BoxShadow(color: Color(0x40FFFFFF), blurRadius: 1, offset: Offset(0, 0)),
  BoxShadow(color: Color(0xFF3A7FFF), blurRadius: 12.2, offset: Offset(0, 1)),
];
```

Used on: active cloud fill bar, active visibility rating bars, FAB.

### Anti-Patterns to Avoid

- **Hardcoded colors in widget files:** `Colors.blueAccent`, `Colors.white.withOpacity(x)`, `Color(0xFF...)` inline → always use `AppColors.*`
- **withOpacity() usage:** Deprecated in Flutter 3.x — use `.withValues(alpha: x)` instead (already seen in newer code: `dashboard_grid.dart` line 115)
- **GlassPanel for home screen cards:** GlassPanel uses 20px blur and `Color(0xFF121212)`. Home screen glass cards need 2px blur and `AppColors.surfaceOverlay` — use custom implementation per Pattern 2
- **Animating between sky states:** Phase 3 is static swap only (no AnimatedSwitcher)
- **Moving header into HomeScreen:** Global glass header is intentionally in `ScaffoldWithNavBar` — do not duplicate

---

## Token Migration (DS-02) — Scope

### Known Hardcoded Value Patterns to Replace

Based on codebase inspection (35 files with `Colors.*`, 26 with `fontSize:`): [VERIFIED: codebase grep]

| Hardcoded Pattern | Replace With |
|------------------|-------------|
| `Colors.blueAccent` | `AppColors.accent` |
| `Colors.white` | `AppColors.textPrimary` |
| `Colors.white.withOpacity(x)` / `.withValues(alpha: x)` | `AppColors.textPrimary.withValues(alpha: x)` |
| `Color(0xFF000000)` / `Colors.black` | `AppColors.surface` |
| `AppTheme.deepCosmos` | `AppColors.surface` |
| `AppTheme.oledBlack` | `AppColors.surface` |
| `AppTheme.starlight` | `AppColors.textPrimary` |
| `AppTheme.accentPurple` | No direct token (purple removed from design system; use contextually appropriate token) |
| `AppTheme.accentCyan` | `AppColors.accentSecondary` |
| `Colors.indigo` / `Colors.indigo[300]` | `AppColors.accent` (closest design token) |
| `fontSize: N` inline | `AppTypography.*` style |
| `EdgeInsets.all(N)` / `SizedBox(height: N)` with literal | `AppSpacing.*` equivalent |
| `AppTheme.glassBlur` | Remove; each site uses explicit `ImageFilter.blur(sigmaX: ...)` |
| `Color(0xFF121212)` in GlassPanel | `AppColors.surfaceGlass` (for nav shell) or `AppColors.surfaceOverlay` (for cards) |

### GlassPanel Token Migration

`GlassPanel` uses `Color(0xFF121212).withValues(alpha: 0.8)` and `Colors.white.withValues(alpha: ...)`. After migration:
- Background: context-dependent (`surfaceGlass` for header pills, `surfaceOverlay` for other panels)
- Border: `AppColors.borderSurface` (Grey/600/100) for nav pills
- Consider adding optional `backgroundColor` and `borderColor` parameters to `GlassPanel` to support contextual use

### 15 Surfaces Requiring Token Migration

All active surfaces in `lib/` (not visually redesigned, but hardcoded values replaced):
1. `home_screen.dart` — visual redesign + tokens
2. `scaffold_with_nav_bar.dart` — tokens only
3. `atmospherics_sheet.dart` — tokens only
4. `celestial_detail_sheet.dart` — tokens only
5. `highlights_feed.dart` — restyle + tokens
6. `cloud_bar.dart` — restyle + tokens
7. `moon_phase_card.dart` → replaced by `MoonMiniCard` (tokens built-in)
8. `bortle_bar.dart` → replaced by `VisibilityMiniCard` (tokens built-in)
9. `dashboard_grid.dart` — tokens only (structural changes to layout)
10. `glass_panel.dart` — tokens migration
11. All other `lib/features/*/presentation/` widgets encountered during sweep

---

## Existing Code to Preserve

The following logic in `home_screen.dart` MUST be preserved during the in-place refactor (D-04):

| Logic | Location | Notes |
|-------|----------|-------|
| `SystemChrome.setSystemUIOverlayStyle(...)` | `initState()` | OLED black status bar |
| `_bannerController` + `_bannerTimer` | Class fields + `_handleDateChange()` | Past/future date banner |
| `_hasHandledLaunchToast` + `_hasHandledLaunchLocation` | Class fields | One-shot launch handling |
| `LaunchResult` switch + `WidgetsBinding.addPostFrameCallback` | `build()` | Smart launch zero-click UX |
| `ref.listen(astrContextProvider, ...)` | `build()` | Date change banner trigger |
| `ref.read(astrContextProvider.notifier).refreshLocation()` | Refresh handler | Pull-to-refresh |
| `ref.read(weatherProvider.notifier).refresh()` | Refresh handler | Pull-to-refresh |

---

## Common Pitfalls

### Pitfall 1: withOpacity() Deprecation

**What goes wrong:** `Colors.white.withOpacity(0.5)` compiles but produces a lint warning in Flutter 3.x+; some versions fail.
**Why it happens:** `withOpacity()` is deprecated in favor of `withValues(alpha:)`.
**How to avoid:** Always write `color.withValues(alpha: x)` in Phase 3. The existing `dashboard_grid.dart` already uses `withValues(alpha: 0.5)` correctly — follow that pattern.
**Warning signs:** Analyzer warning "withOpacity is deprecated".

### Pitfall 2: BackdropFilter Without Clip

**What goes wrong:** `BackdropFilter` without a `ClipRRect` parent will blur the entire screen, ignoring card shape.
**Why it happens:** `BackdropFilter` clips to the nearest ancestor with clipping.
**How to avoid:** Always wrap in `ClipRRect(borderRadius: ...)` + `RepaintBoundary` before the `BackdropFilter`, exactly as in `GlassPanel`.
**Warning signs:** Visual: blur extends outside card bounds.

### Pitfall 3: Image.asset Opacity Parameter

**What goes wrong:** Using `Opacity(opacity: 0.5, child: Image.asset(...))` creates a composited layer that's expensive.
**Why it happens:** `Opacity` widget forces compositing.
**How to avoid:** Use `Image.asset(path, opacity: const AlwaysStoppedAnimation(0.5))` — this is the Flutter-recommended approach for static image opacity.
**Warning signs:** Performance profiler shows extra compositing layers.

### Pitfall 4: Hive Field Index vs. Name

**What goes wrong:** After renaming `ZoneCacheEntry.bortleClass` to `astrZone`, existing cached Hive entries fail to deserialize if the generated adapter changes.
**Why it happens:** Misunderstanding that Hive serializes by field name.
**How to avoid:** Hive serializes by the integer in `@HiveField(N)`. Renaming the Dart field identifier is safe as long as the integer stays `@HiveField(1)`. Run `dart run build_runner build` to regenerate the adapter after rename.
**Warning signs:** Runtime `HiveError` on cache reads if the integer was accidentally changed.

### Pitfall 5: SkyState Null Before conditionQualityProvider Resolves

**What goes wrong:** `SkyStateBackground` receives null sky state while `conditionQualityProvider` is loading, shows blank or crashes.
**Why it happens:** `FutureProvider` has a loading state.
**How to avoid:** Default to `SkyState.starrySkies` (or `assets/img/starry_sky.jpg`) until resolved. The UI-SPEC loading state contract specifies: "Background image defaults to `assets/img/starry_sky.jpg` until sky state resolves".
**Warning signs:** Black screen flash on first load.

### Pitfall 6: Hero Label vs. Conditions Title Mismatch

**What goes wrong:** "Excellent" hero label shown with "Cloud Cover" conditions title (wrong pairing).
**Why it happens:** Hero label and conditions title both depend on SkyState but mapped separately.
**How to avoid:** Both should switch on the same `SkyState` value from `conditionQualityProvider`. The UI-SPEC Hero Condition Labels table is the source of truth.
**Warning signs:** Mismatched text content on screen.

### Pitfall 7: Token Audit Missing Generated Files

**What goes wrong:** Token migration passes the sweep, but generated `.g.dart` or `.freezed.dart` files still contain hardcoded values.
**Why it happens:** Grep may skip generated files or they may regenerate with old values.
**How to avoid:** Generated files are excluded from analysis (CLAUDE.md) and don't need token migration. Only hand-written `lib/` files need migration. The token enforcement rule in DS-02 only applies to non-generated code.

---

## Code Examples

### Hero Section Assembly

```dart
// Source: UI-SPEC layout spec + Figma node 119:80
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text(
      heroLabel,  // e.g. 'Excellent'
      style: AppTypography.display,   // 72px Satoshi Bold
      textAlign: TextAlign.center,
    ),
    const SizedBox(height: AppSpacing.sm),
    Text(
      skyStateName,  // e.g. 'Milkyway Visible'
      style: AppTypography.body,   // 16px Satoshi Regular
      textAlign: TextAlign.center,
    ),
    const SizedBox(height: AppSpacing.md),
    // Zone Badge
    Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,      // 8px
        horizontal: AppSpacing.md,    // 16px
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceOverlay,   // 0x800C0F11
        border: Border.all(color: AppColors.borderPrimary),  // Blue/800
        borderRadius: BorderRadius.circular(AppSpacing.kBadgeRadius),  // 70px
      ),
      child: Text(
        'Zone ${zone}',
        style: AppTypography.labelMd,   // 12px Satoshi Medium
      ),
    ),
  ],
)
```

### Visibility Rating Bars

```dart
// Source: UI-SPEC + Figma node 119:80
// 5 bars, total width 132px, height 5px, gap 5px
// Active bars: zones 1-2 = 1 active bar ... zones 8-9 = 5 active bars
Row(
  children: List.generate(5, (index) {
    final int activeBars = ((visibilityIndex - 1) / 2).floor().clamp(0, 5);
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

### Sun/Moon Time Cell

```dart
// Source: UI-SPEC — 72×64px each
Container(
  width: AppSpacing.kSunMoonCellWidth,    // 72px
  height: AppSpacing.kSunMoonCellHeight,  // 64px
  decoration: BoxDecoration(
    color: AppColors.surfaceGlass,          // 0xCC0C0F11
    border: Border.all(color: AppColors.borderSubtle),  // Blue/900
    borderRadius: BorderRadius.circular(AppSpacing.kInnerRadius),  // 12px
  ),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(label, style: AppTypography.micro),  // 'SUNRISE' etc.
      const SizedBox(height: AppSpacing.xs),
      Text(timeStr, style: AppTypography.labelMd),  // 'HH:mm'
    ],
  ),
)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `withOpacity()` | `withValues(alpha:)` | Flutter 3.x | `withOpacity()` deprecated; use `withValues` |
| Manual opacity widget | `Image.asset(opacity: AlwaysStoppedAnimation(x))` | Flutter 3.8+ | Avoids extra compositing layer |
| `background` deprecated in ThemeData | `surface` + `scaffoldBackgroundColor` | Flutter 3.x | AppTheme already uses `surface` param |

**Deprecated/outdated in this codebase:**
- `Colors.white.withOpacity(x)` → 35+ instances need migration to `.withValues(alpha: x)`
- `AppTheme.deepCosmos` / `AppTheme.oledBlack` / `AppTheme.starlight` → migrate to token refs, then remove from `AppTheme`

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `withValues(alpha:)` API is available in the Flutter SDK version in use | Common Pitfalls | If not available, revert to `.withOpacity()` — minor |
| A2 | `Image.asset` `opacity` parameter (AlwaysStoppedAnimation) is supported in the Flutter SDK version in use | Code Examples | If not, use `Opacity` widget wrapper — minor performance cost |
| A3 | Cloudflare Worker JSON key is `'bortle'` (confirmed by grep showing no cloudflare/worker.js output; RemoteZoneService hardcodes `json['bortle']`) | bortleClass rename | If wrong, API calls would fail — HIGH risk. Executor must verify worker.js response before finalizing RemoteZoneService change |
| A4 | The existing `ConditionQuality.unknown` case requires a loading placeholder sky state (mapped to `SkyState.starrySkies`) | Critical Finding | If wrong, loading state shows unexpected background |
| A5 | `BortleBar._getShortLabel()` labels ("Dark Sky", "Rural", "Suburban", "Urban") are not the final labels for the Visibility mini-card | Architecture | UI-SPEC specifies "Rural Sky" as the primary label — confirm exact label mapping with existing `BortleMpsasConverter.bortleDescription()` or the Figma |

---

## Open Questions (RESOLVED)

1. **Cloudflare Worker JSON key verification**
   - RESOLVED: Verified directly from `cloudflare/worker.js` line 102: the worker returns `{ bortle: row.zone, ratio: ..., sqm: ..., h3: ... }`. The JSON key is `'bortle'`. `RemoteZoneService` correctly uses `json['bortle']` as the lookup key. The Dart rename changes only the named constructor parameter (`bortleClass:` → `astrZone:`); the JSON wire format is unchanged.

2. **Visibility card label mapping**
   - RESOLVED: Add a new static helper `_getSkyLabel(int astrZone)` in `VisibilityMiniCard`: zone ≤2 → 'Dark Sky', zone ≤4 → 'Rural Sky', zone ≤6 → 'Suburban Sky', zone >6 → 'Urban Sky'. Do not re-use `BortleBar._getShortLabel()` directly — it returns different strings (e.g. 'Rural' not 'Rural Sky'). Confirm exact label text against `figma/home/Home.png` before finalizing. This mapping is specified in PATTERNS.md `_getSkyLabel` section.

3. **GlassPanel blur sigma for restyled nav pills**
   - RESOLVED: Header pills remain at 20px blur (existing GlassPanel behavior). Only home screen cards (ConditionsCard, VisibilityMiniCard, MoonMiniCard) use the 2px blur per Figma spec. The UI-SPEC does not override the header pill blur — the existing GlassPanel default is correct for the nav shell.

4. **SkyState enum location**
   - RESOLVED: `lib/core/engine/models/sky_state.dart`. The enum is produced by `QualitativeConditionService` (a core engine service) and stored in `ConditionResult`, which is a shared entity consumed by multiple features. Placing it alongside `ConditionResult` and `ConditionQuality` in `lib/core/engine/models/` is correct; it is a shared domain type, not a feature-specific one.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Widget framework | ✓ | (Dart >=3.0.5) | — |
| Satoshi font files | Typography | ✓ | All 4 weights in assets/fonts/ | — |
| `assets/img/*.jpg` | SkyStateBackground | ✓ | All 6 confirmed present | — |
| `assets/design/color_system.csv` | Token value reference | ✓ | All 108 rows present | — |
| `figma/home/Home.png` | Executor design reference | ✓ | Present | — |
| `dart run build_runner build` | ZoneCacheEntry regen | ✓ | Already used for existing .g.dart files | — |

**Missing dependencies with no fallback:** None.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK built-in) |
| Config file | No separate config — uses `flutter test` |
| Quick run command | `flutter test test/core/services/qualitative/ -x` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DS-01 | Token constants compile and have correct values | unit | `flutter test test/core/design/app_colors_test.dart -x` | ❌ Wave 0 |
| DS-01 | Typography styles have correct font sizes | unit | `flutter test test/core/design/app_typography_test.dart -x` | ❌ Wave 0 |
| HOME-01 | SkyStateBackground returns correct asset for each SkyState | unit | `flutter test test/features/dashboard/presentation/widgets/sky_state_background_test.dart -x` | ❌ Wave 0 |
| HOME-01 | QualitativeConditionService produces correct SkyState | unit | `flutter test test/core/services/qualitative/qualitative_condition_service_test.dart -x` | ✅ exists (needs SkyState assertions added) |
| HOME-04 | ConditionsCard renders with placeholder when loading | widget | `flutter test test/features/dashboard/presentation/widgets/conditions_card_test.dart -x` | ❌ Wave 0 |
| D-09 | ZoneData.astrZone field accessible and equals former bortleClass | unit | `flutter test test/features/data_layer/models/zone_data_test.dart -x` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/core/design/ test/features/dashboard/presentation/widgets/ -x`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/core/design/app_colors_test.dart` — covers DS-01 (token values match CSV)
- [ ] `test/core/design/app_typography_test.dart` — covers DS-01 (font sizes correct)
- [ ] `test/features/dashboard/presentation/widgets/sky_state_background_test.dart` — covers HOME-01 (asset mapping)
- [ ] `test/features/dashboard/presentation/widgets/conditions_card_test.dart` — covers HOME-04 (loading/data states)
- [ ] `test/features/data_layer/models/zone_data_test.dart` — covers D-09 (astrZone field)
- [x] `test/core/services/qualitative/qualitative_condition_service_test.dart` — exists; add `SkyState` assertions for each condition path

---

## Security Domain

Phase 3 is a pure UI/styling phase with no new network calls, authentication, session management, or user data input. Security posture is unchanged.

| ASVS Category | Applies | Notes |
|---------------|---------|-------|
| V2 Authentication | No | No new auth in Phase 3 |
| V3 Session Management | No | No session changes |
| V4 Access Control | No | No access control changes |
| V5 Input Validation | No | No new user input fields |
| V6 Cryptography | No | No cryptographic changes |

The existing token-based security model for Cloudflare Worker calls is preserved unchanged.

---

## Sources

### Primary (HIGH confidence — verified directly in codebase)

- `lib/features/dashboard/presentation/home_screen.dart` — existing home screen structure, preserved business logic
- `lib/app/router/scaffold_with_nav_bar.dart` — existing nav shell, hardcoded values to migrate
- `lib/app/theme/app_theme.dart` — existing AppTheme constants to migrate to tokens
- `lib/core/widgets/glass_panel.dart` — glassmorphism pattern (RepaintBoundary + ClipRRect + BackdropFilter)
- `lib/core/services/qualitative/qualitative_condition_service.dart` — sky state branching logic
- `lib/core/engine/models/condition_quality.dart` — ConditionQuality enum (4 values vs. 6 needed)
- `lib/core/engine/models/condition_result.dart` — ConditionResult model to extend
- `lib/features/data_layer/models/zone_data.dart` — bortleClass field to rename
- `lib/features/data_layer/models/zone_cache_entry.dart` — @HiveField(1) annotation
- `lib/features/data_layer/repositories/cached_zone_repository.dart` — 5 bortleClass references
- `lib/features/data_layer/services/remote_zone_service.dart` — json['bortle'] key confirmation
- `lib/features/dashboard/data/repositories/light_pollution_repository.dart` — 3 bortleClass references
- `lib/features/dashboard/presentation/providers/condition_quality_provider.dart` — provider structure
- `lib/features/dashboard/presentation/providers/visibility_provider.dart` — VisibilityState
- `lib/features/dashboard/presentation/widgets/dashboard_grid.dart` — existing layout to replace
- `lib/features/dashboard/presentation/widgets/bortle_bar.dart` — existing visibility card (visibility label logic)
- `lib/features/dashboard/presentation/widgets/cloud_bar.dart` — existing cloud bar to restyle
- `lib/features/dashboard/presentation/widgets/highlights_feed.dart` — existing highlights list to restyle
- `assets/design/color_system.csv` — locked color primitives (108 rows, verified)
- `pubspec.yaml` — font registration (Satoshi 300/400/500/700), asset declarations, package versions
- `.planning/phases/03-design-system-home-screen/03-CONTEXT.md` — locked decisions
- `.planning/phases/03-design-system-home-screen/03-UI-SPEC.md` — typography, spacing, color tokens, component inventory

### Secondary (MEDIUM confidence)

- `figma/home/Home.png` — Figma export confirmed present; visual reference for executor

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages verified in pubspec.yaml; no new dependencies
- Architecture: HIGH — all patterns verified in codebase
- Sky state gap: HIGH — verified by reading both ConditionQuality enum and QualitativeConditionService
- bortleClass rename scope: HIGH — verified by grep, 5 files identified
- Pitfalls: HIGH — derived from actual code patterns seen in codebase
- Token migration scope: HIGH — 35/26 files confirmed by grep

**Research date:** 2026-07-05
**Valid until:** 2026-09-01 (stable Flutter; token values locked to CSV)
