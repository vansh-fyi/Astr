// Web stub implementation for location database service
// SQLite is not supported on web platform

import 'package:sqflite_common/sqlite_api.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/engine/models/result.dart';

/// Stub implementation for web platform.
///
/// SQLite (sqflite) is not supported on web, so this returns failure.
/// Future consideration: Could implement with IndexedDB or in-memory storage.
Future<Result<Database>> initializeLocationDatabase({
  required String? testDatabasePath,
  required String dbName,
  required int version,
  required Future<void> Function(Database db, int version) onCreate,
  required Future<void> Function(Database db, int oldVersion, int newVersion)
      onUpgrade,
}) async {
  return Result.failure(
    const DatabaseFailure('Location database not supported on web platform'),
  );
}

/// Stub for closing database on web.
Future<void> closeLocationDatabase(dynamic db) async {
  // No-op on web
}

/// Stub for checking if database is open on web.
Future<bool> isLocationDatabaseOpen(dynamic db) async {
  return false;
}
