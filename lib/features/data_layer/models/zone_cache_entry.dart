import 'package:hive_ce/hive.dart';

part 'zone_cache_entry.g.dart';

/// Cache entry for storing light pollution zone data fetched from remote.
///
/// Per Architecture: Zone data is fetched from Cloudflare R2/Worker API
/// and cached locally in Hive for offline access and performance.
///
/// Key format: `zone_{h3Index}` (H3 resolution 8 hex string)
@HiveType(typeId: 5)
class ZoneCacheEntry {
  ZoneCacheEntry({
    required this.h3Index,
    required this.bortleClass,
    required this.ratio,
    required this.sqm,
    required this.fetchedAt,
  });

  /// H3 index (resolution 8) as hex string
  @HiveField(0)
  final String h3Index;

  /// Bortle Dark-Sky Scale value (1-9)
  @HiveField(1)
  final int bortleClass;

  /// Light pollution ratio (relative to natural sky, 0-10 scale)
  @HiveField(2)
  final double ratio;

  /// Sky Quality Meter value in mag/arcsec²
  @HiveField(3)
  final double sqm;

  /// Timestamp when this entry was cached
  @HiveField(4)
  final DateTime fetchedAt;

  /// Zone data is static (satellite imagery from specific date).
  /// Unlike weather, we don't consider zone cache "stale" - it's valid until
  /// we regenerate zones.db with newer satellite data.
  /// 
  /// However, we may want to refresh after major app updates.
  bool get isExpired {
    // Expire after 1 year to allow for data updates
    return DateTime.now().toUtc().difference(fetchedAt).inDays > 365;
  }

  @override
  String toString() =>
      'ZoneCacheEntry(h3: $h3Index, bortle: $bortleClass, fetchedAt: $fetchedAt)';
}
