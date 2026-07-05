---
phase: 03-design-system-home-screen
plan: 01A
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/core/design/app_colors.dart
  - lib/core/design/app_typography.dart
  - lib/core/design/app_spacing.dart
  - lib/app/theme/app_theme.dart
  - test/core/design/app_colors_test.dart
autonomous: true
requirements:
  - DS-01
  - DS-03

must_haves:
  truths:
    - "AppColors, AppTypography, AppSpacing compile as static-only classes with all constants from UI-SPEC"
    - "AppTheme.darkTheme builds without error; legacy constants (deepCosmos etc.) remain for backward compatibility"
    - "flutter test test/core/design/ passes all assertions"
  artifacts:
    - path: "lib/core/design/app_colors.dart"
      provides: "AppColors — 17 semantic color tokens + glowShadow"
      contains: "class AppColors"
    - path: "lib/core/design/app_typography.dart"
      provides: "AppTypography — 8 text-style roles"
      contains: "class AppTypography"
    - path: "lib/core/design/app_spacing.dart"
      provides: "AppSpacing — base scale (xs–xxxl) + 21 Figma k* constants"
      contains: "class AppSpacing"
  key_links:
    - from: "lib/core/design/app_typography.dart"
      to: "lib/core/design/app_colors.dart"
      via: "relative import 'app_colors.dart' for AppColors.textPrimary"
      pattern: "import 'app_colors.dart'"
    - from: "lib/app/theme/app_theme.dart"
      to: "lib/core/design/app_colors.dart"
      via: "relative import for AppColors token usage in darkTheme getter"
      pattern: "AppColors\\."
---

## Phase Goal

**As a** stargazer, **I want to** open Astr and see tonight's sky conditions on a fully redesigned home screen, **so that** I know instantly whether it's worth going outside.

<objective>
Establish the design token foundation for Phase 3: three static-only token files in lib/core/design/ covering all color, typography, and spacing constants from the locked UI-SPEC. AppTheme.darkTheme is updated to reference AppColors; legacy AppTheme constants are preserved for backward compatibility until Plan 06 removes them.

Purpose: Every downstream widget in Plans 02–06 imports AppColors, AppTypography, and AppSpacing. Without these token files, all downstream plans fail to compile.

Output: lib/core/design/ (3 new files), lib/app/theme/app_theme.dart (updated imports, legacy constants preserved), test/core/design/app_colors_test.dart (new).
</objective>

