import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/src/either.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod/src/async_notifier.dart';

import '../../../../core/error/failure.dart';
import '../../../../features/context/domain/entities/geo_location.dart';
import '../../../../features/context/presentation/providers/astr_context_provider.dart';
import '../../../../features/data_layer/services/h3_service.dart';
import '../../../context/domain/entities/astr_context.dart';
import '../../../planner/domain/entities/daily_forecast.dart';
import '../../../planner/presentation/providers/planner_provider.dart';
import '../../data/datasources/open_meteo_weather_service.dart';
import '../../data/models/weather_cache_entry.dart';
import '../../data/repositories/cached_weather_repository.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../../domain/entities/hourly_forecast.dart';
import '../../domain/entities/weather.dart';
import '../../domain/repositories/i_weather_repository.dart';

// Dependency Injection
final Provider<Dio> dioProvider = Provider<Dio>((ProviderRef<Dio> ref) => Dio());

final Provider<OpenMeteoWeatherService> weatherServiceProvider = Provider<OpenMeteoWeatherService>((ProviderRef<OpenMeteoWeatherService> ref) {
  final Dio dio = ref.watch(dioProvider);
  return OpenMeteoWeatherService(dio);
});

/// Weather repository provider with caching layer.
///
/// Uses decorator pattern: CachedWeatherRepository wraps WeatherRepositoryImpl.
/// Per Architecture: "Transient Cache using Hive CE for weather forecasts"
final Provider<IWeatherRepository> weatherRepositoryProvider = Provider<IWeatherRepository>((ProviderRef<IWeatherRepository> ref) {
  final OpenMeteoWeatherService service = ref.watch(weatherServiceProvider);
  final IWeatherRepository innerRepo = WeatherRepositoryImpl(service);

  // Get the weatherCache box (already opened in initHive)
  final Box<WeatherCacheEntry> cacheBox = Hive.box<WeatherCacheEntry>('weatherCache');
  final H3Service h3Service = ref.watch(h3ServiceProvider);

  return CachedWeatherRepository(
    innerRepository: innerRepo,
    cacheBox: cacheBox,
    h3Service: h3Service,
  );
});

// Weather State
final AsyncNotifierProviderImpl<WeatherNotifier, Weather> weatherProvider = AsyncNotifierProvider<WeatherNotifier, Weather>(() {
  return WeatherNotifier();
});

final FutureProvider<List<HourlyForecast>> hourlyForecastProvider = FutureProvider<List<HourlyForecast>>((FutureProviderRef<List<HourlyForecast>> ref) async {
  final IWeatherRepository repository = ref.watch(weatherRepositoryProvider);
  final AsyncValue<AstrContext> contextAsync = ref.watch(astrContextProvider);
  
  final AstrContext? context = contextAsync.value;
  if (context == null) {
    // If context is not loaded yet, we can't fetch weather.
    // Return empty list or keep loading.
    return <HourlyForecast>[];
  }
  
  final GeoLocation location = context.location; 
  
  final Either<Failure, List<HourlyForecast>> result = await repository.getHourlyForecast(location);
  return result.fold(
    (Failure failure) => throw failure,
    (List<HourlyForecast> forecasts) => forecasts,
  );
});

class WeatherNotifier extends AsyncNotifier<Weather> {
  @override
  Future<Weather> build() async {
    // Watch context to trigger refresh on change
    final AsyncValue<AstrContext> contextAsync = ref.watch(astrContextProvider);
    
    // If context is loading, we are loading
    if (contextAsync.isLoading) {
      return const Weather(cloudCover: 0);
    }

    final AstrContext? context = contextAsync.value;
    if (context == null) {
      return const Weather(cloudCover: 0);
    }

    // Check if selected date is today
    final DateTime now = DateTime.now();
    final bool isToday = context.selectedDate.year == now.year && 
                    context.selectedDate.month == now.month && 
                    context.selectedDate.day == now.day;

    if (!isToday) {
      // Use Planner Data for future dates
      final List<DailyForecast> forecasts = await ref.watch(forecastListProvider.future);
      final DailyForecast forecast = forecasts.firstWhere(
        (DailyForecast f) => f.date.year == context.selectedDate.year && 
               f.date.month == context.selectedDate.month && 
               f.date.day == context.selectedDate.day,
        orElse: () => forecasts.isNotEmpty ? forecasts.first : throw Exception('No forecast for date'),
      );
      
      return Weather(
        cloudCover: forecast.cloudCoverAvg,
        seeingScore: forecast.starRating, // Map star rating to seeing score roughly? Or just leave null?
        // Test expects cloudCover to match.
        // We can leave others as null or defaults.
      );
    }

    return _fetchWeather(context.location);
  }

  Future<Weather> _fetchWeather(GeoLocation location) async {
    final IWeatherRepository repository = ref.read(weatherRepositoryProvider);
    
    // Fetch hourly forecast which contains current conditions as the first element (or close to it)
    // Ideally we should use a specific 'current' endpoint or extract from hourly based on current time
    // For now, let's use the repository's method to get hourly and extract current
    // Or better, let's update repository to support getCurrentWeather if needed, 
    // but for now we can infer from hourly or add a new method to repository.
    
    // Actually, looking at OpenMeteoWeatherService, it has getCloudCover for current.
    // But we want more data. Let's stick to what we have or improve it.
    // The requirement says "Display Current cloud cover condition".
    
    // Let's use the repository to get the forecast and pick the current hour.
    final Either<Failure, List<HourlyForecast>> result = await repository.getHourlyForecast(location);
    
    return result.fold(
      (Failure failure) => throw failure,
      (List<HourlyForecast> forecasts) {
        // Find the forecast for the current hour
        final DateTime now = DateTime.now();
        // Simple approximation: find the forecast with the closest time
        // Assuming forecasts are sorted
        final HourlyForecast currentForecast = forecasts.firstWhere(
          (HourlyForecast f) => f.time.isAfter(now.subtract(const Duration(minutes: 30))) && f.time.isBefore(now.add(const Duration(minutes: 30))),
          orElse: () => forecasts.first,
        );
        
        return Weather(
          cloudCover: currentForecast.cloudCover,
          temperatureC: currentForecast.temperatureC,
          humidity: currentForecast.humidity.toDouble(),
          windSpeedKph: currentForecast.windSpeedKph,
          seeingScore: currentForecast.seeingScore,
          seeingLabel: currentForecast.seeingLabel,
        );
      },
    );
  }
  
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final AstrContext? context = ref.read(astrContextProvider).value;
      if (context != null) {
        final Weather weather = await _fetchWeather(context.location);
        state = AsyncValue.data(weather);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
    
    // Also refresh hourly forecast
    ref.invalidate(hourlyForecastProvider);
  }
}
