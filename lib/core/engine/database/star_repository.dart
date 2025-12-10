import 'package:astr/core/engine/database/database_service.dart';
import 'package:astr/core/engine/models/result.dart';
import 'package:astr/core/engine/models/star.dart';
import 'package:astr/core/error/failure.dart';

/// Repository for accessing Star data from the local database
///
/// Provides methods to search and retrieve stars from the SQLite database.
/// All methods return Result<T> for consistent error handling.
class StarRepository {
  final DatabaseService _databaseService;

  const StarRepository(this._databaseService);

  /// Searches for stars by name (case-insensitive, supports partial matches)
  ///
  /// AC #2: Searching for "Sirius" returns correct Star objects
  /// AC #3: Query performance < 100ms
  Future<Result<List<Star>>> searchByName(String query, {int limit = 20}) async {
    if (query.isEmpty) {
      return Result.success([]);
    }

    final result = await _databaseService.query(
      'stars',
      where: 'LOWER(name) LIKE LOWER(?)',
      whereArgs: ['%$query%'],
      orderBy: 'mag ASC', // Brightest first
      limit: limit,
    );

    return result.fold(
      (rows) {
        try {
          final stars = rows.map((row) => Star.fromMap(row)).toList();
          return Result.success(stars);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse star data: $e'),
          );
        }
      },
      (failure) => Result.failure(failure),
    );
  }

  /// Searches for stars by constellation
  Future<Result<List<Star>>> searchByConstellation(
    String constellation, {
    int limit = 50,
  }) async {
    if (constellation.isEmpty) {
      return Result.success([]);
    }

    final result = await _databaseService.query(
      'stars',
      where: 'LOWER(constellation) = LOWER(?)',
      whereArgs: [constellation],
      orderBy: 'mag ASC',
      limit: limit,
    );

    return result.fold(
      (rows) {
        try {
          final stars = rows.map((row) => Star.fromMap(row)).toList();
          return Result.success(stars);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse star data: $e'),
          );
        }
      },
      (failure) => Result.failure(failure),
    );
  }

  /// Gets a star by its Hipparcos ID
  Future<Result<Star?>> getByHipId(int hipId) async {
    final result = await _databaseService.query(
      'stars',
      where: 'hip_id = ?',
      whereArgs: [hipId],
      limit: 1,
    );

    return result.fold(
      (rows) {
        if (rows.isEmpty) {
          return Result.success(null);
        }

        try {
          final star = Star.fromMap(rows.first);
          return Result.success(star);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse star data: $e'),
          );
        }
      },
      (failure) => Result.failure(failure),
    );
  }

  /// Gets brightest stars up to a magnitude limit
  Future<Result<List<Star>>> getBrightestStars({
    double maxMagnitude = 3.0,
    int limit = 100,
  }) async {
    final result = await _databaseService.query(
      'stars',
      where: 'mag IS NOT NULL AND mag <= ?',
      whereArgs: [maxMagnitude],
      orderBy: 'mag ASC',
      limit: limit,
    );

    return result.fold(
      (rows) {
        try {
          final stars = rows.map((row) => Star.fromMap(row)).toList();
          return Result.success(stars);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse star data: $e'),
          );
        }
      },
      (failure) => Result.failure(failure),
    );
  }

  /// Gets all stars (use with caution, may return large dataset)
  Future<Result<List<Star>>> getAll({int limit = 1000}) async {
    final result = await _databaseService.query(
      'stars',
      orderBy: 'mag ASC',
      limit: limit,
    );

    return result.fold(
      (rows) {
        try {
          final stars = rows.map((row) => Star.fromMap(row)).toList();
          return Result.success(stars);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse star data: $e'),
          );
        }
      },
      (failure) => Result.failure(failure),
    );
  }
}
