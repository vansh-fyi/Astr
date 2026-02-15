import 'package:hive_ce/hive.dart';

part 'weather_cache_entry.g.dart';

/// Cache entry for storing weather data with H3-based lookup key.
///
/// Per Architecture: Transient Cache using Hive CE for weather forecasts.
/// Key format: `weather_{h3Index}_{YYYY-MM-DD}`
@HiveType(typeId: 4)
class WeatherCacheEntry {
  WeatherCacheEntry({
    required this.h3Index,
    required this.date,
    required this.jsonData,
    required this.fetchedAt,
    required this.cacheKey,
  });

  /// H3 index (resolution 8) for this cached location
  @HiveField(0)
  final String h3Index;

  /// Normalized date (midnight UTC) for this forecast
  @HiveField(1)
  final DateTime date;

  /// Serialized weather JSON from API response
  @HiveField(2)
  final String jsonData;

  /// Timestamp when this entry was cached
  @HiveField(3)
  final DateTime fetchedAt;

  /// Cache key for debugging: `weather_{h3Index}_{YYYY-MM-DD}`
  @HiveField(4)
  final String cacheKey;

  /// Check if cache is stale (>24 hours old).
  /// Per FR-09: Retain expired data until replacement succeeds.
  bool get isStale => DateTime.now().toUtc().difference(fetchedAt).inHours > 24;

  @override
  String toString() =>
      'WeatherCacheEntry(key: $cacheKey, stale: $isStale, fetchedAt: $fetchedAt)';
}
