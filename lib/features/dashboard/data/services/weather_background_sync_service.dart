import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../context/domain/entities/geo_location.dart';
import '../../../profile/domain/entities/user_location.dart';
import '../../../profile/domain/repositories/i_location_repository.dart';
import '../../../profile/presentation/providers/user_locations_provider.dart';
import '../../domain/repositories/i_weather_repository.dart';

/// Service for background weather synchronization.
///
/// Implements background sync strategy per PRD FR-08:
/// - Syncs weather for all "active" locations (non-stale OR pinned)
/// - Uses existing CachedWeatherRepository (leverages Stories 3.1/3.2)
/// - Silent failure on all errors (NFR-04)
/// - Battery-conscious: 500ms delay between requests
///
/// Designed to be called from:
/// - Android WorkManager (Task 2)
/// - iOS BGTaskScheduler (Task 3)
/// - App foreground resume (Story 3.3)
class WeatherBackgroundSyncService {
  WeatherBackgroundSyncService({
    required IWeatherRepository weatherRepository,
    required ILocationRepository locationRepository,
  })  : _weather = weatherRepository,
        _locations = locationRepository;

  final IWeatherRepository _weather;
  final ILocationRepository _locations;

  /// Syncs weather for all active (non-stale) locations.
  ///
  /// Active locations are:
  /// - Pinned locations (always active, bypass staleness)
  /// - Non-stale locations (lastViewed < 11 days ago)
  ///
  /// Returns the number of locations successfully synced.
  /// Never throws - all errors are caught and logged (NFR-04).
  Future<int> syncActiveLocations() async {
    try {
      // Get all saved locations
      final Either<Failure, List<UserLocation>> result =
          await _locations.getAllLocations();

      return await result.fold(
        (Failure failure) {
          // Silent failure - log but don't crash
          debugPrint('Background sync: Failed to load locations: $failure');
          return 0;
        },
        (List<UserLocation> locations) async {
          if (locations.isEmpty) {
            debugPrint('Background sync: No locations to sync');
            return 0;
          }

          int syncedCount = 0;

          // Prioritize pinned locations first (most important)
          final List<UserLocation> sortedLocations = <UserLocation>[
            ...locations.where((UserLocation loc) => loc.isPinned),
            ...locations.where((UserLocation loc) => !loc.isPinned),
          ];

          for (final UserLocation location in sortedLocations) {
            // Skip stale locations (unless pinned)
            if (_shouldSkipLocation(location)) {
              debugPrint(
                  'Background sync: Skipping stale location ${location.name}');
              continue;
            }

            // Attempt to sync weather for this location
            final bool success = await _syncLocation(location);
            if (success) syncedCount++;

            // Battery-conscious: Small delay between requests
            await Future<void>.delayed(const Duration(milliseconds: 500));
          }

          debugPrint(
              'Background sync: Synced $syncedCount/${locations.length} locations');
          return syncedCount;
        },
      );
    } catch (e, st) {
      // NFR-04: Silent failure - log but don't crash
      debugPrint('Background sync: Unexpected error: $e');
      debugPrint('Stack trace: $st');
      return 0;
    }
  }

  /// Determines if a location should be skipped during sync.
  ///
  /// Skip if:
  /// - NOT pinned AND stale (> 11 days since last view)
  bool _shouldSkipLocation(UserLocation location) {
    // Pinned locations are NEVER skipped
    if (location.isPinned) return false;

    // Use the established staleness logic from Epic 2
    return UserLocationsNotifier.isStale(location);
  }

  /// Syncs weather for a single location.
  ///
  /// Returns true if successful, false otherwise.
  /// Never throws - catches all exceptions.
  Future<bool> _syncLocation(UserLocation location) async {
    try {
      final GeoLocation geoLocation = GeoLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        name: location.name,
      );

      // Use existing CachedWeatherRepository (Stories 3.1/3.2)
      // This handles caching, network fallback, etc.
      final Either<Failure, dynamic> result =
          await _weather.getDailyForecast(geoLocation);

      return result.fold(
        (Failure failure) {
          debugPrint(
              'Background sync: Failed to fetch weather for ${location.name}: $failure');
          return false; // Network failure - silent fail
        },
        (_) {
          debugPrint(
              'Background sync: Successfully synced ${location.name}');
          return true; // Success - weather cached by repository
        },
      );
    } catch (e) {
      // NFR-04: zones.db lock or Hive write failure - silent fail
      debugPrint('Background sync: Error syncing ${location.name}: $e');
      return false;
    }
  }

  /// Syncs weather for pinned locations only.
  ///
  /// Useful for iOS BGTaskScheduler with strict 30s limit.
  /// Pinned locations are highest priority.
  Future<int> syncPinnedLocationsOnly() async {
    try {
      final Either<Failure, List<UserLocation>> result =
          await _locations.getPinnedLocations();

      return await result.fold(
        (Failure failure) {
          debugPrint('Background sync: Failed to load pinned locations');
          return 0;
        },
        (List<UserLocation> pinnedLocations) async {
          int syncedCount = 0;
          for (final UserLocation location in pinnedLocations) {
            final bool success = await _syncLocation(location);
            if (success) syncedCount++;
            await Future<void>.delayed(const Duration(milliseconds: 500));
          }
          return syncedCount;
        },
      );
    } catch (e) {
      debugPrint('Background sync: Error in pinned sync: $e');
      return 0;
    }
  }
}
