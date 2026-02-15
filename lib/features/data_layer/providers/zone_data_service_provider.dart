import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/binary_reader_service.dart';
import '../services/zone_data_service.dart';
import 'binary_reader_service_provider.dart';

// Re-export for cleaner consumption
export '../services/zone_data_service.dart';

/// Riverpod provider for [ZoneDataService].
///
/// This is an async provider that depends on [binaryReaderServiceProvider].
/// It automatically initializes once BinaryReaderService is ready.
///
/// Usage:
/// ```dart
/// final zoneDataAsync = ref.watch(zoneDataServiceProvider);
/// zoneDataAsync.when(
///   data: (service) async {
///     // Example H3 index for Resolution 8 (near equator, 0°N 0°E)
///     final h3Index = BigInt.from(617700169958293503);
///     final zoneData = await service.getZoneData(h3Index);
///     return zoneData.bortleClass;
///   },
///   loading: () => /* show loading */,
///   error: (e, st) => /* handle error */,
/// );
/// ```
final FutureProvider<ZoneDataService> zoneDataServiceProvider =
    FutureProvider<ZoneDataService>(
  (FutureProviderRef<ZoneDataService> ref) async {
    // Wait for BinaryReaderService to be initialized
    final binaryReader = await ref.watch(binaryReaderServiceProvider.future);
    return ZoneDataService(binaryReader: binaryReader);
  },
);
