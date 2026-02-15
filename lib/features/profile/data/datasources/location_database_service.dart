import 'package:flutter/foundation.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/engine/models/result.dart';
// Conditional imports for platform-specific code
import 'location_database_service_mobile.dart'
    if (dart.library.html) 'location_database_service_web.dart';

/// Database name constant for user locations.
const String kLocationDbName = 'user_locations.db';

/// Current database version for migration handling.
const int kLocationDbVersion = 1;

/// Table name constant for locations.
const String kLocationsTable = 'locations';

/// Column name constants for the locations table.
class LocationColumns {
  LocationColumns._();

  static const String id = 'id';
  static const String name = 'name';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String h3Index = 'h3Index';
  static const String lastViewedTimestamp = 'lastViewedTimestamp';
  static const String isPinned = 'isPinned';
  static const String createdAt = 'createdAt';
}

/// SQL statements for database schema creation.
class LocationDatabaseSchema {
  LocationDatabaseSchema._();

  /// Create locations table with all required columns and indexes.
  static const String createLocationsTable = '''
    CREATE TABLE IF NOT EXISTS $kLocationsTable (
      ${LocationColumns.id} TEXT PRIMARY KEY,
      ${LocationColumns.name} TEXT NOT NULL,
      ${LocationColumns.latitude} REAL NOT NULL,
      ${LocationColumns.longitude} REAL NOT NULL,
      ${LocationColumns.h3Index} TEXT NOT NULL,
      ${LocationColumns.lastViewedTimestamp} INTEGER NOT NULL,
      ${LocationColumns.isPinned} INTEGER NOT NULL DEFAULT 0,
      ${LocationColumns.createdAt} INTEGER NOT NULL
    )
  ''';

  /// Index on h3Index for fast zone lookups.
  static const String createH3IndexIndex = '''
    CREATE INDEX IF NOT EXISTS idx_h3Index ON $kLocationsTable(${LocationColumns.h3Index})
  ''';

  /// Index on lastViewedTimestamp for staleness queries.
  static const String createTimestampIndex = '''
    CREATE INDEX IF NOT EXISTS idx_lastViewedTimestamp ON $kLocationsTable(${LocationColumns.lastViewedTimestamp})
  ''';

  /// Index on isPinned for filtering pinned locations.
  static const String createPinnedIndex = '''
    CREATE INDEX IF NOT EXISTS idx_isPinned ON $kLocationsTable(${LocationColumns.isPinned})
  ''';
}

/// Service for managing the user locations SQLite database.
///
/// This service handles:
/// - Database initialization and schema creation
/// - Database versioning and migrations
/// - CRUD operations on the locations table
///
/// Unlike `DatabaseService` which copies from assets, this creates a fresh
/// database for user-generated content (read-write operations).
///
/// On web, this provides a stub implementation since SQLite is not supported.
class LocationDatabaseService {
  /// Creates a LocationDatabaseService instance.
  ///
  /// [testDatabasePath] is optional and should only be used in tests to provide
  /// a direct path to a test database file.
  LocationDatabaseService({this.testDatabasePath});

  /// Optional test database path (for testing only).
  final String? testDatabasePath;

  dynamic _database;
  bool _isInitialized = false;

  /// Gets the database instance (initializes if needed).
  Future<Result<Database>> getDatabase() async {
    if (kIsWeb) {
      return Result.failure(
        const DatabaseFailure('Database not supported on web platform'),
      );
    }

    if (_database != null && await _isDatabaseOpen(_database)) {
      return Result.success(_database as Database);
    }

    final Result<void> initResult = await initialize();
    return initResult.fold(
      (_) => _database != null
          ? Result.success(_database as Database)
          : Result.failure(const DatabaseFailure(
              'Database not initialized after initialization attempt')),
      Result.failure,
    );
  }

  /// Initializes the database, creating schema if needed.
  ///
  /// This method:
  /// 1. Opens or creates the database file
  /// 2. Creates the locations table and indexes if they don't exist
  /// 3. Handles migrations for future schema changes
  Future<Result<void>> initialize() async {
    if (kIsWeb) {
      return Result.failure(
        const DatabaseFailure('Database not supported on web platform'),
      );
    }

    if (_isInitialized &&
        _database != null &&
        await _isDatabaseOpen(_database)) {
      return Result.success(null);
    }

    try {
      final Result<Database> result = await initializeLocationDatabase(
        testDatabasePath: testDatabasePath,
        dbName: kLocationDbName,
        version: kLocationDbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
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
        DatabaseFailure('Failed to initialize location database: $e'),
      );
    }
  }

