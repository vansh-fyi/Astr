import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../models/zone_cache_entry.dart';
import '../repositories/cached_zone_repository.dart';
import '../services/remote_zone_service.dart';

// Re-export for cleaner consumption
export '../repositories/cached_zone_repository.dart';

/// Provider for the base URL of the zone API.
/// Override this in tests or for different environments.
final Provider<String> zoneApiBaseUrlProvider = Provider<String>((Ref ref) {
  return 'https://astr-zones.astr-vansh-fyi.workers.dev';
});

/// Provider for [RemoteZoneService].
final Provider<RemoteZoneService> remoteZoneServiceProvider =
    Provider<RemoteZoneService>((Ref ref) {
  final String baseUrl = ref.watch(zoneApiBaseUrlProvider);
  return RemoteZoneService(baseUrl: baseUrl);
});

/// Provider for the zone cache Hive box.
final Provider<Box<ZoneCacheEntry>> zoneCacheBoxProvider =
    Provider<Box<ZoneCacheEntry>>((Ref ref) {
  return Hive.box<ZoneCacheEntry>('zoneCache');
});

/// Riverpod provider for [CachedZoneRepository].
///
/// Uses remote Cloudflare D1 API + Hive cache for zone data lookups.
final Provider<CachedZoneRepository> cachedZoneRepositoryProvider =
    Provider<CachedZoneRepository>((Ref ref) {
  final RemoteZoneService remoteService = ref.watch(remoteZoneServiceProvider);
  final Box<ZoneCacheEntry> cacheBox = ref.watch(zoneCacheBoxProvider);

  return CachedZoneRepository(
    remoteService: remoteService,
    cacheBox: cacheBox,
  );
});