<execution_context>
@/Users/hp/Desktop/Work/Repositories/Astr/.claude/gsd-core/workflows/execute-plan.md
@/Users/hp/Desktop/Work/Repositories/Astr/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/ROADMAP.md
@.planning/phases/03-design-system-home-screen/03-CONTEXT.md
@.planning/phases/03-design-system-home-screen/03-UI-SPEC.md
@.planning/phases/03-design-system-home-screen/03-PATTERNS.md
@assets/design/color_system.csv
@lib/app/theme/app_theme.dart
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Create lib/core/design/ token files and update AppTheme ThemeData factory</name>
  <files>
    lib/core/design/app_colors.dart,
    lib/core/design/app_typography.dart,
    lib/core/design/app_spacing.dart,
    lib/app/theme/app_theme.dart,
    test/core/design/app_colors_test.dart
  </files>
  <read_first>
    lib/app/theme/app_theme.dart — static-only class pattern to replicate exactly: private constructor const AppTheme._(), all members static const, single import from flutter/material.dart
    assets/design/color_system.csv — locked color primitives; Flutter Color column (0xAARRGGBB) is the authoritative hex value for every AppColors constant; read ALL rows before writing the file
    .planning/phases/03-design-system-home-screen/03-UI-SPEC.md — semantic color token table (17 constants + glowShadow), typography role table (8 roles with exact size/weight/height/letterSpacing), spacing scale and ALL Figma k* constants (read the full table — count changes as design is finalised)
    .planning/phases/03-design-system-home-screen/03-PATTERNS.md — sections for app_colors.dart, app_typography.dart, app_spacing.dart — follow exact structure shown; nav role is a getter not const because GoogleFonts returns runtime instances
  </read_first>
  <behavior>
    - AppColors.surface == const Color(0xFF0C0F11)
    - AppColors.accent == const Color(0xFF448AFF)
    - AppColors.glowShadow is List<BoxShadow> with exactly 2 entries; first entry color is Color(0x40FFFFFF) blurRadius 1.0; second entry color is Color(0xFF3A7FFF) blurRadius 12.2 (Figma verbatim — NOT the CSV Blue/400 value 0xFF3A96FF)
    - AppTypography.display has fontSize 72.0, fontWeight FontWeight.w700, fontFamily 'Satoshi', height 1.1, color AppColors.textPrimary
    - AppTypography.nav is a static getter (not const) returning GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w400, height: 1.3, color: AppColors.textPrimary)
    - AppSpacing.kConditionsCardWidth == 345.0
    - AppSpacing.kMiniCardWidth == 164.0
    - AppSpacing.kHeaderContentOffset == 55.0
  </behavior>
  <action>
    Create lib/core/design/app_colors.dart: static-only class AppColors with private constructor const AppColors._(). Import: only 'package:flutter/material.dart'. Declare exactly the 17 static const Color fields named per the UI-SPEC semantic token table, using 0xAARRGGBB values from the CSV Flutter Color column. The glowShadow constant uses Color(0xFF3A7FFF) for the second BoxShadow — this is the Figma node 119:80 value and differs from the CSV Blue/400 value; use the Figma value as noted in UI-SPEC.

    Create lib/core/design/app_typography.dart: static-only class AppTypography. Imports: 'package:flutter/material.dart', 'package:google_fonts/google_fonts.dart', 'app_colors.dart' (relative import — same lib/core/design/ directory, not package:astr). Declare 7 static const TextStyle fields (display, title, heading, body, labelMd, labelSm, micro) with exact parameters from the UI-SPEC typography table. Declare nav as a static TextStyle getter using GoogleFonts.inter() — not const.

    Create lib/core/design/app_spacing.dart: static-only class AppSpacing. Import: only 'package:flutter/material.dart'. Declare 7 base scale doubles (xs=4, sm=8, md=16, lg=24, xl=32, xxl=48, xxxl=64) as static const double. Declare ALL Figma-exact k* constants from the UI-SPEC spacing table as static const double — read the full table in the UI-SPEC before writing; the count is subject to change as design is finalized.

    Update lib/app/theme/app_theme.dart: add relative imports for the three new token files. From lib/app/theme/app_theme.dart, the relative paths are '../../core/design/app_colors.dart', '../../core/design/app_typography.dart', '../../core/design/app_spacing.dart'. Do NOT use package:astr imports in this source file. In the darkTheme getter, reference AppColors.surface for surface/background/scaffoldBackground and AppColors.accent where the primary color is used. Do NOT remove the legacy constants deepCosmos, oledBlack, starlight, accentPurple, accentCyan, glassBlur, glassOpacity, glassColor, glassRadius — they remain for backward compatibility and are removed in Plan 06 after all consumers are migrated.

    Create test/core/design/app_colors_test.dart: assert AppColors.surface equals const Color(0xFF0C0F11), AppColors.accent equals const Color(0xFF448AFF), AppColors.glowShadow.length equals 2, AppColors.glowShadow[1].color equals const Color(0xFF3A7FFF), AppSpacing.kConditionsCardWidth equals 345.0, AppSpacing.kMiniCardWidth equals 164.0, AppTypography.display.fontSize equals 72.0, AppTypography.display.fontWeight equals FontWeight.w700. Test files use package:astr/... imports (test files follow the package: import convention per CLAUDE.md; only source files under lib/ use relative imports).
  </action>
  <verify>
    <automated>flutter test test/core/design/ -x && flutter analyze lib/core/design/ lib/app/theme/</automated>
  </verify>
  <done>
    - lib/core/design/app_colors.dart, app_typography.dart, app_spacing.dart exist with no compile errors
    - test/core/design/app_colors_test.dart passes all assertions
    - flutter analyze lib/core/design/ returns 0 errors
    - AppTheme.darkTheme continues to build without error (existing theme behavior preserved)
    - AppTheme legacy constants (deepCosmos etc.) still present — not removed yet
    - app_typography.dart uses relative import 'app_colors.dart' (not package:astr/core/design/app_colors.dart)
    - app_theme.dart uses relative imports '../../core/design/app_colors.dart' (not package:astr)
  </done>
</task>

</tasks>

## Artifacts this plan produces

