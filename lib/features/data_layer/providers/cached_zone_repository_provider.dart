import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../models/zone_cache_entry.dart';
import '../repositories/cached_zone_repository.dart';
import '../services/remote_zone_service.dart';
import '../../profile/presentation/providers/offline_data_provider.dart';

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
/// This is a synchronous provider since all dependencies are ready
/// after Hive initialization in main.dart.
///
/// Usage:
/// ```dart
/// final zoneRepo = ref.watch(cachedZoneRepositoryProvider);
/// final zoneData = await zoneRepo.getZoneData(h3Index);
/// if (zoneData != null) {
///   print('Bortle: ${zoneData.bortleClass}');
/// } else {
///   // Fall back to PNG map
/// }
/// ```
final Provider<CachedZoneRepository> cachedZoneRepositoryProvider =
    Provider<CachedZoneRepository>((Ref ref) {
  final RemoteZoneService remoteService = ref.watch(remoteZoneServiceProvider);
  final Box<ZoneCacheEntry> cacheBox = ref.watch(zoneCacheBoxProvider);

  // Reactively watch offline data state — rebuilds when download completes/deletes
  final OfflineDataState offlineState = ref.watch(offlineDataProvider);
  final String? localDbPath =
      offlineState.status == OfflineDataStatus.downloaded
          ? offlineState.localDbPath
          : null;

  return CachedZoneRepository(
    remoteService: remoteService,
    cacheBox: cacheBox,
    localDbPath: localDbPath,
  );
});
