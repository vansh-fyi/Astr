// Mobile implementation for location database service (iOS, Android, macOS, etc.)
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/engine/models/result.dart';

/// Initializes the location database for mobile platforms.
///
/// Unlike the main DatabaseService which copies from assets, this creates
/// a fresh database for user-generated content.
Future<Result<Database>> initializeLocationDatabase({
  required String? testDatabasePath,
  required String dbName,
  required int version,
  required Future<void> Function(Database db, int version) onCreate,
  required Future<void> Function(Database db, int oldVersion, int newVersion)
      onUpgrade,
}) async {
  try {
    String dbPath;
    if (testDatabasePath != null) {
      dbPath = testDatabasePath;
    } else {
      // Get the application documents directory
      final Directory documentsDirectory =
          await getApplicationDocumentsDirectory();
      dbPath = join(documentsDirectory.path, dbName);

      // Ensure parent directory exists
      final File dbFile = File(dbPath);
      final Directory parentDir = dbFile.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }
    }

    // Open the database with schema creation callbacks
    try {
      final Database database = await openDatabase(
        dbPath,
        version: version,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
      );

      return Result.success(database);
    } catch (e) {
      return Result.failure(
        DatabaseFailure('Failed to open location database: $e'),
      );
    }
  } catch (e) {
    return Result.failure(
      DatabaseFailure('Failed to initialize location database: $e'),
    );
  }
}

/// Closes the location database.
Future<void> closeLocationDatabase(dynamic db) async {
  final Database database = db as Database;
  await database.close();
}

/// Checks if the location database is open.
Future<bool> isLocationDatabaseOpen(dynamic db) async {
  final Database database = db as Database;
  return database.isOpen;
}
