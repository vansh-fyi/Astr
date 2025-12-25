// Mobile implementation for database service (iOS, Android, macOS, etc.)
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../error/failure.dart';
import '../models/result.dart';

Future<Result<Database>> initializePlatformDatabase({
  required String? testDatabasePath,
  required String dbName,
  required String assetPath,
}) async {
  try {
    // For testing, use the test database path directly if provided
    String dbPath;
    if (testDatabasePath != null) {
      dbPath = testDatabasePath;
    } else {
      // Get the application documents directory
      final Directory documentsDirectory = await getApplicationDocumentsDirectory();
      dbPath = join(documentsDirectory.path, dbName);

      // Check if database exists
      final File dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        // Copy from assets
        try {
          final ByteData byteData = await rootBundle.load(assetPath);
          final Uint8List bytes = byteData.buffer.asUint8List();

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
      final Database database = await openDatabase(
        dbPath,
        version: 1,
      );

      return Result.success(database);
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

Future<List<Map<String, dynamic>>> queryPlatformDatabase(
  dynamic db,
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
  final Database database = db as Database;
  return database.query(
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
}

Future<List<Map<String, dynamic>>> rawQueryPlatformDatabase(
  dynamic db,
  String sql, [
  List<Object?>? arguments,
]) async {
  final Database database = db as Database;
  return database.rawQuery(sql, arguments);
}

Future<void> closePlatformDatabase(dynamic db) async {
  final Database database = db as Database;
  await database.close();
}

Future<bool> isPlatformDatabaseOpen(dynamic db) async {
  final Database database = db as Database;
  return database.isOpen;
}
