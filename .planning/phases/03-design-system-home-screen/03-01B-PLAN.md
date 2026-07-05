---
phase: 03-design-system-home-screen
plan: 01B
type: execute
wave: 2
depends_on:
  - 03-01A
files_modified:
  - lib/core/engine/models/sky_state.dart
  - lib/core/engine/models/condition_result.dart
  - lib/core/services/qualitative/qualitative_condition_service.dart
  - lib/features/data_layer/models/zone_data.dart
  - lib/features/data_layer/models/zone_cache_entry.dart
  - lib/features/data_layer/models/zone_cache_entry.g.dart
  - lib/features/data_layer/repositories/cached_zone_repository.dart
  - lib/features/data_layer/services/remote_zone_service.dart
  - lib/features/dashboard/data/repositories/light_pollution_repository.dart
  - test/features/data_layer/models/zone_data_test.dart
autonomous: true
requirements:
  - DS-01

must_haves:
  truths:
    - "SkyState enum has exactly 6 values: milkyWayVisible, starrySkies, planetsVisible, fewStars, cloudy, tooMuchLight"
    - "Every ConditionResult constructor call in QualitativeConditionService._determineQualityAndAdvice includes a skyState: argument"
    - "ZoneData.astrZone field exists; grep -r bortleClass lib/ returns 0 results"
    - "zone_cache_entry.g.dart is regenerated and @HiveField(1) integer is unchanged on the renamed field"
    - "flutter test test/features/data_layer/models/ and test/core/services/qualitative/ pass"
  artifacts:
    - path: "lib/core/engine/models/sky_state.dart"
      provides: "SkyState enum (6 values)"
      contains: "enum SkyState"
    - path: "lib/core/engine/models/condition_result.dart"
      provides: "ConditionResult.skyState field"
      contains: "final SkyState skyState"
    - path: "lib/features/data_layer/models/zone_data.dart"
      provides: "ZoneData.astrZone field (renamed from bortleClass)"
      contains: "final int astrZone"
  key_links:
    - from: "lib/core/engine/models/condition_result.dart"
      to: "lib/core/engine/models/sky_state.dart"
      via: "relative import + skyState field"
      pattern: "final SkyState skyState"
    - from: "lib/core/services/qualitative/qualitative_condition_service.dart"
      to: "lib/core/engine/models/sky_state.dart"
      via: "skyState: SkyState.* in each ConditionResult constructor call"
      pattern: "skyState: SkyState\\."
---

## Phase Goal

**As a** stargazer, **I want to** open Astr and see tonight's sky conditions on a fully redesigned home screen, **so that** I know instantly whether it's worth going outside.

<objective>
Resolve the sky state gap and clean up the zone field naming — two independent but wave-grouped concerns: (1) add SkyState enum and wire it through ConditionResult so SkyStateBackground can select the correct illustrated background; (2) rename ZoneData.bortleClass to ZoneData.astrZone across 5 files with build_runner regeneration (per D-09).

Purpose: Without SkyState, Plan 02's SkyStateBackground cannot select the correct background. Without the rename, zone display uses the legacy Bortle class name. Both changes unblock Plan 02 onward.

Output: lib/core/engine/models/sky_state.dart (new), condition_result.dart and qualitative_condition_service.dart (modified), 5 data-layer files with field renamed, zone_cache_entry.g.dart regenerated, 2 new test files.
</objective>

