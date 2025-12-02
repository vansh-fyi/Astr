import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:astr/features/planner/data/repositories/planner_repository.dart';
import 'package:astr/features/planner/domain/logic/planner_logic.dart';
import 'package:astr/features/planner/domain/repositories/i_planner_repository.dart';
import 'package:astr/features/planner/domain/entities/daily_forecast.dart';
import 'package:astr/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:astr/features/astronomy/presentation/providers/astro_engine_provider.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:astr/features/dashboard/presentation/providers/light_pollution_provider.dart';

// Logic Provider
final plannerLogicProvider = Provider<PlannerLogic>((ref) {
  return PlannerLogic();
});

// Repository Provider
final plannerRepositoryProvider = Provider<IPlannerRepository>((ref) {
  final weatherService = ref.watch(weatherServiceProvider);
  final astroEngine = ref.watch(astroEngineProvider);
  final logic = ref.watch(plannerLogicProvider);
  
  return PlannerRepository(weatherService, astroEngine, logic);
});

// Forecast List Provider
final forecastListProvider = FutureProvider<List<DailyForecast>>((ref) async {
  final repository = ref.watch(plannerRepositoryProvider);
  final contextAsync = ref.watch(astrContextProvider);
  final lightPollution = ref.watch(lightPollutionProvider); // Watch Light Pollution
  
  final context = contextAsync.value;
  if (context == null) {
    return [];
  }
  
  // Pass Bortle Scale (visibilityIndex) to repository
  final result = await repository.get7DayForecast(context.location, lightPollution.visibilityIndex);
  
  return result.fold(
    (failure) => throw failure,
    (forecasts) => forecasts,
  );
});
