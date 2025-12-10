import 'dart:io';
import 'package:astr/core/engine/database/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize sqflite for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseService', () {
    late DatabaseService service;
    late String testDbPath;

    setUpAll(() async {
      // Copy database from assets to test directory
      final testDir = await Directory.systemTemp.createTemp('astr_test_');
      testDbPath = join(testDir.path, 'astr_test.db');

      // Copy the database file from assets directory to test directory
      final assetDb = File('assets/db/astr.db');
      await assetDb.copy(testDbPath);
    });

    setUp(() {
      service = DatabaseService(testDatabasePath: testDbPath);
    });

    tearDown(() async {
      await service.close();
    });

    test('initialize creates database from assets', () async {
      final result = await service.initialize();

      expect(result.isSuccess, true);
      expect(service.isInitialized, true);
    });

    test('getDatabase returns initialized database', () async {
      await service.initialize();

      final dbResult = await service.getDatabase();

      expect(dbResult.isSuccess, true);
      expect(dbResult.value, isA<Database>());
      expect(dbResult.value.isOpen, true);
    });

    test('getDatabase auto-initializes if not initialized', () async {
      final dbResult = await service.getDatabase();

      expect(dbResult.isSuccess, true);
      expect(service.isInitialized, true);
    });

    test('query executes successfully on stars table', () async {
      await service.initialize();

      final result = await service.query('stars', limit: 10);

      expect(result.isSuccess, true);
      expect(result.value, isA<List<Map<String, dynamic>>>());
    });

    test('query with where clause works correctly', () async {
      await service.initialize();

      final result = await service.query(
        'stars',
        where: 'name = ?',
        whereArgs: ['Sirius'],
      );

      expect(result.isSuccess, true);
      expect(result.value.length, greaterThan(0));

      final star = result.value.first;
      expect(star['name'], 'Sirius');
    });

    test('rawQuery executes successfully', () async {
      await service.initialize();

      final result = await service.rawQuery(
        'SELECT COUNT(*) as count FROM stars',
      );

      expect(result.isSuccess, true);
      expect(result.value.first['count'], greaterThan(0));
    });

    test('close closes database connection', () async {
      await service.initialize();
      expect(service.isInitialized, true);

      await service.close();

      expect(service.isInitialized, false);
    });

    test('multiple initialize calls are safe', () async {
      final result1 = await service.initialize();
      final result2 = await service.initialize();

      expect(result1.isSuccess, true);
      expect(result2.isSuccess, true);
      expect(service.isInitialized, true);
    });
  });
}
