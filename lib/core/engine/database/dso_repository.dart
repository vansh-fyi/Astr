import '../../error/failure.dart';
import '../models/dso.dart';
import '../models/result.dart';
import 'database_service.dart';

/// Repository for accessing Deep Sky Object (DSO) data from the local database
///
/// Provides methods to search and retrieve DSOs from the SQLite database.
/// All methods return Result<T> for consistent error handling.
class DsoRepository {

  const DsoRepository(this._databaseService);
  final DatabaseService _databaseService;

  /// Searches for DSOs by name (case-insensitive, supports partial matches)
  ///
  /// AC #2: Searching for "Andromeda" returns correct DSO objects
  /// AC #3: Query performance < 100ms
  Future<Result<List<DSO>>> searchByName(String query, {int limit = 20}) async {
    if (query.isEmpty) {
      return Result.success(<DSO>[]);
    }

    final Result<List<Map<String, dynamic>>> result = await _databaseService.query(
      'dso',
      where: 'LOWER(name) LIKE LOWER(?) OR LOWER(messier_id) LIKE LOWER(?) OR LOWER(ngc_id) LIKE LOWER(?)',
      whereArgs: <Object?>['%$query%', '%$query%', '%$query%'],
      orderBy: 'mag ASC', // Brightest first
      limit: limit,
    );

    return result.fold(
      (List<Map<String, dynamic>> rows) {
        try {
          final List<DSO> dsos = rows.map(DSO.fromMap).toList();
          return Result.success(dsos);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse DSO data: $e'),
          );
        }
      },
      Result.failure,
    );
  }

  /// Searches for DSOs by type (Galaxy, Nebula, Cluster)
  Future<Result<List<DSO>>> searchByType(
    DSOType type, {
    int limit = 50,
  }) async {
    final Result<List<Map<String, dynamic>>> result = await _databaseService.query(
      'dso',
      where: 'LOWER(type) = LOWER(?)',
      whereArgs: <Object?>[type.displayName],
      orderBy: 'mag ASC',
      limit: limit,
    );

    return result.fold(
      (List<Map<String, dynamic>> rows) {
        try {
          final List<DSO> dsos = rows.map(DSO.fromMap).toList();
          return Result.success(dsos);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse DSO data: $e'),
          );
        }
      },
      Result.failure,
    );
  }

  /// Gets a DSO by its Messier ID (e.g., "M31")
  Future<Result<DSO?>> getByMessierId(String messierId) async {
    final Result<List<Map<String, dynamic>>> result = await _databaseService.query(
      'dso',
      where: 'messier_id = ?',
      whereArgs: <Object?>[messierId],
      limit: 1,
    );

    return result.fold(
      (List<Map<String, dynamic>> rows) {
        if (rows.isEmpty) {
          return Result.success(null);
        }

        try {
          final DSO dso = DSO.fromMap(rows.first);
          return Result.success(dso);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse DSO data: $e'),
          );
        }
      },
      Result.failure,
    );
  }

  /// Gets a DSO by its NGC/IC ID (e.g., "NGC224")
  Future<Result<DSO?>> getByNgcId(String ngcId) async {
    final Result<List<Map<String, dynamic>>> result = await _databaseService.query(
      'dso',
      where: 'ngc_id = ?',
      whereArgs: <Object?>[ngcId],
      limit: 1,
    );

    return result.fold(
      (List<Map<String, dynamic>> rows) {
        if (rows.isEmpty) {
          return Result.success(null);
        }

        try {
          final DSO dso = DSO.fromMap(rows.first);
          return Result.success(dso);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse DSO data: $e'),
          );
        }
      },
      Result.failure,
    );
  }

  /// Searches for DSOs by constellation
  Future<Result<List<DSO>>> searchByConstellation(
    String constellation, {
    int limit = 50,
  }) async {
    if (constellation.isEmpty) {
      return Result.success(<DSO>[]);
    }

    final Result<List<Map<String, dynamic>>> result = await _databaseService.query(
      'dso',
      where: 'LOWER(constellation) = LOWER(?)',
      whereArgs: <Object?>[constellation],
      orderBy: 'mag ASC',
      limit: limit,
    );

    return result.fold(
      (List<Map<String, dynamic>> rows) {
        try {
          final List<DSO> dsos = rows.map(DSO.fromMap).toList();
          return Result.success(dsos);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse DSO data: $e'),
          );
        }
      },
      Result.failure,
    );
  }

  /// Gets all DSOs (use with caution, may return large dataset)
  Future<Result<List<DSO>>> getAll({int limit = 500}) async {
    final Result<List<Map<String, dynamic>>> result = await _databaseService.query(
      'dso',
      orderBy: 'mag ASC',
      limit: limit,
    );

    return result.fold(
      (List<Map<String, dynamic>> rows) {
        try {
          final List<DSO> dsos = rows.map(DSO.fromMap).toList();
          return Result.success(dsos);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse DSO data: $e'),
          );
        }
      },
      Result.failure,
    );
  }
}
