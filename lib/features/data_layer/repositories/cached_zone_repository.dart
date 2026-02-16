import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../models/zone_cache_entry.dart';
import '../models/zone_data.dart';
import '../services/remote_zone_service.dart';

/// Cached repository for zone data with cache-first pattern.
///
/// Lookup strategy:
/// 1. Check Hive cache for existing data
/// 2. If cache miss, fetch from remote Cloudflare D1 API
/// 3. Cache successful responses
/// 4. Return pristine dark sky (Bortle 1) if not in database
///
/// **Key difference from weather cache:**
/// Zone data is static (based on satellite imagery date) so we don't
/// need staleness checks. Cache is valid until app update with new data.
///
/// **Dark Sky Logic:**
/// The VNL database only contains *lit areas* (radiance > 0).
/// Locations NOT in the database are dark sky sites - the best for stargazing!
/// These return Bortle 1 (pristine dark sky) as default.
class CachedZoneRepository {
  CachedZoneRepository({
    required RemoteZoneService remoteService,
    required Box<ZoneCacheEntry> cacheBox,
  })  : _remote = remoteService,
        _cache = cacheBox;

  final RemoteZoneService _remote;
  final Box<ZoneCacheEntry> _cache;

  /// Cache key prefix for zone entries
  static const String _keyPrefix = 'zone_';

  /// Default value for locations not in lit-areas database.
  /// These are pristine dark sky sites - the best for stargazing!
  static final ZoneData pristineDarkSky = ZoneData(
    bortleClass: 1,  // Bortle 1: Excellent dark-sky site
    ratio: 0.0,      // No artificial light
    sqm: 22.0,       // Maximum sky quality
  );

  /// Get zone data for an H3 index, using cache-first strategy.
  ///
  /// Returns:
  /// - [ZoneData] from cache or remote API
  /// - [pristineDarkSky] if not found in database (dark sky location!)
  Future<ZoneData> getZoneData(BigInt h3Index) async {
    final String h3Hex = h3Index.toRadixString(16);
    final String cacheKey = '$_keyPrefix$h3Hex';

    // 1. Check cache first
    final ZoneCacheEntry? cached = _cache.get(cacheKey);
    if (cached != null && !cached.isExpired) {
      debugPrint('Zone cache hit for $h3Hex');
      return ZoneData(
        bortleClass: cached.bortleClass,
        ratio: cached.ratio,
        sqm: cached.sqm,
      );
    }

    // 2. Cache miss — fetch from remote D1 API
    debugPrint('Zone cache miss for $h3Hex, fetching from remote...');
    final ZoneData? remoteData = await _remote.getZoneData(h3Index);

    if (remoteData != null) {
      _cacheZoneData(cacheKey, h3Hex, remoteData);
      return remoteData;
    }

    // 3. Remote failed - check if we have stale cache
    if (cached != null) {
      debugPrint('Remote failed, using expired cache for $h3Hex');
      return ZoneData(
        bortleClass: cached.bortleClass,
        ratio: cached.ratio,
        sqm: cached.sqm,
      );
    }

    // 4. Not in database = pristine dark sky location
    debugPrint('$h3Hex not in lit-areas DB, returning pristine dark sky');
    return pristineDarkSky;
  }

  /// Synchronous cache-only lookup (for performance-critical paths).
  /// Returns [pristineDarkSky] if not in cache.
  ZoneData getZoneDataSync(BigInt h3Index) {
    final String h3Hex = h3Index.toRadixString(16);
    final String cacheKey = '$_keyPrefix$h3Hex';

    final ZoneCacheEntry? cached = _cache.get(cacheKey);
    if (cached != null) {
      return ZoneData(
        bortleClass: cached.bortleClass,
        ratio: cached.ratio,
        sqm: cached.sqm,
      );
    }
    return pristineDarkSky;
  }

  /// Pre-cache nearby zones (e.g., H3 ring around current location).
  ///
  /// Useful for smooth UX when panning the map.
  Future<void> prefetchZones(List<BigInt> h3Indices) async {
    // Filter out already cached
    final List<BigInt> toFetch = h3Indices.where((BigInt index) {
      final String cacheKey = '$_keyPrefix${index.toRadixString(16)}';
      final ZoneCacheEntry? cached = _cache.get(cacheKey);
      return cached == null || cached.isExpired;
    }).toList();

    if (toFetch.isEmpty) return;

    debugPrint('Prefetching ${toFetch.length} zone cells...');
    final Map<BigInt, ZoneData> results = await _remote.getZoneDataBatch(toFetch);

    for (final MapEntry<BigInt, ZoneData> entry in results.entries) {
      final String h3Hex = entry.key.toRadixString(16);
      final String cacheKey = '$_keyPrefix$h3Hex';
      _cacheZoneData(cacheKey, h3Hex, entry.value);
    }
  }

  /// Cache zone data entry
  void _cacheZoneData(String cacheKey, String h3Hex, ZoneData data) {
    try {
      _cache.put(
        cacheKey,
        ZoneCacheEntry(
          h3Index: h3Hex,
          bortleClass: data.bortleClass,
          ratio: data.ratio,
          sqm: data.sqm,
          fetchedAt: DateTime.now().toUtc(),
        ),
      );
    } catch (e) {
      debugPrint('Failed to cache zone data for $h3Hex: $e');
      // Silent fail - caching is best-effort
    }
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return <String, dynamic>{
      'totalEntries': _cache.length,
      'keys': _cache.keys.take(10).toList(),
    };
  }

  /// Clear all cached zone data
  Future<void> clearCache() async {
    await _cache.clear();
  }
}
