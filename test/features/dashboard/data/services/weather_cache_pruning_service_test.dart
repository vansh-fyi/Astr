import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:astr/features/dashboard/data/models/weather_cache_entry.dart';
import 'package:astr/features/dashboard/data/services/weather_cache_pruning_service.dart';

void main() {
  late Box<WeatherCacheEntry> cacheBox;
  late WeatherCachePruningService sut;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('pruning_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapter(WeatherCacheEntryAdapter());
  });

  setUp(() async {
    cacheBox = await Hive.openBox<WeatherCacheEntry>('prune_test_${DateTime.now().millisecondsSinceEpoch}');
    sut = WeatherCachePruningService(cacheBox: cacheBox);
  });

  tearDown(() async {
    await cacheBox.clear();
    await cacheBox.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('WeatherCachePruningService', () {
    test('pruneOldEntries deletes entries older than today entirely', () async {
      final now = DateTime.now();
      
      // Create entry from 2 days ago (always before today 9 AM)
      final twoDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 2));
      await cacheBox.put(
        'old_entry',
        WeatherCacheEntry(
          h3Index: 'test_h3',
          date: twoDaysAgo,
          jsonData: '{}',
          fetchedAt: twoDaysAgo,
          cacheKey: 'old_entry',
        ),
      );

      // Create entry from tomorrow (always after today 9 AM)
      final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      await cacheBox.put(
        'new_entry',
        WeatherCacheEntry(
          h3Index: 'test_h3',
          date: tomorrow,
          jsonData: '{}',
          fetchedAt: tomorrow,
          cacheKey: 'new_entry',
        ),
      );

      expect(cacheBox.length, 2);

      final deleted = await sut.pruneOldEntries();

      // Old entry (2 days ago) should always be deleted
      expect(deleted, 1);
      expect(cacheBox.length, 1);
      expect(cacheBox.containsKey('new_entry'), true);
      expect(cacheBox.containsKey('old_entry'), false);
    });

    test('pruneOldEntries keeps entries from tomorrow', () async {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

      await cacheBox.put(
        'tomorrow_entry',
        WeatherCacheEntry(
          h3Index: 'test_h3',
          date: tomorrow,
          jsonData: '{}',
          fetchedAt: tomorrow,
          cacheKey: 'tomorrow_entry',
        ),
      );

      final deleted = await sut.pruneOldEntries();

      expect(deleted, 0);
      expect(cacheBox.length, 1);
    });

    test('pruneOldEntries returns 0 for empty cache', () async {
      final deleted = await sut.pruneOldEntries();
      expect(deleted, 0);
    });

    test('pruneOldEntries batch deletes multiple old entries', () async {
      final now = DateTime.now();
      final oldDate = now.subtract(const Duration(days: 7));

      // Create 5 old entries
      for (int i = 0; i < 5; i++) {
        await cacheBox.put(
          'old_entry_$i',
          WeatherCacheEntry(
            h3Index: 'test_h3',
            date: oldDate,
            jsonData: '{}',
            fetchedAt: oldDate,
            cacheKey: 'old_entry_$i',
          ),
        );
      }

      expect(cacheBox.length, 5);

      final deleted = await sut.pruneOldEntries();

      expect(deleted, 5);
      expect(cacheBox.length, 0);
    });

    test('cacheSize returns correct count', () async {
      await cacheBox.put('entry1', WeatherCacheEntry(
        h3Index: 'h3',
        date: DateTime.now(),
        jsonData: '{}',
        fetchedAt: DateTime.now(),
        cacheKey: 'entry1',
      ));
      await cacheBox.put('entry2', WeatherCacheEntry(
        h3Index: 'h3',
        date: DateTime.now(),
        jsonData: '{}',
        fetchedAt: DateTime.now(),
        cacheKey: 'entry2',
      ));

      expect(sut.cacheSize, 2);
    });

    test('approximateStorageBytes returns positive value', () async {
      await cacheBox.put('entry', WeatherCacheEntry(
        h3Index: 'test_h3_index',
        date: DateTime.now(),
        jsonData: '{"cloudCover":25.0,"temperatureC":18.5}',
        fetchedAt: DateTime.now(),
        cacheKey: 'weather_test_h3_index_daily_2025-01-01',
      ));

      expect(sut.approximateStorageBytes, greaterThan(0));
    });
  });

}
