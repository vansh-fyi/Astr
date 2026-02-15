import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'location_database_service.dart';

part 'location_database_service_provider.g.dart';

/// Riverpod provider for [LocationDatabaseService].
///
/// Provides a singleton instance of the database service for dependency
/// injection throughout the app. The service is lazily initialized on
/// first access.
@riverpod
LocationDatabaseService locationDatabaseService(
  LocationDatabaseServiceRef ref,
) {
  final service = LocationDatabaseService();

  // Ensure database is closed when provider is disposed
  ref.onDispose(() async {
    await service.close();
  });

  return service;
}
