# Phase 1: Archive & Cleanup - Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 7 (files to create or modify in active codebase)
**Analogs found:** 6 / 7

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/features/forecast/presentation/forecast_screen.dart` | screen (widget) | request-response | `lib/features/planner/presentation/pages/forecast_screen.dart` | exact — this IS the content to migrate |
| `lib/features/forecast/presentation/providers/forecast_provider.dart` | provider | request-response | `lib/features/planner/presentation/providers/planner_provider.dart` | exact — this IS the content to migrate |
| `lib/app/router/app_router.dart` | config (router) | request-response | itself (modify in place) | self |
| `lib/hive/hive_adapters.dart` | config (Hive) | — | itself (modify in place) | self |
| `.gitignore` | config | — | itself (modify in place) | self |
| `archive/INDEX.md` | documentation | — | no analog (new file) | none |
| `archive/data-pipeline/README.md` | documentation | — | `scripts/README.md` (different pipeline — do NOT copy) | no analog |

---

## Pattern Assignments

### `lib/features/forecast/presentation/forecast_screen.dart` (screen, request-response)

**Action:** Replace stub content entirely with content migrated from analog.

**Analog:** `lib/features/planner/presentation/pages/forecast_screen.dart`

**Imports pattern** (lines 1-12):
```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/glass_panel.dart';
import '../../../context/presentation/providers/astr_context_provider.dart';
import '../../../dashboard/presentation/widgets/nebula_background.dart';
import '../../domain/entities/daily_forecast.dart';
import '../providers/planner_provider.dart';
```

**After migration**, the last import must change to point at the new provider location:
```dart
// Before:
import '../providers/planner_provider.dart';

// After (new canonical path):
import '../providers/forecast_provider.dart';
```

**Core widget pattern** (lines 14-283 of analog): The entire `ForecastScreen` `ConsumerStatefulWidget` and `_ForecastItem` `StatelessWidget` classes are copied verbatim. No logic change — only the import path for the provider changes.

**Key dependency:** `forecastListProvider` from `planner_provider.dart` is the only provider reference. This must resolve to `forecast_provider.dart` after migration.

---

### `lib/features/forecast/presentation/providers/forecast_provider.dart` (provider, request-response)

**Action:** Create this file as a copy of the analog with updated relative import paths.

**Analog:** `lib/features/planner/presentation/providers/planner_provider.dart`

**Full content pattern** (lines 1-50 of analog — copy verbatim, update relative paths):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/src/either.dart';

import '../../../../core/error/failure.dart';
import '../../../astronomy/domain/repositories/i_astro_engine.dart';
import '../../../astronomy/presentation/providers/astro_engine_provider.dart';
import '../../../context/domain/entities/astr_context.dart';
import '../../../context/presentation/providers/astr_context_provider.dart';
import '../../../dashboard/data/datasources/open_meteo_weather_service.dart';
import '../../../dashboard/domain/entities/light_pollution.dart';
import '../../../dashboard/presentation/providers/light_pollution_provider.dart';
import '../../../dashboard/presentation/providers/weather_provider.dart';
```

**Relative path adjustment required:** The analog is at depth `lib/features/planner/presentation/providers/`. The new file lives at `lib/features/forecast/presentation/providers/`. The relative path depth is identical (`../../../../` reaches `lib/`), so all `../../../../` imports stay unchanged. The only import that needs updating is the one referencing planner's own domain:

```dart
// Before (planner-internal):
import '../../data/repositories/planner_repository.dart';
import '../../domain/entities/daily_forecast.dart';
import '../../domain/logic/planner_logic.dart';
import '../../domain/repositories/i_planner_repository.dart';

// After — these planner domain files must also be migrated to lib/features/forecast/domain/
// OR the forecast_provider.dart imports them from planner/ until planner/ is archived.
// CRITICAL: planner/ domain files (daily_forecast.dart, planner_logic.dart,
// planner_repository.dart, i_planner_repository.dart) must migrate to
// lib/features/forecast/domain/ before planner/ is deleted.
// Migration target paths:
import '../../domain/entities/daily_forecast.dart';
import '../../domain/logic/forecast_logic.dart';       // renamed from planner_logic.dart
import '../../data/repositories/forecast_repository.dart'; // renamed from planner_repository.dart
import '../../domain/repositories/i_forecast_repository.dart'; // renamed from i_planner_repository.dart
```

