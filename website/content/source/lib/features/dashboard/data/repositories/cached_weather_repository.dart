import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../../../../features/context/domain/entities/geo_location.dart';
import '../../../../features/data_layer/services/h3_service.dart';
import '../../domain/entities/daily_weather_data.dart';
import '../../domain/entities/hourly_forecast.dart';
import '../../domain/entities/weather.dart';
import '../../domain/repositories/i_weather_repository.dart';
import '../models/weather_cache_entry.dart';
import '../models/weather_cache_key.dart';

/// Cached decorator for [IWeatherRepository].
///
/// Implements cache-first pattern:
/// 1. Check cache for fresh data
/// 2. If cache miss/stale, fetch from network
/// 3. Cache successful network responses
/// 4. Return stale cache on network failure (FR-09: "Stale but Safe")
///
/// Per Architecture: "Transient Cache using Hive CE for weather forecasts"
class CachedWeatherRepository implements IWeatherRepository {
  CachedWeatherRepository({
    required IWeatherRepository innerRepository,
    required Box<WeatherCacheEntry> cacheBox,
    required H3Service h3Service,
  })  : _inner = innerRepository,
        _cache = cacheBox,
        _h3 = h3Service;

  final IWeatherRepository _inner;
  final Box<WeatherCacheEntry> _cache;
  final H3Service _h3;

  /// H3 resolution for weather caching.
  /// Resolution 8: ~461m edge length - good for local weather granularity.
  static const int _h3Resolution = 8;

  @override
  Future<Either<Failure, Weather>> getWeather(GeoLocation location) async {
    // Generate cache key using H3 index
    final String h3Index = _getH3Index(location);
    final String cacheKey = WeatherCacheKeyGenerator.generate(h3Index, DateTime.now());

    // Try cache first
    final WeatherCacheEntry? cached = _cache.get(cacheKey);
    if (cached != null && !cached.isStale) {
      try {
        final Weather weather = _deserializeWeather(cached.jsonData);
        // Propagate isStale flag and lastUpdated timestamp from cache (FR-09, FR-13)
        return Right(weather.copyWith(
          isStale: cached.isStale,
          lastUpdated: cached.fetchedAt,
        ));
      } catch (e, st) {
        debugPrint('Cache corruption detected for key $cacheKey: $e');
        debugPrint('Stack trace: $st');
        // Cache corruption - continue to network
      }
    }

    // Fetch from network
    final Either<Failure, Weather> result = await _inner.getWeather(location);

    return result.fold(
      (Failure failure) {
        // FR-09: Return stale cache on network failure if available
        if (cached != null) {
          try {
            final Weather staleWeather = _deserializeWeather(cached.jsonData);
            // Mark as stale and include lastUpdated timestamp (FR-09, FR-13)
            return Right(staleWeather.copyWith(
              isStale: true,
              lastUpdated: cached.fetchedAt,
            ));
          } catch (e, st) {
            debugPrint('Failed to deserialize stale cache for key $cacheKey: $e');
            debugPrint('Stack trace: $st');
            // Cache corruption - return network failure
          }
        }
        return Left(failure);
      },
      (Weather weather) {
        // Cache successful response (fire-and-forget)
        _cacheWeather(cacheKey, h3Index, weather);
        // Set lastUpdated to current time for fresh network data (FR-13)
        return Right(weather.copyWith(lastUpdated: DateTime.now().toUtc()));
      },
    );
  }

