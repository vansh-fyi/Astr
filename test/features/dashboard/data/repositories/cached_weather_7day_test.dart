import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:astr/features/dashboard/data/models/weather_cache_entry.dart';
import 'package:astr/features/dashboard/domain/entities/daily_weather_data.dart';
import 'package:astr/features/dashboard/domain/entities/weather.dart';
import 'package:astr/core/utils/timezone_helper.dart';

void main() {
  late Box<WeatherCacheEntry> cacheBox;
  late Directory tempDir;

  const testWeather = Weather(
    cloudCover: 25.0,
    temperatureC: 18.5,
    humidity: 65.0,
    windSpeedKph: 12.0,
    seeingScore: 7,
    seeingLabel: 'Good',
  );

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('7day_cache_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapter(WeatherCacheEntryAdapter());
  });

  setUp(() async {
    cacheBox = await Hive.openBox<WeatherCacheEntry>('test_7day_${DateTime.now().millisecondsSinceEpoch}');
  });

  tearDown(() async {
    await cacheBox.clear();
    await cacheBox.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('TimezoneHelper', () {
    test('estimates UTC offset from longitude correctly', () {
      expect(TimezoneHelper.estimateUtcOffset(0.0), 0); // UTC (London)
      expect(TimezoneHelper.estimateUtcOffset(-122.4), -8); // PST (San Francisco)
      expect(TimezoneHelper.estimateUtcOffset(139.6), 9); // JST (Tokyo)
      expect(TimezoneHelper.estimateUtcOffset(77.2), 5); // IST (India)
      expect(TimezoneHelper.estimateUtcOffset(-74.0), -5); // EST (New York)
    });

    test('clamps extreme offsets to valid range', () {
      // Extreme longitudes should clamp to max offsets
      expect(TimezoneHelper.estimateUtcOffset(-180.0), -12);
      expect(TimezoneHelper.estimateUtcOffset(180.0), 12);
    });

    test('get7DayRange returns exactly 7 dates', () {
      final dates = TimezoneHelper.get7DayRange(-122.4); // San Francisco
      expect(dates.length, 7);
    });

    test('get7DayRange dates are consecutive', () {
      final dates = TimezoneHelper.get7DayRange(-122.4);
      for (int i = 1; i < dates.length; i++) {
        final diff = dates[i].difference(dates[i - 1]);
        expect(diff.inDays, 1);
      }
    });

    test('get7DayRange dates are normalized to midnight UTC', () {
      final dates = TimezoneHelper.get7DayRange(0.0);
      for (final date in dates) {
        expect(date.hour, 0);
        expect(date.minute, 0);
        expect(date.second, 0);
        expect(date.isUtc, true);
      }
    });
  });

  group('7-Day Cache Key Generation', () {
    test('generates unique key for each day in range', () {
      final keys = TimezoneHelper.generateDailyKeys('8940e92f1bfffff', -122.4);
      expect(keys.length, 7);

      // All keys should be unique
      final uniqueKeys = keys.toSet();
      expect(uniqueKeys.length, 7);
    });

    test('key format matches pattern', () {
      final keys = TimezoneHelper.generateDailyKeys('8940e92f1bfffff', 0.0);
      for (final key in keys) {
        expect(key, matches(RegExp(r'^weather_8940e92f1bfffff_daily_\d{4}-\d{2}-\d{2}$')));
      }
    });
  });

  group('7-Day Cache Storage', () {
    test('stores 7 days individually', () async {
      const h3Index = '8940e92f1bfffff';
      final today = DateTime.now().toUtc();

      // Simulate storing 7 days
      for (int i = 0; i < 7; i++) {
        final date = today.add(Duration(days: i));
        final cacheKey = 'weather_${h3Index}_daily_${_formatDate(date)}';
        final forecast = DailyWeatherData(
          date: date,
          weather: testWeather,
          weatherCode: 1,
        );

        await cacheBox.put(
          cacheKey,
          WeatherCacheEntry(
            h3Index: h3Index,
            date: date,
            jsonData: _serializeDailyWeather(forecast),
            fetchedAt: DateTime.now().toUtc(),
            cacheKey: cacheKey,
          ),
        );
      }

      // Verify all 7 entries exist
      expect(cacheBox.length, 7);
    });

    test('retrieves each day independently', () async {
      const h3Index = '8940e92f1bfffff';
      final today = DateTime.now().toUtc();

      // Store 7 days with different cloud cover values
      for (int i = 0; i < 7; i++) {
        final date = today.add(Duration(days: i));
        final cacheKey = 'weather_${h3Index}_daily_${_formatDate(date)}';
        final forecast = DailyWeatherData(
          date: date,
          weather: Weather(
            cloudCover: 10.0 + i * 5, // Different cloud cover per day
            seeingScore: 5 + i,
          ),
          weatherCode: 1,
        );

        await cacheBox.put(
          cacheKey,
          WeatherCacheEntry(
            h3Index: h3Index,
            date: date,
            jsonData: _serializeDailyWeather(forecast),
            fetchedAt: DateTime.now().toUtc(),
            cacheKey: cacheKey,
          ),
        );
      }

      // Retrieve and verify each day
      for (int i = 0; i < 7; i++) {
        final date = today.add(Duration(days: i));
        final cacheKey = 'weather_${h3Index}_daily_${_formatDate(date)}';
        final entry = cacheBox.get(cacheKey);

        expect(entry, isNotNull);
        expect(entry!.h3Index, h3Index);
      }
    });

    test('cache entries have correct staleness', () async {
      const h3Index = '8940e92f1bfffff';
      final today = DateTime.now().toUtc();
      final cacheKey = 'weather_${h3Index}_daily_${_formatDate(today)}';

      final freshEntry = WeatherCacheEntry(
        h3Index: h3Index,
        date: today,
        jsonData: '{}',
        fetchedAt: DateTime.now().toUtc(), // Fresh
        cacheKey: cacheKey,
      );

      final staleEntry = WeatherCacheEntry(
        h3Index: h3Index,
        date: today,
        jsonData: '{}',
        fetchedAt: DateTime.now().toUtc().subtract(const Duration(hours: 25)), // Stale
        cacheKey: cacheKey,
      );

      expect(freshEntry.isStale, false);
      expect(staleEntry.isStale, true);
    });

    test('partial cache scenario - some days missing', () async {
      const h3Index = '8940e92f1bfffff';
      final today = DateTime.now().toUtc();

      // Store only first 4 days
      for (int i = 0; i < 4; i++) {
        final date = today.add(Duration(days: i));
        final cacheKey = 'weather_${h3Index}_daily_${_formatDate(date)}';
        final forecast = DailyWeatherData(
          date: date,
          weather: testWeather,
          weatherCode: 1,
        );

        await cacheBox.put(
          cacheKey,
          WeatherCacheEntry(
            h3Index: h3Index,
            date: date,
            jsonData: _serializeDailyWeather(forecast),
            fetchedAt: DateTime.now().toUtc(),
            cacheKey: cacheKey,
          ),
        );
      }

      // Check which days exist
      int cachedCount = 0;
      for (int i = 0; i < 7; i++) {
        final date = today.add(Duration(days: i));
        final cacheKey = 'weather_${h3Index}_daily_${_formatDate(date)}';
        if (cacheBox.containsKey(cacheKey)) {
          cachedCount++;
        }
      }

      expect(cachedCount, 4);
      expect(cacheBox.length, 4);
    });
  });

  group('Timezone Edge Cases', () {
    test('handles date boundary at UTC+12', () {
      // Location at UTC+12 (e.g., Fiji)
      final dates = TimezoneHelper.get7DayRange(180.0);
      expect(dates.length, 7);
      
      // All dates should be valid
      for (final date in dates) {
        expect(date.year, greaterThan(2000));
        expect(date.month, inInclusiveRange(1, 12));
        expect(date.day, inInclusiveRange(1, 31));
      }
    });

    test('handles date boundary at UTC-12', () {
      // Location at UTC-12 (e.g., Baker Island)
      final dates = TimezoneHelper.get7DayRange(-180.0);
      expect(dates.length, 7);
      
      // All dates should be valid
      for (final date in dates) {
        expect(date.year, greaterThan(2000));
      }
    });

    test('date could differ from device date at extreme timezone', () {
      // In extreme timezones, "today" could be different from UTC "today"
      // This test verifies the calculation works correctly
      final utcToday = DateTime.now().toUtc();
      final utcDate = DateTime.utc(utcToday.year, utcToday.month, utcToday.day);

      // Location at UTC+14 during certain times could be a day ahead
      final eastDates = TimezoneHelper.get7DayRange(180.0);
      
      // First date should be either same as UTC date or one day ahead
      final diff = eastDates[0].difference(utcDate).inDays;
      expect(diff, inInclusiveRange(0, 1));
    });
  });
}

// Helper functions for test
String _formatDate(DateTime date) {
  final normalized = DateTime.utc(date.year, date.month, date.day);
  return '${normalized.year.toString().padLeft(4, '0')}-'
      '${normalized.month.toString().padLeft(2, '0')}-'
      '${normalized.day.toString().padLeft(2, '0')}';
}

String _serializeDailyWeather(DailyWeatherData daily) {
  return '{"date":"${daily.date.toIso8601String()}",'
      '"weatherCode":${daily.weatherCode},'
      '"weather":{"cloudCover":${daily.weather.cloudCover},'
      '"temperatureC":${daily.weather.temperatureC},'
      '"humidity":${daily.weather.humidity},'
      '"windSpeedKph":${daily.weather.windSpeedKph},'
      '"seeingScore":${daily.weather.seeingScore},'
      '"seeingLabel":"${daily.weather.seeingLabel}"}}';
}