**Provider declarations pattern** (lines 19-50 of analog — copy with name updates):
```dart
// Logic Provider
final Provider<PlannerLogic> plannerLogicProvider = Provider<PlannerLogic>(...);
// → Rename to ForecastLogic / forecastLogicProvider

// Repository Provider  
final Provider<IPlannerRepository> plannerRepositoryProvider = Provider<IPlannerRepository>(...);
// → Rename to IForecastRepository / forecastRepositoryProvider

// Forecast List Provider — keep name forecastListProvider (already well-named)
final FutureProvider<List<DailyForecast>> forecastListProvider = FutureProvider<List<DailyForecast>>(...);
```

---

### `lib/app/router/app_router.dart` (router config, request-response)

**Action:** Update one import line. No logic changes.

**File:** `lib/app/router/app_router.dart`

**Current import** (line 9):
```dart
import '../../features/planner/presentation/pages/forecast_screen.dart';
```

**Replace with** (line 9 after migration):
```dart
import '../../features/forecast/presentation/forecast_screen.dart';
```

All other lines in `app_router.dart` are unchanged. The `ForecastScreen` class name is identical in both files so no usage-site changes are needed.

**Verification:** `flutter analyze --no-pub` must return zero errors after this change.

---

### `lib/hive/hive_adapters.dart` (config, Hive adapter registration)

**Action:** Remove two lines — the `ThemeUiModel` import and its `AdapterSpec` entry.

**File:** `lib/hive/hive_adapters.dart`

**Current content** (lines 1-17 — full file):
```dart
// lib/hive/hive_adapters.dart   ← keep registrar but REMOVE the spec
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../config/theme/theme_ui_model.dart';

// ignore: always_specify_types
@GenerateAdapters(firstTypeId: 0,[
  // AdapterSpec<LoginCredentials>(),
  AdapterSpec<ThemeUiModel>(),
  // WeatherCacheEntry removed - it has its own @HiveType(typeId: 2) annotation
  // Add other models here
])           // or just omit the list entirely
part 'hive_adapters.g.dart';
```

**After edit:**
```dart
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

// ignore: always_specify_types
@GenerateAdapters(firstTypeId: 0,[
  // AdapterSpec<LoginCredentials>(),
  // WeatherCacheEntry removed - it has its own @HiveType(typeId: 2) annotation
  // Add other models here
])
part 'hive_adapters.g.dart';
```

**Lines to remove:**
- Line 5: `import '../config/theme/theme_ui_model.dart';`
- Line 13: `AdapterSpec<ThemeUiModel>(),`
- Line 1 comment (optional cleanup): The comment on line 1 references "REMOVE the spec" — remove that stale comment too.

**Post-edit:** Run `dart run build_runner build` to regenerate `hive_adapters.g.dart`. Then `flutter analyze --no-pub`.

---

### `.gitignore` (config, git)

**Action:** Add four new entries. The existing entries stay unchanged.

**File:** `/Users/hp/Desktop/Work/Repositories/Astr/.gitignore`

**Current relevant entries** (lines 98-128):
```
test_output*.txt          # line 98 — wrong pattern, does not match test_failures*.log
zone_accumulator.db       # line 109 — missing 's', does not match zones_accumulator.db
archive/                  # line 128 — already present, archive content excluded
```

**Lines to add** (append after line 109 or in the same section):
```
# Correct zone DB name (was 'zone_accumulator.db' — missing 's')
zones_accumulator.db
# Test failure logs
test_failures*.log
# GetStorage runtime files
GetStorage.bak
GetStorage.gs
```

**Archive documentation exception** (add after line 128 `archive/`):
```
# Allow archive documentation to be committed
!archive/INDEX.md
!archive/**/README.md
```

**Do NOT remove** the existing `zone_accumulator.db` entry (line 109) — it may match files created by older pipeline runs. Keeping both patterns is safe.

---

## Shared Patterns