| Symbol | Kind | File |
|--------|------|------|
| AppColors | class | lib/core/design/app_colors.dart |
| AppColors.surface | static const Color | lib/core/design/app_colors.dart |
| AppColors.surfaceOverlay | static const Color | lib/core/design/app_colors.dart |
| AppColors.surfaceGlass | static const Color | lib/core/design/app_colors.dart |
| AppColors.accent | static const Color | lib/core/design/app_colors.dart |
| AppColors.accentSecondary | static const Color | lib/core/design/app_colors.dart |
| AppColors.borderPrimary | static const Color | lib/core/design/app_colors.dart |
| AppColors.borderSubtle | static const Color | lib/core/design/app_colors.dart |
| AppColors.borderSurface | static const Color | lib/core/design/app_colors.dart |
| AppColors.textPrimary | static const Color | lib/core/design/app_colors.dart |
| AppColors.textSecondary | static const Color | lib/core/design/app_colors.dart |
| AppColors.textMuted | static const Color | lib/core/design/app_colors.dart |
| AppColors.textSubdued | static const Color | lib/core/design/app_colors.dart |
| AppColors.zonePillFill | static const Color | lib/core/design/app_colors.dart |
| AppColors.zonePillText | static const Color | lib/core/design/app_colors.dart |
| AppColors.ratingBarActive | static const Color | lib/core/design/app_colors.dart |
| AppColors.ratingBarInactive | static const Color | lib/core/design/app_colors.dart |
| AppColors.cloudTrack | static const Color | lib/core/design/app_colors.dart |
| AppColors.glowShadow | static const List<BoxShadow> | lib/core/design/app_colors.dart |
| AppTypography | class | lib/core/design/app_typography.dart |
| AppTypography.display | static const TextStyle | lib/core/design/app_typography.dart |
| AppTypography.title | static const TextStyle | lib/core/design/app_typography.dart |
| AppTypography.heading | static const TextStyle | lib/core/design/app_typography.dart |
| AppTypography.body | static const TextStyle | lib/core/design/app_typography.dart |
| AppTypography.labelMd | static const TextStyle | lib/core/design/app_typography.dart |
| AppTypography.labelSm | static const TextStyle | lib/core/design/app_typography.dart |
| AppTypography.micro | static const TextStyle | lib/core/design/app_typography.dart |
| AppTypography.nav | static TextStyle getter | lib/core/design/app_typography.dart |
| AppSpacing | class | lib/core/design/app_spacing.dart |
| AppSpacing.xs / sm / md / lg / xl / xxl / xxxl | static const double (×7) | lib/core/design/app_spacing.dart |
| AppSpacing.kPillHeight / kPillRadius / kCardRadius / kInnerRadius / kBadgeRadius | static const double | lib/core/design/app_spacing.dart |
| AppSpacing.kExploreButtonRadius / kExploreButtonWidth / kExploreButtonHeight | static const double | lib/core/design/app_spacing.dart |
| AppSpacing.kConditionsCardWidth / kConditionsCardHeight | static const double | lib/core/design/app_spacing.dart |
| AppSpacing.kMiniCardWidth / kMiniCardHeight | static const double | lib/core/design/app_spacing.dart |
| AppSpacing.kSunMoonCellWidth / kSunMoonCellHeight | static const double | lib/core/design/app_spacing.dart |
| AppSpacing.kCloudTrackHeight / kRatingBarHeight / kRatingBarGap / kRatingBarsWidth | static const double | lib/core/design/app_spacing.dart |
| AppSpacing.kFabSize / kFabAboveNav / kNavBarHMargin / kNavTabGap / kNavFabNotchGap / kCardPadding / kScreenHPadding / kHeaderBarHeight / kHeaderContentOffset / kNavDatePillGap / kLogoSize / kLogoTopOffset | static const double | lib/core/design/app_spacing.dart |
| AppSpacing.kCloudSectionTop / kCloudLabelTop / kCloudTrackTop / kCloudTrackLeft / kCloudTrackWidth / kSunMoonLabelTop / kSunMoonTimeTop | static const double | lib/core/design/app_spacing.dart |

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Compile-time constants | All token values are compile-time constants; no runtime injection path exists |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-03-01A-01 | Information Disclosure | Token color values (compile-time constants) | accept | No PII; values are in public Figma design and CSV asset; no runtime injection path |
| T-03-01A-SC | Tampering | No new packages installed | accept | No package legitimacy gate needed; all packages from existing approved pubspec.yaml |
</threat_model>

<verification>
- flutter analyze lib/core/design/ lib/app/theme/ returns 0 errors
- flutter test test/core/design/ passes
- grep "class AppColors" lib/core/design/app_colors.dart returns 1 match
- grep "import 'app_colors.dart'" lib/core/design/app_typography.dart returns 1 match (relative import, not package:astr)
- grep "../../core/design/app_colors.dart" lib/app/theme/app_theme.dart returns 1 match (relative, not package:astr)
- AppTheme legacy constants (deepCosmos etc.) still present in lib/app/theme/app_theme.dart
</verification>

<success_criteria>
- lib/core/design/ contains exactly 3 files: app_colors.dart, app_typography.dart, app_spacing.dart
- AppColors declares 17 color constants and glowShadow (18 total); AppTypography declares 8 roles; AppSpacing declares 7 base + 21 k* constants (28 total)
- app_typography.dart uses relative import 'app_colors.dart' — not package:astr/core/design/app_colors.dart
- app_theme.dart uses relative imports '../../core/design/...' — not package:astr imports
- All tests pass; flutter analyze clean
</success_criteria>

<output>
Create .planning/phases/03-design-system-home-screen/03-01A-SUMMARY.md when done
</output>
