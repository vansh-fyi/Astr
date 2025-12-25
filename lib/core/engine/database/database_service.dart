import 'package:flutter/foundation.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../error/failure.dart';
import '../models/result.dart';
// Conditional imports for platform-specific code
import 'database_service_mobile.dart'
    if (dart.library.html) 'database_service_web.dart';

/// Service for managing the local SQLite database
///
/// This service handles initialization of the database from assets,
/// maintains the connection, and provides access to the database instance.
///
/// On web, this provides a stub implementation since SQLite is not supported.
class DatabaseService {

  /// Creates a DatabaseService instance
  ///
  /// [testDatabasePath] is optional and should only be used in tests to provide
  /// a direct path to a test database file, bypassing asset loading.
  DatabaseService({this.testDatabasePath});
  static const String _dbName = 'astr.db';
  static const String _assetPath = 'assets/db/$_dbName';

  dynamic _database;
  bool _isInitialized = false;

  /// Optional test database path (for testing only)
  final String? testDatabasePath;

  /// Gets the database instance (initializes if needed)
  Future<Result<dynamic>> getDatabase() async {
    if (kIsWeb) {
      return Result.failure(
        const DatabaseFailure('Database not supported on web platform'),
      );
    }

    if (_database != null && await _isDatabaseOpen(_database)) {
      return Result.success(_database);
    }

    final Result<void> initResult = await initialize();
    return initResult.fold(
      (_) => _database != null
          ? Result.success(_database)
          : Result.failure(const DatabaseFailure(
              'Database not initialized after initialization attempt')),
      Result.failure,
    );
  }

  /// Initializes the database by copying from assets if needed
  ///
  /// This method:
  /// 1. Checks if database already exists in app documents
  /// 2. If not, copies from assets
  /// 3. Opens the database connection
  ///
  /// AC #1: Database initialization from assets on first run
  Future<Result<void>> initialize() async {
    if (kIsWeb) {
      return Result.failure(
        const DatabaseFailure('Database not supported on web platform'),
      );
    }

    if (_isInitialized && _database != null && await _isDatabaseOpen(_database)) {
      return Result.success(null);
    }

    try {
      final Result<Database> result = await initializePlatformDatabase(
        testDatabasePath: testDatabasePath,
        dbName: _dbName,
        assetPath: _assetPath,
      );

      return result.fold(
        (Database db) {
          _database = db;
          _isInitialized = true;
          return Result.success(null);
        },
        Result.failure,
      );
    } catch (e) {
      return Result.failure(
        DatabaseFailure('Failed to initialize database: $e'),
      );
    }
  }

  /// Executes a raw SQL query
  ///
  /// This is a convenience method for repositories to execute queries.
  Future<Result<List<Map<String, dynamic>>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (kIsWeb) {
      return Result.failure(
        const DatabaseFailure('Database not supported on web platform'),
      );
    }

    final Result dbResult = await getDatabase();
    return dbResult.fold(
      (db) async {
        try {
          final List<Map<String, dynamic>> results = await queryPlatformDatabase(
            db,
            table,
            distinct: distinct,
            columns: columns,
            where: where,
            whereArgs: whereArgs,
            groupBy: groupBy,
            having: having,
            orderBy: orderBy,
            limit: limit,
            offset: offset,
          );
          return Result.success(results);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Query failed: $e'),
          );
        }
      },
      Result.failure,
    );
  }

  /// Executes a raw SQL query with custom SQL
  Future<Result<List<Map<String, dynamic>>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    if (kIsWeb) {
      return Result.failure(
        const DatabaseFailure('Database not supported on web platform'),
      );
    }

    final Result dbResult = await getDatabase();
    return dbResult.fold(
      (db) async {
        try {
          final List<Map<String, dynamic>> results = await rawQueryPlatformDatabase(db, sql, arguments);
          return Result.success(results);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Raw query failed: $e'),
          );
        }
      },
      Result.failure,
    );
  }

  /// Closes the database connection
  Future<void> close() async {
    if (kIsWeb) {
      return;
    }

    if (_database != null && await _isDatabaseOpen(_database)) {
      await closePlatformDatabase(_database);
      _database = null;
      _isInitialized = false;
    }
  }

  /// Checks if the database is initialized
  bool get isInitialized => !kIsWeb && _isInitialized && _database != null;

  Future<bool> _isDatabaseOpen(dynamic db) async {
    if (kIsWeb) return false;
    return isPlatformDatabaseOpen(db);
  }
}
