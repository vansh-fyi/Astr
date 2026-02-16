import 'dart:io';

import 'package:astr/core/utils/timezone_helper.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';

import 'package:astr/core/error/failure.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/dashboard/data/models/weather_cache_entry.dart';
import 'package:astr/features/dashboard/data/models/weather_cache_key.dart';
import 'package:astr/features/dashboard/data/repositories/cached_weather_repository.dart';
import 'package:astr/features/dashboard/domain/entities/daily_weather_data.dart';
import 'package:astr/features/dashboard/domain/entities/hourly_forecast.dart';
import 'package:astr/features/dashboard/domain/entities/weather.dart';
import 'package:astr/features/dashboard/domain/repositories/i_weather_repository.dart';
import 'package:astr/features/data_layer/services/h3_service.dart';

/// Fake implementation of IWeatherRepository for testing.
class FakeWeatherRepository implements IWeatherRepository {
  Weather? weatherToReturn;
  List<HourlyForecast>? hourlyToReturn;
  List<DailyWeatherData>? dailyToReturn;
  Failure? failureToReturn;
  int getWeatherCallCount = 0;
  int getHourlyForecastCallCount = 0;
  int getDailyForecastCallCount = 0;

  @override
  Future<Either<Failure, Weather>> getWeather(GeoLocation location) async {
    getWeatherCallCount++;
    if (failureToReturn != null) return Left(failureToReturn!);
    return Right(weatherToReturn!);
  }

  @override
  Future<Either<Failure, List<HourlyForecast>>> getHourlyForecast(GeoLocation location) async {
    getHourlyForecastCallCount++;
    if (failureToReturn != null) return Left(failureToReturn!);
    return Right(hourlyToReturn!);
  }

  @override
  Future<Either<Failure, List<DailyWeatherData>>> getDailyForecast(GeoLocation location) async {
    getDailyForecastCallCount++;
    if (failureToReturn != null) return Left(failureToReturn!);
    return Right(dailyToReturn!);
  }
}

