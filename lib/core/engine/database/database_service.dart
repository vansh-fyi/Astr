import 'dart:io';
import 'package:astr/core/engine/models/result.dart';
import 'package:astr/core/error/failure.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Service for managing the local SQLite database
///
/// This service handles initialization of the database from assets,
/// maintains the connection, and provides access to the database instance.
class DatabaseService {
  static const String _dbName = 'astr.db';
  static const String _assetPath = 'assets/db/$_dbName';

  Database? _database;
  bool _isInitialized = false;

  /// Optional test database path (for testing only)
  final String? testDatabasePath;

  /// Creates a DatabaseService instance
  ///
  /// [testDatabasePath] is optional and should only be used in tests to provide
  /// a direct path to a test database file, bypassing asset loading.
  DatabaseService({this.testDatabasePath});

  /// Gets the database instance (initializes if needed)
  Future<Result<Database>> getDatabase() async {
    if (_database != null && _database!.isOpen) {
      return Result.success(_database!);
    }

    final initResult = await initialize();
    return initResult.fold(
      (_) => _database != null
          ? Result.success(_database!)
          : Result.failure(const DatabaseFailure('Database not initialized after initialization attempt')),
      (failure) => Result.failure(failure),
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
    if (_isInitialized && _database != null && _database!.isOpen) {
      return Result.success(null);
    }

    try {
      // For testing, use the test database path directly if provided
      String dbPath;
      if (testDatabasePath != null) {
        dbPath = testDatabasePath!;
      } else {
        // Get the application documents directory
        final documentsDirectory = await getApplicationDocumentsDirectory();
        dbPath = join(documentsDirectory.path, _dbName);

        // Check if database exists
        final dbFile = File(dbPath);
        if (!await dbFile.exists()) {
          // Copy from assets
          try {
            final byteData = await rootBundle.load(_assetPath);
            final bytes = byteData.buffer.asUint8List();

            // Ensure parent directory exists
            await dbFile.create(recursive: true);

            // Write the database file
            await dbFile.writeAsBytes(bytes, flush: true);
          } catch (e) {
            return Result.failure(
              DatabaseFailure('Failed to copy database from assets: $e'),
            );
          }
        }
      }

      // Open the database
      try {
        _database = await openDatabase(
          dbPath,
          version: 1,
          readOnly: false, // Allow writes for future updates
        );

        _isInitialized = true;
        return Result.success(null);
      } catch (e) {
        return Result.failure(
          DatabaseFailure('Failed to open database: $e'),
        );
      }
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
    final dbResult = await getDatabase();
    return dbResult.fold(
      (db) async {
        try {
          final results = await db.query(
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
      (failure) => Result.failure(failure),
    );
  }

  /// Executes a raw SQL query with custom SQL
  Future<Result<List<Map<String, dynamic>>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final dbResult = await getDatabase();
    return dbResult.fold(
      (db) async {
        try {
          final results = await db.rawQuery(sql, arguments);
          return Result.success(results);
        } catch (e) {
          return Result.failure(
            DatabaseFailure('Raw query failed: $e'),
          );
        }
      },
      (failure) => Result.failure(failure),
    );
  }

  /// Closes the database connection
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      _isInitialized = false;
    }
  }

  /// Checks if the database is initialized
  bool get isInitialized => _isInitialized && _database != null && _database!.isOpen;
}
