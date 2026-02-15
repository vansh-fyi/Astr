import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:astr/features/dashboard/data/models/weather_cache_entry.dart';
import 'package:astr/features/dashboard/data/models/weather_cache_key.dart';

void main() {
  group('WeatherCacheKeyGenerator', () {
    test('generates correct key format', () {
      const h3Index = '881f92f4c3fffff';
      final date = DateTime.utc(2025, 12, 31, 14, 30); // Any time

      final key = WeatherCacheKeyGenerator.generate(h3Index, date);

      expect(key, 'weather_881f92f4c3fffff_2025-12-31');
    });

    test('normalizes date to midnight UTC', () {
      const h3Index = '881f92f4c3fffff';
      final date = DateTime(2025, 12, 31, 23, 59, 59); // Local time late night

      final key = WeatherCacheKeyGenerator.generate(h3Index, date);

      // Key should use UTC midnight date
      expect(key, contains('2025-12-31'));
    });

    test('pads month and day with zeros', () {
      const h3Index = '881f92f4c3fffff';
      final date = DateTime.utc(2025, 1, 5); // Single digit month and day

      final key = WeatherCacheKeyGenerator.generate(h3Index, date);

      expect(key, 'weather_881f92f4c3fffff_2025-01-05');
    });

    test('normalizeDate returns midnight UTC', () {
      final date = DateTime(2025, 6, 15, 18, 30, 45);

      final normalized = WeatherCacheKeyGenerator.normalizeDate(date);

      expect(normalized.hour, 0);
      expect(normalized.minute, 0);
      expect(normalized.second, 0);
      expect(normalized.isUtc, true);
    });
  });

  group('WeatherCacheEntry', () {
    late Directory tempDir;
    late Box<WeatherCacheEntry> box;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
      Hive.registerAdapter(WeatherCacheEntryAdapter());
    });

    setUp(() async {
      box = await Hive.openBox<WeatherCacheEntry>('test_weather_cache');
    });

    tearDown(() async {
      await box.clear();
      await box.close();
    });

    tearDownAll(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('serializes and deserializes correctly', () async {
      final entry = WeatherCacheEntry(
        h3Index: '881f92f4c3fffff',
        date: DateTime.utc(2025, 12, 31),
        jsonData: '{"cloud_cover": 25, "temp": 15.5}',
        fetchedAt: DateTime.utc(2025, 12, 31, 12, 0),
        cacheKey: 'weather_881f92f4c3fffff_2025-12-31',
      );

      await box.put('test_key', entry);
      final retrieved = box.get('test_key');

      expect(retrieved, isNotNull);
      expect(retrieved!.h3Index, '881f92f4c3fffff');
      expect(retrieved.date, DateTime.utc(2025, 12, 31));
      expect(retrieved.jsonData, '{"cloud_cover": 25, "temp": 15.5}');
      expect(retrieved.fetchedAt, DateTime.utc(2025, 12, 31, 12, 0));
      expect(retrieved.cacheKey, 'weather_881f92f4c3fffff_2025-12-31');
    });

    test('isStale returns false for fresh cache', () {
      final entry = WeatherCacheEntry(
        h3Index: '881f92f4c3fffff',
        date: DateTime.now().toUtc(),
        jsonData: '{}',
        fetchedAt: DateTime.now().toUtc(), // Just fetched
        cacheKey: 'test_key',
      );

      expect(entry.isStale, false);
    });

    test('isStale returns true for cache older than 24 hours', () {
      final entry = WeatherCacheEntry(
        h3Index: '881f92f4c3fffff',
        date: DateTime.now().toUtc(),
        jsonData: '{}',
        fetchedAt: DateTime.now().toUtc().subtract(const Duration(hours: 25)),
        cacheKey: 'test_key',
      );

      expect(entry.isStale, true);
    });

    test('isStale returns false for cache exactly 24 hours old', () {
      final entry = WeatherCacheEntry(
        h3Index: '881f92f4c3fffff',
        date: DateTime.now().toUtc(),
        jsonData: '{}',
        fetchedAt: DateTime.now().toUtc().subtract(const Duration(hours: 24)),
        cacheKey: 'test_key',
      );

      // At exactly 24 hours, it should NOT be stale (>24 is stale)
      expect(entry.isStale, false);
    });

    test('persists complex JSON data', () async {
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

      await box.put('complex', entry);
      final retrieved = box.get('complex');

      expect(retrieved!.jsonData, complexJson);
    });

    test('toString provides useful debug info', () {
      final entry = WeatherCacheEntry(
        h3Index: 'h3_test',
        date: DateTime.utc(2025, 12, 31),
        jsonData: '{}',
        fetchedAt: DateTime.now().toUtc(),
        cacheKey: 'weather_h3_test_2025-12-31',
      );

      final str = entry.toString();

      expect(str, contains('weather_h3_test_2025-12-31'));
      expect(str, contains('stale:'));
    });
  });
}