  /// Called when database is created for the first time.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute(LocationDatabaseSchema.createLocationsTable);
    await db.execute(LocationDatabaseSchema.createH3IndexIndex);
    await db.execute(LocationDatabaseSchema.createTimestampIndex);
    await db.execute(LocationDatabaseSchema.createPinnedIndex);
  }

  /// Called when database version is upgraded.
  ///
  /// Migration strategy: Add new migrations in order of version.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Version 1 is the initial version, no migrations needed yet.
    // Future migrations would be structured like:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE locations ADD COLUMN newField TEXT');
    // }
  }

  /// Inserts a new location into the database.
  Future<Result<void>> insert(Map<String, dynamic> values) async {
    if (kIsWeb) {
      return Result.failure(
        const DatabaseFailure('Database not supported on web platform'),
      );
    }

    final Result<Database> dbResult = await getDatabase();
    return dbResult.fold(
      (db) async {
        try {
          await db.insert(
            kLocationsTable,
            values,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          return Result.success(null);
        } catch (e) {
          return Result.failure(DatabaseFailure('Insert failed: $e'));
        }
      },
      Result.failure,
    );
  }

  /// Updates an existing location in the database.
  Future<Result<int>> update(
    Map<String, dynamic> values, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    if (kIsWeb) {
      return Result.failure(
        const DatabaseFailure('Database not supported on web platform'),
      );
    }

    final Result<Database> dbResult = await getDatabase();
    return dbResult.fold(
      (db) async {
        try {
          final int count = await db.update(
            kLocationsTable,
            values,
            where: where,
            whereArgs: whereArgs,
          );
          return Result.success(count);
        } catch (e) {
          return Result.failure(DatabaseFailure('Update failed: $e'));
        }
      },
      Result.failure,
    );
  }

  /// Deletes locations matching the where clause.
  Future<Result<int>> delete({
    required String where,
    required List<Object?> whereArgs,
  }) async {
    if (kIsWeb) {
      return Result.failure(
        const DatabaseFailure('Database not supported on web platform'),
      );
    }

    final Result<Database> dbResult = await getDatabase();
    return dbResult.fold(
      (db) async {
        try {
          final int count = await db.delete(
            kLocationsTable,
            where: where,
            whereArgs: whereArgs,
          );
          return Result.success(count);
        } catch (e) {
          return Result.failure(DatabaseFailure('Delete failed: $e'));
        }
      },
      Result.failure,
    );
  }

  /// Queries the locations table.
  Future<Result<List<Map<String, dynamic>>>> query({
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    if (kIsWeb) {
      return Result.failure(
        const DatabaseFailure('Database not supported on web platform'),
      );
    }

    final Result<Database> dbResult = await getDatabase();
    return dbResult.fold(
      (db) async {
        try {
          final List<Map<String, dynamic>> results = await db.query(
            kLocationsTable,
            columns: columns,
            where: where,
            whereArgs: whereArgs,
            orderBy: orderBy,
            limit: limit,
          );
          return Result.success(results);
        } catch (e) {
          return Result.failure(DatabaseFailure('Query failed: $e'));
        }
      },
      Result.failure,
    );
  }

  /// Executes a raw SQL query.
  Future<Result<List<Map<String, dynamic>>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    if (kIsWeb) {
      return Result.failure(
        const DatabaseFailure('Database not supported on web platform'),
      );
    }

    final Result<Database> dbResult = await getDatabase();
    return dbResult.fold(
      (db) async {
        try {
          final List<Map<String, dynamic>> results =
              await db.rawQuery(sql, arguments);
          return Result.success(results);
        } catch (e) {
          return Result.failure(DatabaseFailure('Raw query failed: $e'));
        }
      },
      Result.failure,
    );
  }

  /// Closes the database connection.
  Future<void> close() async {
    if (kIsWeb) {
      return;
    }

    if (_database != null && await _isDatabaseOpen(_database)) {
      await closeLocationDatabase(_database);
      _database = null;
      _isInitialized = false;
    }
  }

  /// Checks if the database is initialized.
  bool get isInitialized => !kIsWeb && _isInitialized && _database != null;

  Future<bool> _isDatabaseOpen(dynamic db) async {
    if (kIsWeb) return false;
    return isLocationDatabaseOpen(db);
  }
}
