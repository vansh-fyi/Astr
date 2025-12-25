// Web stub implementation for database service
import '../../error/failure.dart';
import '../models/result.dart';

Future<Result<dynamic>> initializePlatformDatabase({
  required String? testDatabasePath,
  required String dbName,
  required String assetPath,
}) async {
  return Result.failure(
    const DatabaseFailure('SQLite database not supported on web platform'),
  );
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
  throw UnsupportedError('Database operations not supported on web');
}

Future<List<Map<String, dynamic>>> rawQueryPlatformDatabase(
  dynamic db,
  String sql, [
  List<Object?>? arguments,
]) async {
  throw UnsupportedError('Database operations not supported on web');
}

Future<void> closePlatformDatabase(dynamic db) async {
  // No-op on web
}

Future<bool> isPlatformDatabaseOpen(dynamic db) async {
  return false;
}
