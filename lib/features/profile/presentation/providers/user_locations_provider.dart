import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';
import '../../../context/domain/entities/geo_location.dart';
import '../../../context/presentation/providers/astr_context_provider.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../domain/entities/user_location.dart';

part 'user_locations_provider.g.dart';

/// Riverpod AsyncNotifier for managing user locations.
///
/// This provider:
/// - Loads and caches the list of UserLocation entities
/// - Provides CRUD methods: addLocation, updateLocation, deleteLocation
/// - Auto-resolves H3 index when saving new locations
/// - Auto-selects newly added locations in AstrContext
///
/// Replaces the old `SavedLocationsNotifier` (Hive-based) with
/// Sqflite-backed storage.
@riverpod
class UserLocationsNotifier extends _$UserLocationsNotifier {
  @override
  Future<List<UserLocation>> build() async {
    return _loadLocations();
  }

  Future<List<UserLocation>> _loadLocations() async {
    final repository = ref.read(locationRepositoryProvider);
    final result = await repository.getAllLocations();
    return result.fold(
      (failure) => <UserLocation>[],
      (locations) => locations,
    );
  }

  /// Adds a new location with auto-computed H3 index.
  ///
  /// Creates a new UserLocation with:
  /// - Generated UUID for id
  /// - H3 index auto-resolved by repository layer (Story 2.1)
  /// - Current timestamp for createdAt and lastViewedTimestamp
  /// - isPinned defaults to false
  ///
  /// After saving, auto-selects the location in AstrContext.
  ///
  /// Throws [Failure] if save fails.
  Future<void> addLocation({
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    final now = DateTime.now();
    final location = UserLocation(
      id: const Uuid().v4(),
      name: name,
      latitude: latitude,
      longitude: longitude,
      h3Index: '', // Repository computes H3 index from coordinates (Story 2.1)
      lastViewedTimestamp: now,
      isPinned: false,
      createdAt: now,
    );

    final repository = ref.read(locationRepositoryProvider);
    final result = await repository.saveLocation(location);

    await result.fold(
      (failure) => throw failure,
      (_) async {
        ref.invalidateSelf();

        // Auto-select newly added location in AstrContext
        ref.read(astrContextProvider.notifier).updateLocation(
              GeoLocation(
                latitude: location.latitude,
                longitude: location.longitude,
                name: location.name,
              ),
            );
      },
    );
  }

  /// Updates an existing location.
  ///
  /// If coordinates change, H3 index is re-computed automatically by repository.
  ///
  /// Throws [Failure] if update fails.
  Future<void> updateLocation(UserLocation location) async {
    final repository = ref.read(locationRepositoryProvider);
    final result = await repository.saveLocation(location);

    await result.fold(
      (failure) => throw failure,
      (_) async => ref.invalidateSelf(),
    );
  }

  /// Deletes a location by ID.
  ///
  /// Throws [Failure] if delete fails.
  Future<void> deleteLocation(String id) async {
    final repository = ref.read(locationRepositoryProvider);
    final result = await repository.deleteLocation(id);

    await result.fold(
      (failure) => throw failure,
      (_) async => ref.invalidateSelf(),
    );
  }

  // ============================================================
  // STALENESS METHODS (Story 2.3)
  // ============================================================

  /// Updates the lastViewedTimestamp for a location.
  ///
  /// Called when user views a location's dashboard (via AstrContext selection).
  /// This resets the staleness clock, making the location "active" again.
  ///
  /// Throws [Failure] if update fails.
  Future<void> updateLastViewed(String id) async {
    final repository = ref.read(locationRepositoryProvider);
    final result = await repository.updateLastViewed(id);

    await result.fold(
      (failure) => throw failure,
      (_) async => ref.invalidateSelf(),
    );
  }

  /// Toggles the isPinned status for a location.
  ///
  /// Returns the new pinned state.
  /// Pinned locations never become stale and always receive background updates.
  ///
  /// Throws [Failure] if update fails.
  Future<bool> togglePinned(String id) async {
    final repository = ref.read(locationRepositoryProvider);
    final result = await repository.togglePinned(id);

    return await result.fold(
      (failure) => throw failure,
      (newPinnedState) async {
        ref.invalidateSelf();
        return newPinnedState;
      },
    );
  }

  /// Checks if a location is stale.
  ///
  /// A location is stale if:
  /// - NOT pinned (isPinned == false)
  /// - AND lastViewedTimestamp > [staleDays] days ago
  ///
  /// Default threshold is 11 days per AC #2.
  static bool isStale(UserLocation location, {int staleDays = kStalenessDaysThreshold}) {
    if (location.isPinned) return false;

    final now = DateTime.now();
    final threshold = now.subtract(Duration(days: staleDays));
    return location.lastViewedTimestamp.isBefore(threshold);
  }

  /// Finds a UserLocation by matching coordinates.
  ///
  /// Returns null if no location matches. Used by AstrContext to
  /// find the location ID for updateLastViewed().
  ///
  /// Uses exact coordinate matching to avoid false positives.
  Future<UserLocation?> findByCoordinates(double latitude, double longitude) async {
    final repository = ref.read(locationRepositoryProvider);
    final result = await repository.getAllLocations();

    return result.fold(
      (_) => null,
      (locations) {
        try {
          return locations.firstWhere(
            (loc) => loc.latitude == latitude && loc.longitude == longitude,
          );
        } catch (_) {
          return null;
        }
      },
    );
  }
}

/// Staleness threshold in days.
///
/// Per AC #2, locations are considered stale after 11 days
/// of inactivity (no views) unless they are pinned.
const int kStalenessDaysThreshold = 11;

/// Provider for pinned locations only.
///
/// Used by background sync (Story 3.4) to get priority locations.
@riverpod
Future<List<UserLocation>> pinnedLocations(PinnedLocationsRef ref) async {
  final repository = ref.watch(locationRepositoryProvider);
  final result = await repository.getPinnedLocations();
  return result.fold(
    (failure) => <UserLocation>[],
    (locations) => locations,
  );
}

/// Provider for stale locations only.
///
/// Returns locations that are NOT pinned AND last viewed > 10 days ago.
/// Used by background sync (Story 3.4) to exclude these from updates.
@riverpod
Future<List<UserLocation>> staleLocations(StaleLocationsRef ref) async {
  final repository = ref.watch(locationRepositoryProvider);
  final result = await repository.getStaleLocations(staleDays: kStalenessDaysThreshold);
  return result.fold(
    (failure) => <UserLocation>[],
    (locations) => locations,
  );
}
