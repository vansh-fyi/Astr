import 'package:hive_ce/hive.dart';
import 'package:flutter/foundation.dart';

import '../models/weather_cache_entry.dart';

/// Service for pruning old weather cache entries.
///
/// Implements "Lazy Pruning" strategy from PRD (FR-10):
/// - Deletes cache entries older than "Today 09:00 AM"
/// - Runs on app start and resume (non-blocking)
/// - Preserves API for Safe Retention (FR-09)
class WeatherCachePruningService {
  WeatherCachePruningService({
    required Box<WeatherCacheEntry> cacheBox,
  }) : _cache = cacheBox;

  final Box<WeatherCacheEntry> _cache;

  /// Prunes cache entries older than "Today 09:00 AM" (device local time).
  ///
  /// FR-10: System must prune weather data older than "Today 09:00 AM".
  ///
  /// Returns the number of entries deleted.
  Future<int> pruneOldEntries() async {
    if (_cache.isEmpty) return 0;

    final DateTime now = DateTime.now();
    final DateTime threshold = DateTime(
      now.year,
      now.month,
      now.day,
      9, // 09:00 AM
    );

    int deletedCount = 0;
    final List<dynamic> keysToDelete = <dynamic>[];

    // Collect keys to delete
    for (final dynamic key in _cache.keys) {
      final WeatherCacheEntry? entry = _cache.get(key);
      if (entry == null) continue;

      // Check if entry date is before threshold
      final DateTime entryDate = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );

      if (entryDate.isBefore(threshold)) {
        keysToDelete.add(key);
      }
    }

    // Delete in batch
    for (final dynamic key in keysToDelete) {
      try {
        await _cache.delete(key);
        deletedCount++;
      } catch (e, st) {
        debugPrint('Failed to delete cache entry $key: $e');
        debugPrint('Stack trace: $st');
        // Continue with other deletions
      }
    }

    if (deletedCount > 0) {
      debugPrint('WeatherCachePruningService: Pruned $deletedCount old entries');
    }

    return deletedCount;
  }

  /// Gets total number of cache entries.
  int get cacheSize => _cache.length;

  /// Gets approximate cache storage size in bytes.
  int get approximateStorageBytes {
    int totalBytes = 0;
    for (final WeatherCacheEntry entry in _cache.values) {
      // Approximate: key length + JSON data length + fixed overhead
      totalBytes += entry.cacheKey.length + entry.jsonData.length + 100;
    }
    return totalBytes;
  }

  /// Clears all cache entries (for debugging/testing only).
  @visibleForTesting
  Future<void> clearAll() async {
    await _cache.clear();
  }
}