void main() {
  late FakeWeatherRepository fakeInner;
  late Box<WeatherCacheEntry> cacheBox;
  late CachedWeatherRepository sut;
  late Directory tempDir;
  late H3Service? h3Service;
  late String testH3Index; // Will be either real H3 or fallback

  final testLocation = GeoLocation(
    latitude: 37.7749,
    longitude: -122.4194,
    name: 'San Francisco',
  );

  // Helper to generate expected cache key (matches repository logic)
  String getExpectedH3Index(GeoLocation location) {
    if (h3Service != null) {
      try {
        return h3Service!.latLonToH3(location.latitude, location.longitude, 8).toRadixString(16);
      } catch (_) {}
    }
    // Fallback matches cached_weather_repository.dart:171
    return 'fallback_${location.latitude.toStringAsFixed(4)}_${location.longitude.toStringAsFixed(4)}';
  }

  final testWeather = const Weather(
    cloudCover: 25.0,
    temperatureC: 18.5,
    humidity: 65.0,
    windSpeedKph: 12.0,
    seeingScore: 7,
    seeingLabel: 'Good',
  );

  final testHourlyForecasts = [
    HourlyForecast(
      time: DateTime.now(),
      cloudCover: 30.0,
      temperatureC: 20.0,
      humidity: 60,
      windSpeedKph: 10.0,
      seeingScore: 6,
      seeingLabel: 'Fair',
    ),
  ];

  final testDailyForecasts = [
    DailyWeatherData(
      date: DateTime.now(),
      weather: testWeather,
      weatherCode: 1,
    ),
  ];

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cached_repo_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapter(WeatherCacheEntryAdapter());

    // Try to initialize H3Service once for all tests
    // If FFI not available (desktop), tests will use fallback logic
    try {
      h3Service = H3Service();
    } catch (e) {
      // Desktop/unsupported platform - repository will use fallback coordinate-based keys
      h3Service = null;
      print('H3Service FFI not available, using fallback logic: $e');
    }
  });

  setUp(() async {
    fakeInner = FakeWeatherRepository();
    cacheBox = await Hive.openBox<WeatherCacheEntry>('test_cache_${DateTime.now().millisecondsSinceEpoch}');

    testH3Index = getExpectedH3Index(testLocation);

    // Create H3Service if not already initialized
    H3Service serviceToUse;
    if (h3Service != null) {
      serviceToUse = h3Service!;
    } else {
      // Try one more time in case FFI is now available
      try {
        serviceToUse = H3Service();
      } catch (e) {
        // FFI still not available - skip all tests
        throw StateError('H3Service FFI not available. Skipping cached repository tests on this platform.');
      }
    }

    sut = CachedWeatherRepository(
      innerRepository: fakeInner,
      cacheBox: cacheBox,
      h3Service: serviceToUse,
    );
  });

  tearDown(() async {
    await cacheBox.clear();
    await cacheBox.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('CachedWeatherRepository - getWeather', () {
    test('CACHE MISS: calls network and caches successful response', () async {
      // Arrange: No cache, network returns success
      fakeInner.weatherToReturn = testWeather;

      // Act
      final result = await sut.getWeather(testLocation);

      // Assert: Network was called
      expect(fakeInner.getWeatherCallCount, 1);

      // Assert: Result is correct
      expect(result.isRight(), true);
      final weather = result.getOrElse((l) => throw Exception());
      expect(weather.cloudCover, 25.0);

      // Assert: Data was cached
      expect(cacheBox.length, 1);
      final cachedEntry = cacheBox.values.first;
      expect(cachedEntry.jsonData, contains('25.0'));
    });

    test('CACHE HIT (fresh): returns cached data WITHOUT calling network', () async {
      // Arrange: Pre-populate cache with fresh data
      final cacheKey = WeatherCacheKeyGenerator.generate(testH3Index, DateTime.now());

      await cacheBox.put(
        cacheKey,
        WeatherCacheEntry(
          h3Index: testH3Index,
          date: WeatherCacheKeyGenerator.normalizeDate(DateTime.now()),
          jsonData: '{"cloudCover":50.0,"temperatureC":20.0,"humidity":70.0,"windSpeedKph":15.0,"seeingScore":8,"seeingLabel":"Excellent"}',
          fetchedAt: DateTime.now().toUtc(), // Fresh
          cacheKey: cacheKey,
        ),
      );

      // Act
      final result = await sut.getWeather(testLocation);

      // Assert: Network was NOT called (AC2 validation)
      expect(fakeInner.getWeatherCallCount, 0);

      // Assert: Cached data returned
      expect(result.isRight(), true);
      final weather = result.getOrElse((l) => throw Exception());
      expect(weather.cloudCover, 50.0);
      expect(weather.seeingLabel, 'Excellent');
    });

    test('CACHE STALE: fetches from network and updates cache', () async {
      // Arrange: Pre-populate cache with stale data (>24h old)
      final cacheKey = WeatherCacheKeyGenerator.generate(testH3Index, DateTime.now());

      await cacheBox.put(
        cacheKey,
        WeatherCacheEntry(
          h3Index: testH3Index,
          date: WeatherCacheKeyGenerator.normalizeDate(DateTime.now()),
          jsonData: '{"cloudCover":99.0,"temperatureC":10.0,"humidity":90.0,"windSpeedKph":5.0,"seeingScore":1,"seeingLabel":"Poor"}',
          fetchedAt: DateTime.now().toUtc().subtract(const Duration(hours: 25)), // Stale
          cacheKey: cacheKey,
        ),
      );

      fakeInner.weatherToReturn = testWeather;

      // Act
      final result = await sut.getWeather(testLocation);

      // Assert: Network was called because cache was stale
      expect(fakeInner.getWeatherCallCount, 1);

      // Assert: Fresh data returned
      final weather = result.getOrElse((l) => throw Exception());
      expect(weather.cloudCover, 25.0); // New data, not 99.0
    });

    test('FR-09: Network FAILS but stale cache exists → returns stale data', () async {
      // Arrange: Stale cache + network failure
      final cacheKey = WeatherCacheKeyGenerator.generate(testH3Index, DateTime.now());

      await cacheBox.put(
        cacheKey,
        WeatherCacheEntry(
          h3Index: testH3Index,
          date: WeatherCacheKeyGenerator.normalizeDate(DateTime.now()),
          jsonData: '{"cloudCover":75.0,"temperatureC":12.0,"humidity":80.0,"windSpeedKph":20.0,"seeingScore":3,"seeingLabel":"Fair"}',
          fetchedAt: DateTime.now().toUtc().subtract(const Duration(hours: 30)), // Stale
          cacheKey: cacheKey,
        ),
      );

      fakeInner.failureToReturn = const ServerFailure('Network error');

      // Act
      final result = await sut.getWeather(testLocation);

      // Assert: Network was attempted
      expect(fakeInner.getWeatherCallCount, 1);

      // Assert: Despite failure, stale cache returned (FR-09 compliance)
      expect(result.isRight(), true);
      final weather = result.getOrElse((l) => throw Exception());
      expect(weather.cloudCover, 75.0); // Stale data returned
    });

    test('Network FAILS and NO cache → returns failure', () async {
      // Arrange: No cache, network fails
      fakeInner.failureToReturn = const ServerFailure('Network error');

      // Act
      final result = await sut.getWeather(testLocation);

      // Assert: Network was attempted
      expect(fakeInner.getWeatherCallCount, 1);

      // Assert: Failure returned
      expect(result.isLeft(), true);
    });

    test('Cache corruption: falls back to network gracefully', () async {
      // Arrange: Cache with invalid JSON
      final cacheKey = WeatherCacheKeyGenerator.generate(testH3Index, DateTime.now());

      await cacheBox.put(
        cacheKey,
        WeatherCacheEntry(
          h3Index: testH3Index,
          date: WeatherCacheKeyGenerator.normalizeDate(DateTime.now()),
          jsonData: 'CORRUPT{{{JSON', // Invalid JSON
          fetchedAt: DateTime.now().toUtc(),
          cacheKey: cacheKey,
        ),
      );

      fakeInner.weatherToReturn = testWeather;

      // Act
      final result = await sut.getWeather(testLocation);

      // Assert: Network was called despite cache present
      expect(fakeInner.getWeatherCallCount, 1);

      // Assert: Valid data returned from network
      expect(result.isRight(), true);
      final weather = result.getOrElse((l) => throw Exception());
      expect(weather.cloudCover, 25.0);
    });
  });

  group('CachedWeatherRepository - getHourlyForecast', () {
    test('CACHE HIT: returns cached hourly without network call', () async {
      // Arrange
      final cacheKey = WeatherCacheKeyGenerator.generate('${testH3Index}_hourly', DateTime.now());

      await cacheBox.put(
        cacheKey,
        WeatherCacheEntry(
          h3Index: testH3Index,
          date: WeatherCacheKeyGenerator.normalizeDate(DateTime.now()),
          jsonData: '[{"time":"2025-12-31T10:00:00.000","cloudCover":40.0,"temperatureC":22.0,"humidity":55,"windSpeedKph":8.0,"seeingScore":9,"seeingLabel":"Excellent"}]',
          fetchedAt: DateTime.now().toUtc(),
          cacheKey: cacheKey,
        ),
      );

      // Act
      final result = await sut.getHourlyForecast(testLocation);

      // Assert: No network call
      expect(fakeInner.getHourlyForecastCallCount, 0);

      // Assert: Cached data returned
      expect(result.isRight(), true);
      final forecasts = result.getOrElse((l) => throw Exception());
      expect(forecasts.length, 1);
      expect(forecasts.first.cloudCover, 40.0);
    });

    test('CACHE MISS: fetches from network', () async {
      fakeInner.hourlyToReturn = testHourlyForecasts;

      final result = await sut.getHourlyForecast(testLocation);

      expect(fakeInner.getHourlyForecastCallCount, 1);
      expect(result.isRight(), true);
    });
  });

  group('CachedWeatherRepository - getDailyForecast', () {
    test('CACHE HIT: returns cached daily without network call when all 7 days fresh', () async {
      // Arrange: Use TimezoneHelper to match production date range
      // Production code uses TimezoneHelper.get7DayRange(location.longitude)
      // which may yield different dates than DateTime.now().toUtc()
      final List<DateTime> dateRange = TimezoneHelper.get7DayRange(testLocation.longitude);
      
      for (int i = 0; i < dateRange.length; i++) {
        final date = dateRange[i];
        final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final cacheKey = 'weather_${testH3Index}_daily_$dateStr';
        
        await cacheBox.put(
          cacheKey,
          WeatherCacheEntry(
            h3Index: testH3Index,
            date: date,
            jsonData: '{"date":"${date.toIso8601String()}","weatherCode":2,"weather":{"cloudCover":35.0,"temperatureC":19.0,"humidity":60.0,"windSpeedKph":14.0,"seeingScore":6,"seeingLabel":"Good"}}',
            fetchedAt: DateTime.now().toUtc(),
            cacheKey: cacheKey,
          ),
        );
      }

      // Act
      final result = await sut.getDailyForecast(testLocation);

      // Assert: No network call when all 7 days are fresh
      expect(fakeInner.getDailyForecastCallCount, 0);

      // Assert: Cached data returned with 7 days
      expect(result.isRight(), true);
      final forecasts = result.getOrElse((l) => throw Exception());
      expect(forecasts.length, 7);
      expect(forecasts.first.weather.cloudCover, 35.0);
    });

    test('CACHE MISS: fetches from network when any day missing', () async {
      fakeInner.dailyToReturn = testDailyForecasts;

      final result = await sut.getDailyForecast(testLocation);

      expect(fakeInner.getDailyForecastCallCount, 1);
      expect(result.isRight(), true);
    });

    test('PARTIAL CACHE: returns partial on network failure', () async {
      // Cache only 3 days, using TimezoneHelper date range
      final List<DateTime> dateRange = TimezoneHelper.get7DayRange(testLocation.longitude);
      
      for (int i = 0; i < 3; i++) {
        final date = dateRange[i];
        final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final cacheKey = 'weather_${testH3Index}_daily_$dateStr';
        
        await cacheBox.put(
          cacheKey,
          WeatherCacheEntry(
            h3Index: testH3Index,
            date: date,
            jsonData: '{"date":"${date.toIso8601String()}","weatherCode":1,"weather":{"cloudCover":20.0,"temperatureC":15.0,"humidity":50.0,"windSpeedKph":10.0,"seeingScore":8,"seeingLabel":"Excellent"}}',
            fetchedAt: DateTime.now().toUtc(),
            cacheKey: cacheKey,
          ),
        );
      }

      // Simulate network failure
      fakeInner.failureToReturn = ServerFailure('Offline');
      fakeInner.dailyToReturn = null;

      final result = await sut.getDailyForecast(testLocation);

      // Should return partial cache (3 days)
      expect(result.isRight(), true);
      final forecasts = result.getOrElse((l) => throw Exception());
      expect(forecasts.length, 3);
    });
  });

  group('Story 3.3 - isStale Flag Propagation', () {
    test('getWeather: Fresh cache returns Weather with isStale=false', () async {
      // Arrange: Fresh cache (less than 24 hours old)
      final cacheKey = WeatherCacheKeyGenerator.generate(testH3Index, DateTime.now());
      final freshEntry = WeatherCacheEntry(
        h3Index: testH3Index,
        date: WeatherCacheKeyGenerator.normalizeDate(DateTime.now()),
        jsonData: '{"cloudCover":15.0,"temperatureC":20.0,"humidity":50.0,"windSpeedKph":5.0,"seeingScore":8,"seeingLabel":"Excellent"}',
        fetchedAt: DateTime.now().toUtc(),
        cacheKey: cacheKey,
      );
      await cacheBox.put(cacheKey, freshEntry);

      // Act
      final result = await sut.getWeather(testLocation);

      // Assert: Fresh cache has isStale=false
      expect(result.isRight(), true);
      final weather = result.getOrElse((l) => throw Exception());
      expect(weather.isStale, false, reason: 'Fresh cache should have isStale=false');
      expect(fakeInner.getWeatherCallCount, 0, reason: 'Should not call network for fresh cache');
    });

    test('getWeather: Stale cache on network failure returns Weather with isStale=true', () async {
      // Arrange: Stale cache (more than 24 hours old)
      final cacheKey = WeatherCacheKeyGenerator.generate(testH3Index, DateTime.now());
      final staleEntry = WeatherCacheEntry(
        h3Index: testH3Index,
        date: WeatherCacheKeyGenerator.normalizeDate(DateTime.now()),
        jsonData: '{"cloudCover":75.0,"temperatureC":18.0,"humidity":60.0,"windSpeedKph":15.0,"seeingScore":3,"seeingLabel":"Poor"}',
        fetchedAt: DateTime.now().subtract(const Duration(hours: 30)).toUtc(), // 30 hours ago = stale
        cacheKey: cacheKey,
      );
      await cacheBox.put(cacheKey, staleEntry);

      // Simulate network failure
      fakeInner.failureToReturn = const ServerFailure('Network error');

      // Act
      final result = await sut.getWeather(testLocation);

      // Assert: Stale cache returned with isStale=true (FR-09)
      expect(result.isRight(), true, reason: 'Should return stale cache on network failure');
      final weather = result.getOrElse((l) => throw Exception());
      expect(weather.isStale, true, reason: 'Stale cache on network failure must have isStale=true');
      expect(weather.cloudCover, 75.0, reason: 'Should return stale cached data');
    });

    test('getHourlyForecast: Fresh cache returns HourlyForecast with isStale=false', () async {
      // Arrange: Fresh cache
      final cacheKey = WeatherCacheKeyGenerator.generate('${testH3Index}_hourly', DateTime.now());
      final freshEntry = WeatherCacheEntry(
        h3Index: testH3Index,
        date: WeatherCacheKeyGenerator.normalizeDate(DateTime.now()),
        jsonData: '[{"time":"2025-12-31T10:00:00.000","cloudCover":20.0,"temperatureC":22.0,"humidity":45,"windSpeedKph":8.0,"seeingScore":9,"seeingLabel":"Excellent"}]',
        fetchedAt: DateTime.now().toUtc(),
        cacheKey: cacheKey,
      );
      await cacheBox.put(cacheKey, freshEntry);

      // Act
      final result = await sut.getHourlyForecast(testLocation);

      // Assert
      expect(result.isRight(), true);
      final forecasts = result.getOrElse((l) => throw Exception());
      expect(forecasts.length, 1);
      expect(forecasts.first.isStale, false, reason: 'Fresh cache should have isStale=false');
      expect(fakeInner.getHourlyForecastCallCount, 0, reason: 'Should not call network for fresh cache');
    });

    test('getHourlyForecast: Stale cache on network failure returns HourlyForecast with isStale=true', () async {
      // Arrange: Stale cache
      final cacheKey = WeatherCacheKeyGenerator.generate('${testH3Index}_hourly', DateTime.now());
      final staleEntry = WeatherCacheEntry(
        h3Index: testH3Index,
        date: WeatherCacheKeyGenerator.normalizeDate(DateTime.now()),
        jsonData: '[{"time":"2025-12-31T10:00:00.000","cloudCover":85.0,"temperatureC":16.0,"humidity":80,"windSpeedKph":25.0,"seeingScore":2,"seeingLabel":"Poor"}]',
        fetchedAt: DateTime.now().subtract(const Duration(hours: 48)).toUtc(), // 48 hours ago = stale
        cacheKey: cacheKey,
      );
      await cacheBox.put(cacheKey, staleEntry);

      // Simulate network failure
      fakeInner.failureToReturn = const ServerFailure('Network error');

      // Act
      final result = await sut.getHourlyForecast(testLocation);

      // Assert
      expect(result.isRight(), true, reason: 'Should return stale cache on network failure');
      final forecasts = result.getOrElse((l) => throw Exception());
      expect(forecasts.length, 1);
      expect(forecasts.first.isStale, true, reason: 'Stale cache on network failure must have isStale=true');
      expect(forecasts.first.cloudCover, 85.0, reason: 'Should return stale cached data');
    });

    test('getDailyForecast: Fresh cache returns DailyWeatherData with isStale=false', () async {
      // Arrange: Cache all 7 days as fresh using TimezoneHelper date range
      final List<DateTime> dateRange = TimezoneHelper.get7DayRange(testLocation.longitude);

      for (int i = 0; i < dateRange.length; i++) {
        final date = dateRange[i];
        final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final cacheKey = 'weather_${testH3Index}_daily_$dateStr';

        await cacheBox.put(
          cacheKey,
          WeatherCacheEntry(
            h3Index: testH3Index,
            date: date,
            jsonData: '{"date":"${date.toIso8601String()}","weatherCode":1,"weather":{"cloudCover":10.0,"temperatureC":25.0,"humidity":40.0,"windSpeedKph":5.0,"seeingScore":9,"seeingLabel":"Excellent"}}',
            fetchedAt: DateTime.now().toUtc(), // Fresh
            cacheKey: cacheKey,
          ),
        );
      }

      // Act
      final result = await sut.getDailyForecast(testLocation);

      // Assert
      expect(result.isRight(), true);
      final forecasts = result.getOrElse((l) => throw Exception());
      expect(forecasts.length, 7);
      for (final forecast in forecasts) {
        expect(forecast.isStale, false, reason: 'All fresh cached days should have isStale=false');
      }
      expect(fakeInner.getDailyForecastCallCount, 0, reason: 'Should not call network for fresh cache');
    });

    test('getDailyForecast: Stale cache returns DailyWeatherData with isStale=true', () async {
      // Arrange: Cache all 7 days as stale using TimezoneHelper date range
      final List<DateTime> dateRange = TimezoneHelper.get7DayRange(testLocation.longitude);

      for (int i = 0; i < dateRange.length; i++) {
        final date = dateRange[i];
        final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final cacheKey = 'weather_${testH3Index}_daily_$dateStr';

        await cacheBox.put(
          cacheKey,
          WeatherCacheEntry(
            h3Index: testH3Index,
            date: date,
            jsonData: '{"date":"${date.toIso8601String()}","weatherCode":3,"weather":{"cloudCover":90.0,"temperatureC":12.0,"humidity":85.0,"windSpeedKph":30.0,"seeingScore":1,"seeingLabel":"Very Poor"}}',
            fetchedAt: DateTime.now().subtract(const Duration(hours: 48)).toUtc(), // Stale
            cacheKey: cacheKey,
          ),
        );
      }

      // Simulate network failure
      fakeInner.failureToReturn = const ServerFailure('Network error');

      // Act
      final result = await sut.getDailyForecast(testLocation);

      // Assert: All stale cache returned with isStale=true (FR-09)
      expect(result.isRight(), true, reason: 'Should return stale cache on network failure');
      final forecasts = result.getOrElse((l) => throw Exception());
      expect(forecasts.length, 7);
      for (final forecast in forecasts) {
        expect(forecast.isStale, true, reason: 'All stale cached days should have isStale=true');
      }
    });

    test('Network success returns fresh data with isStale=false', () async {
      // Arrange
      fakeInner.weatherToReturn = testWeather;

      // Act
      final result = await sut.getWeather(testLocation);

      // Assert: Fresh network data has isStale=false
      expect(result.isRight(), true);
      final weather = result.getOrElse((l) => throw Exception());
      expect(weather.isStale, false, reason: 'Fresh network data should have isStale=false');
    });
  });

  group('Serialization Integration', () {
    test('persists complex JSON data through cache cycle', () async {
      const complexJson = '''
      {
        "hourly": {
          "time": ["2025-12-31T00:00", "2025-12-31T01:00"],
          "cloudCover": [25, 30],
          "temperature": [15.5, 14.2]
        }
      }
      ''';

      final entry = WeatherCacheEntry(
        h3Index: 'h3_test',
        date: DateTime.utc(2025, 12, 31),
        jsonData: complexJson,
        fetchedAt: DateTime.now().toUtc(),
        cacheKey: 'weather_h3_test_2025-12-31',
      );

      await cacheBox.put('complex', entry);
      final retrieved = cacheBox.get('complex');

      expect(retrieved!.jsonData, complexJson);
    });

    test('cache key generation is consistent for same location same day', () {
      final key1 = WeatherCacheKeyGenerator.generate('h3_test', DateTime.now());
      final key2 = WeatherCacheKeyGenerator.generate('h3_test', DateTime.now());

      expect(key1, key2);
    });

    test('cache key generation differs for different days', () {
      final key1 = WeatherCacheKeyGenerator.generate('h3_test', DateTime(2025, 12, 31));
      final key2 = WeatherCacheKeyGenerator.generate('h3_test', DateTime(2025, 12, 30));

      expect(key1, isNot(key2));
    });
  });
}
