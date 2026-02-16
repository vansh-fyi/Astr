import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data_layer/providers/cached_zone_repository_provider.dart';
import '../../../data_layer/services/h3_service.dart';
import '../providers/weather_provider.dart';
import '../../data/services/location_prefetch_service.dart';

/// Riverpod provider for [LocationPrefetchService].
///
/// Wires the service with existing repository and service providers.
/// Usage:
/// ```dart
/// final prefetchService = ref.read(locationPrefetchServiceProvider);
/// await prefetchService.prefetchForLocation(geoLocation);
/// ```
final Provider<LocationPrefetchService> locationPrefetchServiceProvider =
    Provider<LocationPrefetchService>((Ref ref) {
  return LocationPrefetchService(
    weatherRepository: ref.watch(weatherRepositoryProvider),
    zoneRepository: ref.watch(cachedZoneRepositoryProvider),
    h3Service: ref.watch(h3ServiceProvider),
  );
});
