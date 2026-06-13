# Archive: lib/features/planner/

## What this was

The `planner` feature was an observation planning module (`lib/features/planner/`) that provided a 7-day forecast UI. It consisted of:

- **`presentation/pages/forecast_screen.dart`** — The actively-routed forecast screen. This was wired into `lib/app/router/app_router.dart` as the `/forecast` route. It used `planner_provider.dart` to fetch and display 7-day sky quality forecasts.
- **`presentation/providers/planner_provider.dart`** — Riverpod provider managing forecast data fetching. Depended on `PlannerLogic` and `IPlanner Repository`.
- **`presentation/screens/forecast_screen.dart`** — A dead duplicate forecast screen inside planner/. Not routed. Dead within the already-dead planner module.
- **`presentation/widgets/forecast_list_item.dart`** — Widget for rendering individual forecast day rows.
- **`domain/entities/daily_forecast.dart`** — Domain entity for a single day's forecast data.
- **`domain/logic/planner_logic.dart`** — Business logic for computing sky quality scores from weather + light pollution data.
- **`domain/repositories/i_planner_repository.dart`** — Abstract interface for forecast data access.
- **`data/repositories/planner_repository.dart`** — Concrete implementation of `IPlannerRepository` using Open-Meteo weather data.
- **`data/repositories/planner_repository_impl.dart`** — Implementation details for the repository layer.

## Why it was archived (Phase 1, 2026-06-13)

The planner feature was never fully launched as a standalone module. The concept of "observation scheduling" had no active UI beyond the forecast screen. The entire planner domain — `PlannerLogic`, `IPlannerRepository`, `PlannerRepository`, `DailyForecast` — was migrated and renamed to the canonical `lib/features/forecast/` location as part of Phase 1 Plans 02 and 03.

After Plan 04:
- The router's `/forecast` route was updated to import from `lib/features/forecast/presentation/forecast_screen.dart` (not the planner version)
- `lib/features/forecast/presentation/forecast_screen.dart` was promoted to a full `ConsumerStatefulWidget` with the working 7-day forecast list content (migrated from `planner/pages/forecast_screen.dart`)
- No active code in `lib/` imported anything from `lib/features/planner/`
- `flutter analyze lib/` confirmed zero errors after the router update

With all active references removed, `lib/features/planner/` became safe to archive. Decision D-03 (CONTEXT.md) explicitly requires archiving `lib/features/planner/` in full.

## What replaced it

`lib/features/forecast/` now owns the forecast screen and all domain logic. The class names were updated:
- `PlannerLogic` → `ForecastLogic`
- `IPlannerRepository` → `IForecastRepository`
- `PlannerRepository` / `PlannerRepositoryImpl` → `ForecastRepository` / `ForecastRepositoryImpl`
- `planner_provider.dart` → `lib/features/forecast/presentation/providers/forecast_provider.dart`
- `DailyForecast` entity preserved with the same name
- `ForecastScreen` widget class name was preserved unchanged

The active forecast route is now: `app_router.dart` → `lib/features/forecast/presentation/forecast_screen.dart`

## Tests

Planner tests are preserved in `archive/planner/tests/features/planner/` for historical reference. They cover:
- `planner_repository_impl_test.dart` — Repository implementation tests
- `planner_repository_test.dart` — Repository contract tests
- `planner_logic_test.dart` — Domain logic unit tests
- `forecast_screen_test.dart` (pages/ and screens/) — Widget tests for both forecast screen variants

The equivalent tests for the migrated forecast feature live in `test/features/forecast/`.
