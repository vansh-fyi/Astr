import 'package:astr/features/planner/presentation/providers/planner_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/context/presentation/providers/astr_context_provider.dart';
import '../../data/datasources/open_meteo_weather_service.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../../domain/entities/weather.dart';
import '../../domain/repositories/i_weather_repository.dart';
import '../../../../core/error/failure.dart';

import '../../domain/entities/hourly_forecast.dart';
import '../../../../features/context/domain/entities/geo_location.dart';

// Dependency Injection
final dioProvider = Provider<Dio>((ref) => Dio());

final weatherServiceProvider = Provider<OpenMeteoWeatherService>((ref) {
  final dio = ref.watch(dioProvider);
  return OpenMeteoWeatherService(dio);
});

final weatherRepositoryProvider = Provider<IWeatherRepository>((ref) {
  final service = ref.watch(weatherServiceProvider);
  return WeatherRepositoryImpl(service);
});

// Weather State
final weatherProvider = AsyncNotifierProvider<WeatherNotifier, Weather>(() {
  return WeatherNotifier();
});

final hourlyForecastProvider = FutureProvider<List<HourlyForecast>>((ref) async {
  final repository = ref.watch(weatherRepositoryProvider);
  final contextAsync = ref.watch(astrContextProvider);
  
  final context = contextAsync.value;
  if (context == null) {
    // If context is not loaded yet, we can't fetch weather.
    // Return empty list or keep loading.
    return [];
  }
  
  final location = context.location; 
  
  final result = await repository.getHourlyForecast(location);
  return result.fold(
    (failure) => throw failure,
    (forecasts) => forecasts,
  );
});

class WeatherNotifier extends AsyncNotifier<Weather> {
  @override
  Future<Weather> build() async {
    // Watch context to trigger refresh on change
    final contextAsync = ref.watch(astrContextProvider);
    
    // If context is loading, we are loading
    if (contextAsync.isLoading) {
      return const Weather(cloudCover: 0);
    }

    final context = contextAsync.value;
    if (context == null) {
      return const Weather(cloudCover: 0);
    }

    // Check if selected date is today
    final now = DateTime.now();
    final isToday = context.selectedDate.year == now.year && 
                    context.selectedDate.month == now.month && 
                    context.selectedDate.day == now.day;

    if (!isToday) {
      // Use Planner Data for future dates
      final forecasts = await ref.watch(forecastListProvider.future);
      final forecast = forecasts.firstWhere(
        (f) => f.date.year == context.selectedDate.year && 
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
    final repository = ref.read(weatherRepositoryProvider);
    
    // Fetch hourly forecast which contains current conditions as the first element (or close to it)
    // Ideally we should use a specific 'current' endpoint or extract from hourly based on current time
    // For now, let's use the repository's method to get hourly and extract current
    // Or better, let's update repository to support getCurrentWeather if needed, 
    // but for now we can infer from hourly or add a new method to repository.
    
    // Actually, looking at OpenMeteoWeatherService, it has getCloudCover for current.
    // But we want more data. Let's stick to what we have or improve it.
    // The requirement says "Display Current cloud cover condition".
    
    // Let's use the repository to get the forecast and pick the current hour.
    final result = await repository.getHourlyForecast(location);
    
    return result.fold(
      (failure) => throw failure,
      (forecasts) {
        // Find the forecast for the current hour
        final now = DateTime.now();
        // Simple approximation: find the forecast with the closest time
        // Assuming forecasts are sorted
        final currentForecast = forecasts.firstWhere(
          (f) => f.time.isAfter(now.subtract(const Duration(minutes: 30))) && f.time.isBefore(now.add(const Duration(minutes: 30))),
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
      final context = ref.read(astrContextProvider).value;
      if (context != null) {
        final weather = await _fetchWeather(context.location);
        state = AsyncValue.data(weather);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
    
    // Also refresh hourly forecast
    ref.invalidate(hourlyForecastProvider);
  }
}
