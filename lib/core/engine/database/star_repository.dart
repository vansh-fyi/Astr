import '../../error/failure.dart';
import '../models/result.dart';
import '../models/star.dart';
import 'database_service.dart';

/// Repository for accessing Star data from the local database
///
/// Provides methods to search and retrieve stars from the SQLite database.
/// All methods return Result<T> for consistent error handling.
class StarRepository {

  const StarRepository(this._databaseService);
  final DatabaseService _databaseService;

  /// Searches for stars by name (case-insensitive, supports partial matches)
  ///
  /// AC #2: Searching for "Sirius" returns correct Star objects
  /// AC #3: Query performance < 100ms
  Future<Result<List<Star>>> searchByName(String query, {int limit = 20}) async {
    if (query.isEmpty) {
      return Result.success(<Star>[]);
    }

    final Result<List<Map<String, dynamic>>> result = await _databaseService.query(
      'stars',
      where: 'LOWER(name) LIKE LOWER(?)',
      whereArgs: <Object?>['%$query%'],
      orderBy: 'mag ASC', // Brightest first
      limit: limit,
    );

    return result.fold(
      (List<Map<String, dynamic>> rows) {
        try {
          final List<Star> stars = rows.map(Star.fromMap).toList();
          return Result.success(stars);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse star data: $e'),
          );
        }
      },
      Result.failure,
    );
  }

  /// Searches for stars by constellation
  Future<Result<List<Star>>> searchByConstellation(
    String constellation, {
    int limit = 50,
  }) async {
    if (constellation.isEmpty) {
      return Result.success(<Star>[]);
    }

    final Result<List<Map<String, dynamic>>> result = await _databaseService.query(
      'stars',
      where: 'LOWER(constellation) = LOWER(?)',
      whereArgs: <Object?>[constellation],
      orderBy: 'mag ASC',
      limit: limit,
    );

    return result.fold(
      (List<Map<String, dynamic>> rows) {
        try {
          final List<Star> stars = rows.map(Star.fromMap).toList();
          return Result.success(stars);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse star data: $e'),
          );
        }
      },
      Result.failure,
    );
  }

  /// Gets a star by its Hipparcos ID
  Future<Result<Star?>> getByHipId(int hipId) async {
    final Result<List<Map<String, dynamic>>> result = await _databaseService.query(
      'stars',
      where: 'hip_id = ?',
      whereArgs: <Object?>[hipId],
      limit: 1,
    );

    return result.fold(
      (List<Map<String, dynamic>> rows) {
        if (rows.isEmpty) {
          return Result.success(null);
        }

        try {
          final Star star = Star.fromMap(rows.first);
          return Result.success(star);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse star data: $e'),
          );
        }
      },
      Result.failure,
    );
  }

  /// Gets brightest stars up to a magnitude limit
  Future<Result<List<Star>>> getBrightestStars({
    double maxMagnitude = 3.0,
    int limit = 100,
  }) async {
    final Result<List<Map<String, dynamic>>> result = await _databaseService.query(
      'stars',
      where: 'mag IS NOT NULL AND mag <= ?',
      whereArgs: <Object?>[maxMagnitude],
      orderBy: 'mag ASC',
      limit: limit,
    );

    return result.fold(
      (List<Map<String, dynamic>> rows) {
        try {
          final List<Star> stars = rows.map(Star.fromMap).toList();
          return Result.success(stars);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse star data: $e'),
          );
        }
      },
      Result.failure,
    );
  }

  /// Gets all stars (use with caution, may return large dataset)
  Future<Result<List<Star>>> getAll({int limit = 1000}) async {
    final Result<List<Map<String, dynamic>>> result = await _databaseService.query(
      'stars',
      orderBy: 'mag ASC',
      limit: limit,
    );

    return result.fold(
      (List<Map<String, dynamic>> rows) {
        try {
          final List<Star> stars = rows.map(Star.fromMap).toList();
          return Result.success(stars);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse star data: $e'),
          );
        }
      },
      Result.failure,
    );
  }
}