<execution_context>
@/Users/hp/Desktop/Work/Repositories/Astr/.claude/gsd-core/workflows/execute-plan.md
@/Users/hp/Desktop/Work/Repositories/Astr/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/ROADMAP.md
@.planning/phases/03-design-system-home-screen/03-CONTEXT.md
@lib/core/engine/models/condition_quality.dart
@lib/core/engine/models/condition_result.dart
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: SkyState enum + ConditionResult extension + bortleClass rename + build_runner (D-09)</name>
  <files>
    lib/core/engine/models/sky_state.dart,
    lib/core/engine/models/condition_result.dart,
    lib/core/services/qualitative/qualitative_condition_service.dart,
    lib/features/data_layer/models/zone_data.dart,
    lib/features/data_layer/models/zone_cache_entry.dart,
    lib/features/data_layer/models/zone_cache_entry.g.dart,
    lib/features/data_layer/repositories/cached_zone_repository.dart,
    lib/features/data_layer/services/remote_zone_service.dart,
    lib/features/dashboard/data/repositories/light_pollution_repository.dart,
    test/features/data_layer/models/zone_data_test.dart
  </files>
  <read_first>
    lib/core/engine/models/condition_quality.dart — exact enum pattern (doc comments per value, no imports, pure Dart)
    lib/core/engine/models/condition_result.dart — current constructor signature, field declarations, props list; add skyState as 5th required parameter and field
    lib/core/services/qualitative/qualitative_condition_service.dart — all 5 ConditionResult constructor call sites in _determineQualityAndAdvice; map: cloudCover > 70 → cloudy, mpsas < 17.5 → tooMuchLight, excellent → milkyWayVisible, good → starrySkies, fair → planetsVisible, default poor → fewStars
    lib/features/data_layer/models/zone_data.dart — all bortleClass occurrences: constructor param, field declaration, copyWith method, == operator, hashCode, toString, fromBytes factory
    lib/features/data_layer/models/zone_cache_entry.dart — @HiveField(1) annotation on bortleClass; the integer 1 MUST remain on the renamed field
    lib/features/data_layer/repositories/cached_zone_repository.dart — 5 bortleClass references to update
    lib/features/data_layer/services/remote_zone_service.dart — update constructor named parameter from bortleClass: to astrZone:; the JSON key 'bortle' does not change — confirmed from cloudflare/worker.js line 102 which returns { bortle: row.zone, ratio: ..., sqm: ..., h3: ... }
    lib/features/dashboard/data/repositories/light_pollution_repository.dart — 3 bortleClass references to update
    test/core/services/qualitative/qualitative_condition_service_test.dart — existing test file; add SkyState assertions without removing existing tests
  </read_first>
  <behavior>
    - SkyState enum values in order: milkyWayVisible, starrySkies, planetsVisible, fewStars, cloudy, tooMuchLight
    - QualitativeConditionService with cloudCover=80 produces result.skyState == SkyState.cloudy
    - QualitativeConditionService with mpsas=17.0 (any cloud < 70) produces result.skyState == SkyState.tooMuchLight
    - Excellent input (cloudCover=10, mpsas=21.5, moonIllumination=0.05) produces SkyState.milkyWayVisible
    - Good input (cloudCover=20, mpsas=19.5, moonIllumination=0.3) produces SkyState.starrySkies
    - Fair input (cloudCover=40, mpsas=18.0, moonIllumination=0.5) produces SkyState.planetsVisible
    - Default poor input produces SkyState.fewStars
    - ZoneData(astrZone: 3, ratio: 1.0, sqm: 20.5).astrZone == 3
  </behavior>
  <action>
    Create lib/core/engine/models/sky_state.dart: pure Dart file, no imports. Declare enum SkyState with 6 values. Each value has a doc comment identifying the sky condition name, hero label, and background asset path. Follow the exact doc-comment style from condition_quality.dart (triple-slash, single line per value).

    Modify lib/core/engine/models/condition_result.dart: add relative import for sky_state.dart — use 'sky_state.dart' (same directory as condition_result.dart, not package:astr). Add required this.skyState as the 5th constructor parameter. Add final SkyState skyState field declaration after statusColor field. Extend props list to include skyState as the 5th element.

    Modify lib/core/services/qualitative/qualitative_condition_service.dart: add relative import for sky_state.dart — determine the correct relative path from this file's location to lib/core/engine/models/sky_state.dart and use that path (not package:astr). In _determineQualityAndAdvice, add skyState: argument to each ConditionResult constructor call: the cloudCover > 70 branch gets skyState: SkyState.cloudy; the mpsas < 17.5 branch gets skyState: SkyState.tooMuchLight; the excellent branch gets skyState: SkyState.milkyWayVisible; the good branch gets skyState: SkyState.starrySkies; the fair branch gets skyState: SkyState.planetsVisible; the default poor branch gets skyState: SkyState.fewStars. Do not migrate inline Color(0xFF...) literals in this file — that is handled in Plan 06.

    Rename bortleClass → astrZone (per D-09): In zone_data.dart rename bortleClass in the constructor parameter (required this.astrZone), field declaration (final int astrZone), copyWith signature and fallback (astrZone: astrZone ?? this.astrZone), == operator (other.astrZone == astrZone), hashCode (Object.hash(astrZone, ...)), toString, and fromBytes factory (astrZone: bortleClass where bortleClass is a local variable — the local variable name is fine to keep; only the constructor named key changes). In zone_cache_entry.dart rename the field identifier from bortleClass to astrZone; ensure @HiveField(1) remains on this same field. In cached_zone_repository.dart replace all 5 bortleClass references with astrZone. In remote_zone_service.dart update the constructor named parameter from bortleClass: to astrZone: — the JSON key 'bortle' does not change (confirmed: cloudflare/worker.js returns { bortle: row.zone } at line 102; only the Dart constructor named parameter changes). In light_pollution_repository.dart replace all 3 bortleClass references with astrZone. Run dart run build_runner build --delete-conflicting-outputs to regenerate zone_cache_entry.g.dart; after regeneration inspect the generated adapter to confirm @HiveField(1) integer is unchanged on the astrZone field.

    Create test/features/data_layer/models/zone_data_test.dart: unit tests asserting ZoneData(astrZone: 3, ratio: 1.0, sqm: 20.5).astrZone == 3, and equality between two ZoneData instances with identical values.

    In test/core/services/qualitative/qualitative_condition_service_test.dart add a test group 'SkyState mapping' with 6 test cases covering each branch. Call the service evaluate() method with inputs that exercise each branch and assert on result.skyState.
  </action>
  <verify>
    <automated>flutter test test/features/data_layer/models/zone_data_test.dart test/core/services/qualitative/ -x && flutter analyze lib/core/engine/models/ lib/features/data_layer/ lib/features/dashboard/data/repositories/</automated>
  </verify>
  <done>
    - lib/core/engine/models/sky_state.dart exists with enum SkyState { milkyWayVisible, starrySkies, planetsVisible, fewStars, cloudy, tooMuchLight }
    - condition_result.dart contains final SkyState skyState and skyState in props list (5 elements total); import is relative (not package:astr)
    - qualitative_condition_service.dart: all 5 ConditionResult constructor calls include skyState:; import is relative (not package:astr)
    - grep -r "bortleClass" lib/ returns 0 results
    - zone_cache_entry.g.dart exists and references astrZone with @HiveField(1) unchanged
    - All new and updated tests pass
    - flutter analyze lib/ returns 0 errors
  </done>
