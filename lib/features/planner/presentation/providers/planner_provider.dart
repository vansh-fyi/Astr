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
import '../../data/repositories/planner_repository.dart';
import '../../domain/entities/daily_forecast.dart';
import '../../domain/logic/planner_logic.dart';
import '../../domain/repositories/i_planner_repository.dart';

// Logic Provider
final Provider<PlannerLogic> plannerLogicProvider = Provider<PlannerLogic>((ProviderRef<PlannerLogic> ref) {
  return PlannerLogic();
});

// Repository Provider
final Provider<IPlannerRepository> plannerRepositoryProvider = Provider<IPlannerRepository>((ProviderRef<IPlannerRepository> ref) {
  final OpenMeteoWeatherService weatherService = ref.watch(weatherServiceProvider);
  final IAstroEngine astroEngine = ref.watch(astroEngineProvider);
  final PlannerLogic logic = ref.watch(plannerLogicProvider);
  
  return PlannerRepository(weatherService, astroEngine, logic);
});

// Forecast List Provider
final FutureProvider<List<DailyForecast>> forecastListProvider = FutureProvider<List<DailyForecast>>((FutureProviderRef<List<DailyForecast>> ref) async {
  final IPlannerRepository repository = ref.watch(plannerRepositoryProvider);
  final AsyncValue<AstrContext> contextAsync = ref.watch(astrContextProvider);
  final LightPollution lightPollution = ref.watch(lightPollutionProvider); // Watch Light Pollution
  
  final AstrContext? context = contextAsync.value;
  if (context == null) {
    return <DailyForecast>[];
  }
  
  // Pass Bortle Scale (visibilityIndex) to repository
  final Either<Failure, List<DailyForecast>> result = await repository.get7DayForecast(context.location, lightPollution.visibilityIndex);
  
  return result.fold(
    (Failure failure) => throw failure,
    (List<DailyForecast> forecasts) => forecasts,
  );
});
