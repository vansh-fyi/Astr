import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../data_layer/services/h3_service.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/repositories/i_location_repository.dart';
import '../datasources/location_database_service.dart';
import '../datasources/location_database_service_provider.dart';

part 'location_repository_impl.g.dart';

/// Riverpod provider for LocationRepository.
///
/// Provides a singleton instance of [LocationRepositoryImpl] with proper
/// dependency injection of [LocationDatabaseService] and [H3Service].
@riverpod
LocationRepositoryImpl locationRepository(LocationRepositoryRef ref) {
  final databaseService = ref.watch(locationDatabaseServiceProvider);
  final h3Service = ref.watch(h3ServiceProvider);
  return LocationRepositoryImpl(databaseService, h3Service);
}

/// Implementation of [ILocationRepository] using SQLite via [LocationDatabaseService].
///
/// Handles data translation between domain [UserLocation] entities and
/// SQLite database maps. All public methods return [Either<Failure, T>]
/// for functional error handling.
///
/// **H3 Auto-Resolution:** When saving locations, automatically computes
/// the H3 index (Resolution 8) from coordinates using [H3Service].
class LocationRepositoryImpl implements ILocationRepository {
  /// Creates a repository with the given database service and H3 service.
  LocationRepositoryImpl(this._databaseService, this._h3Service);

  final LocationDatabaseService _databaseService;
  final H3Service _h3Service;

  @override
  Future<Either<Failure, List<UserLocation>>> getAllLocations() async {
    final result = await _databaseService.query(
      orderBy: '${LocationColumns.lastViewedTimestamp} DESC',
    );

    return result.fold(
      (rows) {
        try {
          final locations = rows.map(UserLocation.fromMap).toList();
          return Right(locations);
        } catch (e) {
          return Left(CacheFailure('Failed to parse locations: $e'));
        }
      },
      (failure) => Left(CacheFailure(failure.message)),
    );
  }

  @override
  Future<Either<Failure, UserLocation>> getLocationById(String id) async {
    final result = await _databaseService.query(
      where: '${LocationColumns.id} = ?',
      whereArgs: [id],
      limit: 1,
    );

    return result.fold(
      (rows) {
        if (rows.isEmpty) {
          return Left(CacheFailure('Location not found: $id'));
        }
        try {
          return Right(UserLocation.fromMap(rows.first));
        } catch (e) {
          return Left(CacheFailure('Failed to parse location: $e'));
        }
      },
      (failure) => Left(CacheFailure(failure.message)),
    );
  }

  @override
  Future<Either<Failure, void>> saveLocation(UserLocation location) async {
    try {
      // Auto-compute H3 index from coordinates (Resolution 8)
      final h3Index = _h3Service.latLonToH3(
        location.latitude,
        location.longitude,
        8, // Resolution 8 per architecture requirements
      );

      // Convert BigInt to hex string for storage
      final h3IndexString = h3Index.toRadixString(16);

      // Update location with computed H3 index
      final locationWithH3 = location.copyWith(h3Index: h3IndexString);

      final result = await _databaseService.insert(locationWithH3.toMap());

      return result.fold(
        (_) => const Right(null),
        (failure) => Left(CacheFailure(failure.message)),
      );
    } on ArgumentError catch (e) {
      // H3Service throws ArgumentError for invalid coordinates
      return Left(CacheFailure('Invalid coordinates: ${e.message}'));
    } catch (e) {
      return Left(CacheFailure('Failed to save location: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLocation(String id) async {
    final result = await _databaseService.delete(
      where: '${LocationColumns.id} = ?',
      whereArgs: [id],
    );

    return result.fold(
      (_) => const Right(null),
      (failure) => Left(CacheFailure(failure.message)),
    );
  }

  @override
  Future<Either<Failure, List<UserLocation>>> getPinnedLocations() async {
    final result = await _databaseService.query(
      where: '${LocationColumns.isPinned} = ?',
      whereArgs: [1],
      orderBy: '${LocationColumns.name} ASC',
    );

    return result.fold(
      (rows) {
        try {
          final locations = rows.map(UserLocation.fromMap).toList();
          return Right(locations);
        } catch (e) {
          return Left(CacheFailure('Failed to parse pinned locations: $e'));
        }
      },
      (failure) => Left(CacheFailure(failure.message)),
    );
  }

  @override
  Future<Either<Failure, List<UserLocation>>> getStaleLocations({
    int staleDays = 10,
  }) async {
    // Calculate the threshold timestamp
    final now = DateTime.now();
    final threshold = now.subtract(Duration(days: staleDays));
    final thresholdMs = threshold.millisecondsSinceEpoch;

    final result = await _databaseService.query(
      where: '${LocationColumns.isPinned} = ? AND ${LocationColumns.lastViewedTimestamp} < ?',
      whereArgs: [0, thresholdMs],
      orderBy: '${LocationColumns.lastViewedTimestamp} ASC',
    );

    return result.fold(
      (rows) {
        try {
          final locations = rows.map(UserLocation.fromMap).toList();
          return Right(locations);
        } catch (e) {
          return Left(CacheFailure('Failed to parse stale locations: $e'));
        }
      },
      (failure) => Left(CacheFailure(failure.message)),
    );
  }

  @override
  Future<Either<Failure, void>> updateLastViewed(String id) async {
    final now = DateTime.now();

    final result = await _databaseService.update(
      {LocationColumns.lastViewedTimestamp: now.millisecondsSinceEpoch},
      where: '${LocationColumns.id} = ?',
      whereArgs: [id],
    );

    return result.fold(
      (count) {
        if (count == 0) {
          return Left(CacheFailure('Location not found: $id'));
        }
        return const Right(null);
      },
      (failure) => Left(CacheFailure(failure.message)),
    );
  }

  @override
  Future<Either<Failure, bool>> togglePinned(String id) async {
    // First, get the current state
    final locationResult = await getLocationById(id);

    return locationResult.fold(
      (failure) => Left(failure),
      (location) async {
        final newPinnedState = !location.isPinned;

        final result = await _databaseService.update(
          {LocationColumns.isPinned: newPinnedState ? 1 : 0},
          where: '${LocationColumns.id} = ?',
          whereArgs: [id],
        );

        return result.fold(
          (count) {
            if (count == 0) {
              return Left(CacheFailure('Failed to update location: $id'));
            }
            return Right(newPinnedState);
          },
          (failure) => Left(CacheFailure(failure.message)),
        );
      },
    );
  }
}