  @override
  Future<Either<Failure, List<DailyWeatherData>>> getDailyForecast(GeoLocation location) async {
    final String h3Index = _getH3Index(location);

    // Get 7-day range based on location timezone
    final List<DateTime> dateRange = TimezoneHelper.get7DayRange(location.longitude);

    // Check cache for all 7 days
    final List<DailyWeatherData> cachedDays = <DailyWeatherData>[];
    final List<DailyWeatherData> staleDays = <DailyWeatherData>[];
    bool hasMissingOrStale = false;

    for (int i = 0; i < dateRange.length; i++) {
      final DateTime date = dateRange[i];
      final String cacheKey = WeatherCacheKeyGenerator.generateDaily(h3Index, date);
      final WeatherCacheEntry? cached = _cache.get(cacheKey);

      if (cached != null) {
        try {
          final DailyWeatherData data = _deserializeSingleDailyWeather(cached.jsonData);
          // Propagate isStale flag from cache entry to domain model (FR-09)
          final DailyWeatherData dataWithStaleFlag = data.copyWith(isStale: cached.isStale);
          if (cached.isStale) {
            staleDays.add(dataWithStaleFlag);
            hasMissingOrStale = true;
          } else {
            cachedDays.add(dataWithStaleFlag);
          }
        } catch (e, st) {
          debugPrint('Cache corruption for DAY ${i + 1}/7 (key $cacheKey): $e');
          debugPrint('Stack trace: $st');
          hasMissingOrStale = true;
        }
      } else {
        hasMissingOrStale = true;
      }
    }

    // If all 7 days are fresh in cache, return cached data
    if (!hasMissingOrStale && cachedDays.length == 7) {
      // Sort by date to ensure correct order
      cachedDays.sort((DailyWeatherData a, DailyWeatherData b) => a.date.compareTo(b.date));
      return Right(cachedDays);
    }

    // Fetch from network (need to refresh)
    final Either<Failure, List<DailyWeatherData>> result = await _inner.getDailyForecast(location);

    return result.fold(
      (Failure failure) {
        // FR-09: Return stale cache on network failure
        final List<DailyWeatherData> availableData = <DailyWeatherData>[...cachedDays, ...staleDays];
        if (availableData.isNotEmpty) {
          availableData.sort((DailyWeatherData a, DailyWeatherData b) => a.date.compareTo(b.date));
          debugPrint('Network failed, returning ${availableData.length} cached days');
          return Right(availableData);
        }
        return Left(failure);
      },
      (List<DailyWeatherData> forecasts) {
        // Validate API response contains expected 7 days
        if (forecasts.length != 7) {
          debugPrint('WARNING: API returned ${forecasts.length} days instead of 7');
        }

        // Cache each day individually (fire-and-forget)
        _cacheEachDailyForecast(h3Index, forecasts);
        return Right(forecasts);
      },
    );
  }

  /// Caches each day's forecast individually.
  void _cacheEachDailyForecast(String h3Index, List<DailyWeatherData> forecasts) {
    for (final DailyWeatherData forecast in forecasts) {
      final String cacheKey = WeatherCacheKeyGenerator.generateDaily(h3Index, forecast.date);
      try {
        _cache.put(
          cacheKey,
          WeatherCacheEntry(
            h3Index: h3Index,
            date: DateTime.utc(forecast.date.year, forecast.date.month, forecast.date.day),
            jsonData: jsonEncode(_serializeDailyWeather(forecast)),
            fetchedAt: DateTime.now().toUtc(),
            cacheKey: cacheKey,
          ),
        );
      } catch (e, st) {
        debugPrint('Failed to cache day ${forecast.date} for key $cacheKey: $e');
        debugPrint('Stack trace: $st');
        // Silent fail - continue with other days
      }
    }
  }

  /// Deserializes a single DailyWeatherData from JSON string.
  DailyWeatherData _deserializeSingleDailyWeather(String jsonData) {
    final Map<String, dynamic> data = jsonDecode(jsonData) as Map<String, dynamic>;
    return DailyWeatherData(
      date: DateTime.parse(data['date'] as String),
      weatherCode: data['weatherCode'] as int,
      weather: _deserializeWeather(jsonEncode(data['weather'])),
    );
  }

  @override
  Future<Either<Failure, List<HourlyForecast>>> getHourlyForecast(GeoLocation location) async {
    final String h3Index = _getH3Index(location);
    final String cacheKey = WeatherCacheKeyGenerator.generate('${h3Index}_hourly', DateTime.now());

    // Try cache first
    final WeatherCacheEntry? cached = _cache.get(cacheKey);
    if (cached != null && !cached.isStale) {
      try {
        final List<HourlyForecast> forecast = _deserializeHourlyForecast(cached.jsonData);
        // Propagate isStale flag from cache entry to domain models (FR-09)
        final List<HourlyForecast> forecastWithStaleFlag = forecast
            .map((HourlyForecast f) => f.copyWith(isStale: cached.isStale))
            .toList();
        return Right(forecastWithStaleFlag);
      } catch (e, st) {
        debugPrint('Cache corruption detected for hourly forecast key $cacheKey: $e');
        debugPrint('Stack trace: $st');
        // Cache corruption - continue to network
      }
    }

    // Fetch from network
    final Either<Failure, List<HourlyForecast>> result = await _inner.getHourlyForecast(location);

    return result.fold(
      (Failure failure) {
        // Return stale cache on network failure if available
        if (cached != null) {
          try {
            final List<HourlyForecast> staleForecast = _deserializeHourlyForecast(cached.jsonData);
            // Mark as stale since we're returning old data due to network failure
            final List<HourlyForecast> staleForecastWithFlag = staleForecast
                .map((HourlyForecast f) => f.copyWith(isStale: true))
                .toList();
            return Right(staleForecastWithFlag);
          } catch (e, st) {
            debugPrint('Failed to deserialize stale hourly forecast for key $cacheKey: $e');
            debugPrint('Stack trace: $st');
          }
        }
        return Left(failure);
      },
      (List<HourlyForecast> forecast) {
        _cacheHourlyForecast(cacheKey, h3Index, forecast);
        return Right(forecast);
      },
    );
  }