### Dart file move pattern
**Applies to:** All `lib/features/planner/` files being migrated to `lib/features/forecast/`

When moving a Dart source file:
1. Copy file content to new path.
2. Update all relative imports within the file to reflect the new directory depth.
3. Update all other files that imported the old path.
4. Run `flutter analyze --no-pub` — any remaining broken imports surface as errors.
5. Delete the original file only after the analyzer is clean.

This project uses **relative imports** (not `package:astr/` aliases). Path depth from `lib/features/forecast/presentation/providers/` to `lib/` is `../../../../` — identical to the depth from `lib/features/planner/presentation/providers/`. This means only the planner-internal cross-imports need updating, not the core/ or cross-feature imports.

### ConsumerStatefulWidget screen pattern
**Source:** `lib/features/planner/presentation/pages/forecast_screen.dart` lines 14-19
**Apply to:** `lib/features/forecast/presentation/forecast_screen.dart`
```dart
class ForecastScreen extends ConsumerStatefulWidget {
  const ForecastScreen({super.key});

  @override
  ConsumerState<ForecastScreen> createState() => _ForecastScreenState();
}
```

### FutureProvider pattern
**Source:** `lib/features/planner/presentation/providers/planner_provider.dart` lines 33-50
**Apply to:** `lib/features/forecast/presentation/providers/forecast_provider.dart`
```dart
final FutureProvider<List<DailyForecast>> forecastListProvider = FutureProvider<List<DailyForecast>>((FutureProviderRef<List<DailyForecast>> ref) async {
  final IPlannerRepository repository = ref.watch(plannerRepositoryProvider);
  final AsyncValue<AstrContext> contextAsync = ref.watch(astrContextProvider);
  final LightPollution lightPollution = ref.watch(lightPollutionProvider);

  final AstrContext? context = contextAsync.value;
  if (context == null) {
    return <DailyForecast>[];
  }

  final Either<Failure, List<DailyForecast>> result = await repository.get7DayForecast(context.location, lightPollution.visibilityIndex);

  return result.fold(
    (Failure failure) => throw failure,
    (List<DailyForecast> forecasts) => forecasts,
  );
});
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `archive/INDEX.md` | documentation | — | No existing archive index in codebase. Compose from scratch using the Archive Map table in RESEARCH.md §Archive Map. |
| `archive/data-pipeline/README.md` | documentation | — | `scripts/README.md` documents a DIFFERENT (superseded VIIRS HDF5) pipeline. Do NOT copy from it. Compose from scratch using RESEARCH.md §Data Pipeline Inventory and §archive/data-pipeline/README.md Must Cover. |
| `archive/backend/README.md` | documentation | — | No template. Short file: what it was, why archived, what replaced it. |
| `archive/api/README.md` | documentation | — | No template. Short file: what it was, why archived, what replaced it. |
| `archive/planner/README.md` | documentation | — | No template. Short file: what it was, why archived, what replaced it (forecast screen migrated to lib/features/forecast/). |

---

## Critical Sequencing Constraint

The planner must enforce this execution order for all Dart-touching tasks:

1. Migrate `lib/features/planner/domain/` files to `lib/features/forecast/domain/`
2. Create `lib/features/forecast/presentation/providers/forecast_provider.dart` (from planner_provider.dart with updated paths)
3. Replace `lib/features/forecast/presentation/forecast_screen.dart` content (from planner/pages/forecast_screen.dart with updated provider import)
4. Update `lib/app/router/app_router.dart` import (line 9)
5. Run `flutter analyze --no-pub` — must be clean before proceeding
6. Update `lib/hive/hive_adapters.dart` (remove ThemeUiModel)
7. Run `dart run build_runner build` then `flutter analyze --no-pub`
8. Archive `lib/features/planner/` (now safe — no active code references it)
9. Archive `lib/config/theme/` (now safe — hive_adapters.dart no longer references it)
10. Fix `.gitignore`
11. Create `archive/` documentation files

---

## Metadata

**Analog search scope:** `lib/features/planner/`, `lib/app/router/`, `lib/hive/`, `lib/config/theme/`
**Files read:** 8
**Pattern extraction date:** 2026-06-13