</task>

</tasks>

## Artifacts this plan produces

| Symbol | Kind | File |
|--------|------|------|
| SkyState | enum (6 values) | lib/core/engine/models/sky_state.dart |
| ConditionResult.skyState | final field | lib/core/engine/models/condition_result.dart |
| ZoneData.astrZone | final int field (renamed from bortleClass per D-09) | lib/features/data_layer/models/zone_data.dart |

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Hive binary deserialization | zone_cache_entry.g.dart decodes persisted binary data on device; @HiveField integer index must remain unchanged after rename |
| build_runner codegen | Generated file zone_cache_entry.g.dart is trusted output from an existing approved dev-dependency |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-03-01B-01 | Tampering | zone_cache_entry.g.dart (build_runner output) | mitigate | After regeneration, inspect generated adapter to confirm @HiveField(1) integer is unchanged on astrZone field before committing |
| T-03-01B-02 | Information Disclosure | SkyState enum (compile-time constants) | accept | No PII; sky state is derived from local condition data; no user-controlled injection path |
| T-03-01B-SC | Tampering | dart run build_runner (package resolution) | mitigate | build_runner is an existing approved dev-dependency; no new packages installed; existing pubspec.lock unchanged |
</threat_model>

<verification>
- flutter analyze lib/ returns 0 errors
- flutter test test/features/data_layer/models/ test/core/services/qualitative/ all pass
- grep -r "bortleClass" lib/ returns 0 results
- grep "enum SkyState" lib/core/engine/models/sky_state.dart returns 1 match
- grep "final SkyState skyState" lib/core/engine/models/condition_result.dart returns 1 match
- zone_cache_entry.g.dart exists and contains HiveField annotation with integer 1 on astrZone field
</verification>

<success_criteria>
- SkyState enum has exactly 6 values
- All 5 ConditionResult constructor calls in qualitative_condition_service.dart include skyState:
- grep -r "bortleClass" lib/ returns 0 results
- All imports in modified source files use relative paths (not package:astr)
- All tests pass; flutter analyze clean
</success_criteria>

<output>
Create .planning/phases/03-design-system-home-screen/03-01B-SUMMARY.md when done
</output>