  // ========================
  // Helper Methods
  // ========================

  String _getH3Index(GeoLocation location) {
    try {
      final BigInt index = _h3.latLonToH3(
        location.latitude,
        location.longitude,
        _h3Resolution,
      );
      return index.toRadixString(16);
    } catch (e) {
      // Fallback for platforms without FFI (desktop testing)
      return 'fallback_${location.latitude.toStringAsFixed(4)}_${location.longitude.toStringAsFixed(4)}';
    }
  }

  void _cacheWeather(String key, String h3Index, Weather weather) {
    try {
      final Map<String, dynamic> json = _serializeWeather(weather);
      _cache.put(
        key,
        WeatherCacheEntry(
          h3Index: h3Index,
          date: WeatherCacheKeyGenerator.normalizeDate(DateTime.now()),
          jsonData: jsonEncode(json),
          fetchedAt: DateTime.now().toUtc(),
          cacheKey: key,
        ),
      );
    } catch (e, st) {
      debugPrint('Failed to cache weather for key $key: $e');
      debugPrint('Stack trace: $st');
      // Silent fail - caching is best-effort
    }
  }

  void _cacheHourlyForecast(String key, String h3Index, List<HourlyForecast> forecast) {
    try {
      final List<Map<String, dynamic>> json = forecast.map(_serializeHourlyForecast).toList();
      _cache.put(
        key,
        WeatherCacheEntry(
          h3Index: h3Index,
          date: WeatherCacheKeyGenerator.normalizeDate(DateTime.now()),
          jsonData: jsonEncode(json),
          fetchedAt: DateTime.now().toUtc(),
          cacheKey: key,
        ),
      );
    } catch (e, st) {
      debugPrint('Failed to cache hourly forecast for key $key: $e');
      debugPrint('Stack trace: $st');
    }
  }

  // ========================
  // Serialization
  // ========================

  Map<String, dynamic> _serializeWeather(Weather weather) {
    return {
      'cloudCover': weather.cloudCover,
      'temperatureC': weather.temperatureC,
      'humidity': weather.humidity,
      'windSpeedKph': weather.windSpeedKph,
      'seeingScore': weather.seeingScore,
      'seeingLabel': weather.seeingLabel,
    };
  }

  Weather _deserializeWeather(String jsonData) {
    final Map<String, dynamic> data = jsonDecode(jsonData) as Map<String, dynamic>;
    return Weather(
      cloudCover: (data['cloudCover'] as num).toDouble(),
      temperatureC: (data['temperatureC'] as num?)?.toDouble(),
      humidity: (data['humidity'] as num?)?.toDouble(),
      windSpeedKph: (data['windSpeedKph'] as num?)?.toDouble(),
      seeingScore: data['seeingScore'] as int?,
      seeingLabel: data['seeingLabel'] as String?,
    );
  }

  Map<String, dynamic> _serializeDailyWeather(DailyWeatherData daily) {
    return {
      'date': daily.date.toIso8601String(),
      'weatherCode': daily.weatherCode,
      'weather': _serializeWeather(daily.weather),
    };
  }

  Map<String, dynamic> _serializeHourlyForecast(HourlyForecast hourly) {
    return {
      'time': hourly.time.toIso8601String(),
      'cloudCover': hourly.cloudCover,
      'temperatureC': hourly.temperatureC,
      'humidity': hourly.humidity,
      'windSpeedKph': hourly.windSpeedKph,
      'seeingScore': hourly.seeingScore,
      'seeingLabel': hourly.seeingLabel,
    };
  }

  List<HourlyForecast> _deserializeHourlyForecast(String jsonData) {
    final List<dynamic> list = jsonDecode(jsonData) as List<dynamic>;
    return list.map((dynamic item) {
      final Map<String, dynamic> data = item as Map<String, dynamic>;
      return HourlyForecast(
        time: DateTime.parse(data['time'] as String),
        cloudCover: (data['cloudCover'] as num).toDouble(),
        temperatureC: (data['temperatureC'] as num).toDouble(),
        humidity: data['humidity'] as int,
        windSpeedKph: (data['windSpeedKph'] as num).toDouble(),
        seeingScore: data['seeingScore'] as int,
        seeingLabel: data['seeingLabel'] as String,
      );
    }).toList();
  }
}
