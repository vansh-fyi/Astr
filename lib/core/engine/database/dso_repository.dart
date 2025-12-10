import 'package:astr/core/engine/database/database_service.dart';
import 'package:astr/core/engine/models/result.dart';
import 'package:astr/core/engine/models/dso.dart';
import 'package:astr/core/error/failure.dart';

/// Repository for accessing Deep Sky Object (DSO) data from the local database
///
/// Provides methods to search and retrieve DSOs from the SQLite database.
/// All methods return Result<T> for consistent error handling.
class DsoRepository {
  final DatabaseService _databaseService;

  const DsoRepository(this._databaseService);

  /// Searches for DSOs by name (case-insensitive, supports partial matches)
  ///
  /// AC #2: Searching for "Andromeda" returns correct DSO objects
  /// AC #3: Query performance < 100ms
  Future<Result<List<DSO>>> searchByName(String query, {int limit = 20}) async {
    if (query.isEmpty) {
      return Result.success([]);
    }

    final result = await _databaseService.query(
      'dso',
      where: 'LOWER(name) LIKE LOWER(?) OR LOWER(messier_id) LIKE LOWER(?) OR LOWER(ngc_id) LIKE LOWER(?)',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'mag ASC', // Brightest first
      limit: limit,
    );

    return result.fold(
      (rows) {
        try {
          final dsos = rows.map((row) => DSO.fromMap(row)).toList();
          return Result.success(dsos);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse DSO data: $e'),
          );
        }
      },
      (failure) => Result.failure(failure),
    );
  }

  /// Searches for DSOs by type (Galaxy, Nebula, Cluster)
  Future<Result<List<DSO>>> searchByType(
    DSOType type, {
    int limit = 50,
  }) async {
    final result = await _databaseService.query(
      'dso',
      where: 'LOWER(type) = LOWER(?)',
      whereArgs: [type.displayName],
      orderBy: 'mag ASC',
      limit: limit,
    );

    return result.fold(
      (rows) {
        try {
          final dsos = rows.map((row) => DSO.fromMap(row)).toList();
          return Result.success(dsos);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse DSO data: $e'),
          );
        }
      },
      (failure) => Result.failure(failure),
    );
  }

  /// Gets a DSO by its Messier ID (e.g., "M31")
  Future<Result<DSO?>> getByMessierId(String messierId) async {
    final result = await _databaseService.query(
      'dso',
      where: 'messier_id = ?',
      whereArgs: [messierId],
      limit: 1,
    );

    return result.fold(
      (rows) {
        if (rows.isEmpty) {
          return Result.success(null);
        }

        try {
          final dso = DSO.fromMap(rows.first);
          return Result.success(dso);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse DSO data: $e'),
          );
        }
      },
      (failure) => Result.failure(failure),
    );
  }

  /// Gets a DSO by its NGC/IC ID (e.g., "NGC224")
  Future<Result<DSO?>> getByNgcId(String ngcId) async {
    final result = await _databaseService.query(
      'dso',
      where: 'ngc_id = ?',
      whereArgs: [ngcId],
      limit: 1,
    );

    return result.fold(
      (rows) {
        if (rows.isEmpty) {
          return Result.success(null);
        }

        try {
          final dso = DSO.fromMap(rows.first);
          return Result.success(dso);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse DSO data: $e'),
          );
        }
      },
      (failure) => Result.failure(failure),
    );
  }

  /// Searches for DSOs by constellation
  Future<Result<List<DSO>>> searchByConstellation(
    String constellation, {
    int limit = 50,
  }) async {
    if (constellation.isEmpty) {
      return Result.success([]);
    }

    final result = await _databaseService.query(
      'dso',
      where: 'LOWER(constellation) = LOWER(?)',
      whereArgs: [constellation],
      orderBy: 'mag ASC',
      limit: limit,
    );

    return result.fold(
      (rows) {
        try {
          final dsos = rows.map((row) => DSO.fromMap(row)).toList();
          return Result.success(dsos);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse DSO data: $e'),
          );
        }
      },
      (failure) => Result.failure(failure),
    );
  }

  /// Gets all DSOs (use with caution, may return large dataset)
  Future<Result<List<DSO>>> getAll({int limit = 500}) async {
    final result = await _databaseService.query(
      'dso',
      orderBy: 'mag ASC',
      limit: limit,
    );

    return result.fold(
      (rows) {
        try {
          final dsos = rows.map((row) => DSO.fromMap(row)).toList();
          return Result.success(dsos);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Failed to parse DSO data: $e'),
          );
        }
      },
      (failure) => Result.failure(failure),
    );
  }
}
