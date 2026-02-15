import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/user_location.dart';

/// Abstract interface for location repository operations.
///
/// Defines the contract for CRUD and query operations on user locations.
/// Following the Repository pattern, this separates domain logic from
/// data access implementation details.
///
/// All methods return [Either<Failure, T>] to handle errors functionally.
abstract class ILocationRepository {
  /// Retrieves all saved locations.
  ///
  /// Returns locations ordered by [lastViewedTimestamp] descending (most recent first).
  Future<Either<Failure, List<UserLocation>>> getAllLocations();

  /// Retrieves a single location by its ID.
  ///
  /// Returns [Left(CacheFailure)] if location is not found.
  Future<Either<Failure, UserLocation>> getLocationById(String id);

  /// Saves a new location or updates an existing one.
  ///
  /// If a location with the same ID exists, it will be replaced.
  Future<Either<Failure, void>> saveLocation(UserLocation location);

  /// Deletes a location by its ID.
  ///
  /// Returns [Right(void)] even if the location doesn't exist (idempotent).
  Future<Either<Failure, void>> deleteLocation(String id);

  /// Retrieves all pinned locations.
  ///
  /// Pinned locations are protected from staleness cleanup and
  /// always included in background weather updates.
  Future<Either<Failure, List<UserLocation>>> getPinnedLocations();

  /// Retrieves locations that are considered "stale".
  ///
  /// A location is stale if:
  /// - It is NOT pinned (`isPinned == false`)
  /// - AND [lastViewedTimestamp] is older than [staleDays] days ago
  ///
  /// Default [staleDays] is 10 days per Story 2.3 requirements.
  Future<Either<Failure, List<UserLocation>>> getStaleLocations({
    int staleDays = 10,
  });

  /// Updates the [lastViewedTimestamp] for a location.
  ///
  /// Called when user views a location's dashboard to mark it as recently used.
  Future<Either<Failure, void>> updateLastViewed(String id);

  /// Toggles the [isPinned] status for a location.
  ///
  /// Returns the updated pinned state.
  Future<Either<Failure, bool>> togglePinned(String id);
}
