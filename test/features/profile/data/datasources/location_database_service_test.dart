import 'dart:io';

import 'package:astr/features/profile/data/datasources/location_database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize sqflite for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late LocationDatabaseService service;
  late String testDbPath;

  setUp(() async {
    // Create a unique test database path
    final testDir = Directory.systemTemp.createTempSync('location_db_test_');
    testDbPath = join(testDir.path, 'test_locations.db');

    service = LocationDatabaseService(testDatabasePath: testDbPath);
  });

  tearDown(() async {
    // Clean up: close and delete test database
    await service.close();
    final dbFile = File(testDbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    // Clean up temp directory
    final testDir = Directory(dirname(testDbPath));
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });

  group('LocationDatabaseService Initialization', () {
    test('initializes database successfully', () async {
      final result = await service.initialize();

      expect(result.isSuccess, true);
      expect(service.isInitialized, true);
    });

    test('creates locations table on first initialization', () async {
      await service.initialize();

      // Query to check if table exists
      final result = await service.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$kLocationsTable'",
      );

      expect(result.isSuccess, true);
      result.fold(
        (tables) {
          expect(tables, isNotEmpty);
          expect(tables.first['name'], kLocationsTable);
        },
        (_) => fail('Expected successful table query'),
      );
    });

    test('creates all required indexes', () async {
      await service.initialize();

      // Query for indexes on locations table
      final result = await service.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='$kLocationsTable'",
      );

      expect(result.isSuccess, true);
      result.fold(
        (indexes) {
          final indexNames = indexes.map((i) => i['name'] as String).toList();

          // SQLite automatically creates index for PRIMARY KEY
          // We should have our 3 custom indexes
          expect(indexNames, contains('idx_h3Index'));
          expect(indexNames, contains('idx_lastViewedTimestamp'));
          expect(indexNames, contains('idx_isPinned'));
        },
        (_) => fail('Expected successful index query'),
      );
    });

    test('returns success when initialized multiple times (idempotent)', () async {
      final result1 = await service.initialize();
      final result2 = await service.initialize();

      expect(result1.isSuccess, true);
      expect(result2.isSuccess, true);
    });
  });

  group('LocationDatabaseService CRUD Operations', () {
    setUp(() async {
      await service.initialize();
    });

    test('inserts location successfully', () async {
      final testLocation = {
        'id': 'test_001',
        'name': 'Test Location',
        'latitude': 37.7749,
        'longitude': -122.4194,
        'h3Index': '882a107283fffff',
        'lastViewedTimestamp': DateTime.now().millisecondsSinceEpoch,
        'isPinned': 0,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      final result = await service.insert(testLocation);

      expect(result.isSuccess, true);
    });

    test('queries inserted location by id', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final testLocation = {
        'id': 'query_test',
        'name': 'Queryable Location',
        'latitude': 40.0,
        'longitude': -74.0,
        'h3Index': '882a100000fffff',
        'lastViewedTimestamp': now,
        'isPinned': 1,
        'createdAt': now,
      };

      await service.insert(testLocation);

      final result = await service.query(
        where: '${LocationColumns.id} = ?',
        whereArgs: ['query_test'],
      );

      expect(result.isSuccess, true);
      result.fold(
        (rows) {
          expect(rows.length, 1);
          expect(rows.first['id'], 'query_test');
          expect(rows.first['name'], 'Queryable Location');
          expect(rows.first['isPinned'], 1);
        },
        (_) => fail('Expected successful query'),
      );
    });

    test('updates location successfully', () async {
      final testLocation = {
        'id': 'update_test',
        'name': 'Original Name',
        'latitude': 35.0,
        'longitude': -120.0,
        'h3Index': '882a200000fffff',
        'lastViewedTimestamp': DateTime.now().millisecondsSinceEpoch,
        'isPinned': 0,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      await service.insert(testLocation);

      final updateResult = await service.update(
        {'name': 'Updated Name'},
        where: '${LocationColumns.id} = ?',
        whereArgs: ['update_test'],
      );

      expect(updateResult.isSuccess, true);
      updateResult.fold(
        (count) => expect(count, 1),
        (_) => fail('Expected successful update'),
      );

      // Verify update
      final queryResult = await service.query(
        where: '${LocationColumns.id} = ?',
        whereArgs: ['update_test'],
      );

      queryResult.fold(
        (rows) => expect(rows.first['name'], 'Updated Name'),
        (_) => fail('Expected successful query'),
      );
    });

    test('deletes location successfully', () async {
      final testLocation = {
        'id': 'delete_test',
        'name': 'To Be Deleted',
        'latitude': 45.0,
        'longitude': -95.0,
        'h3Index': '882a300000fffff',
        'lastViewedTimestamp': DateTime.now().millisecondsSinceEpoch,
        'isPinned': 0,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      await service.insert(testLocation);

      final deleteResult = await service.delete(
        where: '${LocationColumns.id} = ?',
        whereArgs: ['delete_test'],
      );

      expect(deleteResult.isSuccess, true);
      deleteResult.fold(
        (count) => expect(count, 1),
        (_) => fail('Expected successful delete'),
      );

      // Verify deletion
      final queryResult = await service.query(
        where: '${LocationColumns.id} = ?',
        whereArgs: ['delete_test'],
      );

      queryResult.fold(
        (rows) => expect(rows, isEmpty),
        (_) => fail('Expected successful query'),
      );
    });

    test('replaces location with same id (upsert)', () async {
      final location1 = {
        'id': 'upsert_test',
        'name': 'First Version',
        'latitude': 50.0,
        'longitude': -100.0,
        'h3Index': '882a400000fffff',
        'lastViewedTimestamp': DateTime.now().millisecondsSinceEpoch,
        'isPinned': 0,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      await service.insert(location1);

      // Insert again with same id but different name
      final location2 = {...location1, 'name': 'Second Version'};
      await service.insert(location2);

      // Should have only one record (replaced, not duplicated)
      final queryResult = await service.query(
        where: '${LocationColumns.id} = ?',
        whereArgs: ['upsert_test'],
      );

      queryResult.fold(
        (rows) {
          expect(rows.length, 1);
          expect(rows.first['name'], 'Second Version');
        },
        (_) => fail('Expected successful query'),
      );
    });

    test('queries with orderBy returns sorted results', () async {
      final now = DateTime.now();

      final loc1 = {
        'id': 'loc_1',
        'name': 'Location A',
        'latitude': 30.0,
        'longitude': -90.0,
        'h3Index': '882a500000fffff',
        'lastViewedTimestamp': now.subtract(const Duration(days: 5)).millisecondsSinceEpoch,
        'isPinned': 0,
        'createdAt': now.millisecondsSinceEpoch,
      };

      final loc2 = {
        'id': 'loc_2',
        'name': 'Location B',
        'latitude': 31.0,
        'longitude': -91.0,
        'h3Index': '882a600000fffff',
        'lastViewedTimestamp': now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
        'isPinned': 0,
        'createdAt': now.millisecondsSinceEpoch,
      };

      await service.insert(loc1);
      await service.insert(loc2);

      final result = await service.query(
        orderBy: '${LocationColumns.lastViewedTimestamp} DESC',
      );

      result.fold(
        (rows) {
          expect(rows.length, greaterThanOrEqualTo(2));
          // loc_2 should come first (more recent)
          final relevantRows = rows.where((r) => r['id'] == 'loc_1' || r['id'] == 'loc_2').toList();
          expect(relevantRows[0]['id'], 'loc_2');
          expect(relevantRows[1]['id'], 'loc_1');
        },
        (_) => fail('Expected successful query'),
      );
    });
  });

  group('LocationDatabaseService Edge Cases', () {
    setUp(() async {
      await service.initialize();
    });

    test('query returns empty list when no matches', () async {
      final result = await service.query(
        where: '${LocationColumns.id} = ?',
        whereArgs: ['non_existent_id'],
      );

      expect(result.isSuccess, true);
      result.fold(
        (rows) => expect(rows, isEmpty),
        (_) => fail('Expected successful query'),
      );
    });

    test('update returns 0 when no rows match', () async {
      final result = await service.update(
        {'name': 'Updated'},
        where: '${LocationColumns.id} = ?',
        whereArgs: ['does_not_exist'],
      );

      expect(result.isSuccess, true);
      result.fold(
        (count) => expect(count, 0),
        (_) => fail('Expected successful update'),
      );
    });

    test('delete returns 0 when no rows match (idempotent)', () async {
      final result = await service.delete(
        where: '${LocationColumns.id} = ?',
        whereArgs: ['does_not_exist'],
      );

      expect(result.isSuccess, true);
      result.fold(
        (count) => expect(count, 0),
        (_) => fail('Expected successful delete'),
      );
    });
  });
}
