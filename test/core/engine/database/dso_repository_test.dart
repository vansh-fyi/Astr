import 'dart:io';
import 'package:astr/core/engine/database/database_service.dart';
import 'package:astr/core/engine/database/dso_repository.dart';
import 'package:astr/core/engine/models/dso.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize sqflite for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DsoRepository', () {
    late DatabaseService databaseService;
    late DsoRepository repository;

    setUpAll(() async {
      // Copy database from assets to test directory
      final testDir = await Directory.systemTemp.createTemp('astr_test_');
      final testDbPath = join(testDir.path, 'astr_test.db');
      final assetDb = File('assets/db/astr.db');
      await assetDb.copy(testDbPath);

      databaseService = DatabaseService(testDatabasePath: testDbPath);
      await databaseService.initialize();
      repository = DsoRepository(databaseService);
    });

    tearDownAll(() async {
      await databaseService.close();
    });

    group('searchByName (AC #2)', () {
      test('searching for "Andromeda" returns correct DSO object', () async {
        final result = await repository.searchByName('Andromeda');

        expect(result.isSuccess, true);
        expect(result.value.length, greaterThan(0));

        final andromeda = result.value.first;
        expect(andromeda, isA<DSO>());
        expect(andromeda.name, contains('Andromeda'));
        expect(andromeda.messierId, 'M31');
        expect(andromeda.ngcId, 'NGC224');
        expect(andromeda.dsoType, DSOType.galaxy);
        expect(andromeda.magnitude, closeTo(3.44, 0.1));
      });

      test('searching by Messier ID works', () async {
        final result = await repository.searchByName('M31');

        expect(result.isSuccess, true);
        expect(result.value.length, greaterThan(0));
        expect(result.value.first.messierId, 'M31');
      });

      test('searching by NGC ID works', () async {
        final result = await repository.searchByName('NGC224');

        expect(result.isSuccess, true);
        expect(result.value.length, greaterThan(0));
        expect(result.value.first.ngcId, 'NGC224');
      });

      test('partial name search works', () async {
        final result = await repository.searchByName('Orion');

        expect(result.isSuccess, true);
        expect(result.value.length, greaterThan(0));
        expect(result.value.first.name, contains('Orion'));
      });

      test('case-insensitive search works', () async {
        final result = await repository.searchByName('andromeda');

        expect(result.isSuccess, true);
        expect(result.value.length, greaterThan(0));
      });

      test('empty query returns empty list', () async {
        final result = await repository.searchByName('');

        expect(result.isSuccess, true);
        expect(result.value, isEmpty);
      });

      test('non-existent DSO returns empty list', () async {
        final result = await repository.searchByName('NonExistentDSO12345');

        expect(result.isSuccess, true);
        expect(result.value, isEmpty);
      });
    });

    group('searchByType', () {
      test('finds galaxies', () async {
        final result = await repository.searchByType(DSOType.galaxy);

        expect(result.isSuccess, true);
        expect(result.value.length, greaterThan(0));

        for (final dso in result.value) {
          expect(dso.dsoType, DSOType.galaxy);
        }
      });

      test('finds nebulae', () async {
        final result = await repository.searchByType(DSOType.nebula);

        expect(result.isSuccess, true);
        expect(result.value.length, greaterThan(0));

        for (final dso in result.value) {
          expect(dso.dsoType, DSOType.nebula);
        }
      });

      test('finds clusters', () async {
        final result = await repository.searchByType(DSOType.cluster);

        expect(result.isSuccess, true);
        expect(result.value.length, greaterThan(0));

        for (final dso in result.value) {
          expect(dso.dsoType, DSOType.cluster);
        }
      });
    });

    group('getByMessierId', () {
      test('gets Andromeda by Messier ID', () async {
        final result = await repository.getByMessierId('M31');

        expect(result.isSuccess, true);
        expect(result.value, isNotNull);
        expect(result.value!.messierId, 'M31');
        expect(result.value!.name, contains('Andromeda'));
      });

      test('gets Orion Nebula by Messier ID', () async {
        final result = await repository.getByMessierId('M42');

        expect(result.isSuccess, true);
        expect(result.value, isNotNull);
        expect(result.value!.messierId, 'M42');
      });

      test('non-existent Messier ID returns null', () async {
        final result = await repository.getByMessierId('M999');

        expect(result.isSuccess, true);
        expect(result.value, isNull);
      });
    });

    group('getByNgcId', () {
      test('gets Andromeda by NGC ID', () async {
        final result = await repository.getByNgcId('NGC224');

        expect(result.isSuccess, true);
        expect(result.value, isNotNull);
        expect(result.value!.ngcId, 'NGC224');
      });

      test('non-existent NGC ID returns null', () async {
        final result = await repository.getByNgcId('NGC99999');

        expect(result.isSuccess, true);
        expect(result.value, isNull);
      });
    });

    group('searchByConstellation', () {
      test('finds DSOs in Andromeda constellation', () async {
        final result = await repository.searchByConstellation('Andromeda');

        expect(result.isSuccess, true);
        expect(result.value.length, greaterThan(0));
        expect(result.value.first.constellation, 'Andromeda');
      });

      test('empty constellation returns empty list', () async {
        final result = await repository.searchByConstellation('');

        expect(result.isSuccess, true);
        expect(result.value, isEmpty);
      });
    });

    group('getAll', () {
      test('returns multiple DSOs', () async {
        final result = await repository.getAll(limit: 10);

        expect(result.isSuccess, true);
        expect(result.value.length, greaterThan(0));
      });
    });

    group('performance (AC #3)', () {
      test('search query completes in < 100ms', () async {
        final stopwatch = Stopwatch()..start();

        await repository.searchByName('Andromeda');

        stopwatch.stop();

        // AC #3: Database queries complete in < 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}
