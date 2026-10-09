import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../context/domain/entities/geo_location.dart';
import '../../../data_layer/repositories/cached_zone_repository.dart';
import '../../../data_layer/services/h3_service.dart';
import '../../domain/repositories/i_weather_repository.dart';

/// Prefetches all data for a location so it's available offline.
///
/// Fetches and caches:
/// - Current weather conditions
/// - Hourly forecast
/// - 7-day daily forecast
/// - Zone/light pollution data
///
/// All calls are fire-and-forget with silent failure (NFR-04).
/// This service is designed to be called immediately after saving a location,
/// ensuring offline availability without blocking the UI.
class LocationPrefetchService {
  LocationPrefetchService({
    required IWeatherRepository weatherRepository,
    required CachedZoneRepository zoneRepository,
    required H3Service h3Service,
  })  : _weather = weatherRepository,
        _zone = zoneRepository,
        _h3 = h3Service;

  final IWeatherRepository _weather;
  final CachedZoneRepository _zone;
  final H3Service _h3;

  /// Prefetches all data types for a single location.
  ///
  /// Runs all fetches concurrently for speed. Each fetch independently
  /// populates the cache via [CachedWeatherRepository] and [CachedZoneRepository].
  ///
  /// Never throws — all errors are caught and logged silently.
  Future<void> prefetchForLocation(GeoLocation location) async {
    debugPrint('Prefetch: Starting for ${location.name ?? 'unnamed'} '
        '(${location.latitude}, ${location.longitude})');

    await Future.wait<void>(<Future<void>>[
      _prefetchCurrentWeather(location),
      _prefetchHourlyForecast(location),
      _prefetchDailyForecast(location),
      _prefetchZoneData(location),
    ]);

    debugPrint('Prefetch: Completed for ${location.name ?? 'unnamed'}');
  }

  /// Prefetches all data for multiple locations.
  ///
  /// Processes locations sequentially with a delay between each
  /// to avoid overwhelming the network and battery.
  Future<int> prefetchForLocations(List<GeoLocation> locations) async {
    int successCount = 0;

    for (final GeoLocation location in locations) {
      try {
        await prefetchForLocation(location);
        successCount++;
      } catch (e) {
        debugPrint('Prefetch: Failed for ${location.name}: $e');
      }
      // Battery-conscious delay between locations
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    debugPrint('Prefetch: Completed $successCount/${locations.length} locations');
    return successCount;
  }

  Future<void> _prefetchCurrentWeather(GeoLocation location) async {
    try {
      final Either<Failure, dynamic> result = await _weather.getWeather(location);
      result.fold(
        (Failure f) => debugPrint('Prefetch: Current weather failed: $f'),
        (_) => debugPrint('Prefetch: Current weather cached'),
      );
    } catch (e) {
      debugPrint('Prefetch: Current weather error: $e');
    }
  }

  Future<void> _prefetchHourlyForecast(GeoLocation location) async {
    try {
      final Either<Failure, dynamic> result = await _weather.getHourlyForecast(location);
      result.fold(
        (Failure f) => debugPrint('Prefetch: Hourly forecast failed: $f'),
        (_) => debugPrint('Prefetch: Hourly forecast cached'),
      );
    } catch (e) {
      debugPrint('Prefetch: Hourly forecast error: $e');
    }
  }

  Future<void> _prefetchDailyForecast(GeoLocation location) async {
    try {
      final Either<Failure, dynamic> result = await _weather.getDailyForecast(location);
      result.fold(
        (Failure f) => debugPrint('Prefetch: Daily forecast failed: $f'),
        (_) => debugPrint('Prefetch: Daily forecast cached'),
      );
    } catch (e) {
      debugPrint('Prefetch: Daily forecast error: $e');
    }
  }

  Future<void> _prefetchZoneData(GeoLocation location) async {
    try {
      final BigInt h3Index = _h3.latLonToH3(
        location.latitude,
        location.longitude,
        8, // Resolution 8 matches zone data
      );
      await _zone.getZoneData(h3Index);
      debugPrint('Prefetch: Zone data cached');
    } catch (e) {
      debugPrint('Prefetch: Zone data error: $e');
    }
  }
}
