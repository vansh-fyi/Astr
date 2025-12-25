import 'dart:io';
import 'package:astr/core/engine/database/database_service.dart';
import 'package:astr/core/engine/database/star_repository.dart';
import 'package:astr/core/engine/models/result.dart';
import 'package:astr/core/engine/models/star.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize sqflite for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('StarRepository', () {
    late DatabaseService databaseService;
    late StarRepository repository;

    setUpAll(() async {
      // Copy database from assets to test directory
      final Directory testDir = await Directory.systemTemp.createTemp('astr_test_');
      final String testDbPath = join(testDir.path, 'astr_test.db');
      final File assetDb = File('assets/db/astr.db');
      await assetDb.copy(testDbPath);

      databaseService = DatabaseService(testDatabasePath: testDbPath);
      await databaseService.initialize();
      repository = StarRepository(databaseService);
    });

    tearDownAll(() async {
      await databaseService.close();
    });

    group('searchByName (AC #2)', () {
      test('searching for "Sirius" returns correct Star object', () async {
        final Result<List<Star>> result = await repository.searchByName('Sirius');

        expect(result.isSuccess, true);
        expect(result.value.length, greaterThan(0));

        final Star sirius = result.value.first;
        expect(sirius, isA<Star>());
        expect(sirius.name, 'Sirius');
        expect(sirius.hipId, 32349);
        expect(sirius.magnitude, closeTo(-1.46, 0.01));
        expect(sirius.constellation, 'Canis Major');
      });

      test('partial name search works', () async {
        final Result<List<Star>> result = await repository.searchByName('Sir');

        expect(result.isSuccess, true);
        expect(result.value.length, greaterThan(0));
        expect(result.value.first.name, contains('Sir'));
      });

      test('case-insensitive search works', () async {
        final Result<List<Star>> result = await repository.searchByName('sirius');

        expect(result.isSuccess, true);
        expect(result.value.length, greaterThan(0));
      });

      test('empty query returns empty list', () async {
        final Result<List<Star>> result = await repository.searchByName('');

        expect(result.isSuccess, true);
        expect(result.value, isEmpty);
      });

      test('non-existent star returns empty list', () async {
        final Result<List<Star>> result = await repository.searchByName('NonExistentStar12345');

        expect(result.isSuccess, true);
        expect(result.value, isEmpty);
      });
    });

    group('searchByConstellation', () {
      test('finds stars in Orion', () async {
        final Result<List<Star>> result = await repository.searchByConstellation('Orion');

        expect(result.isSuccess, true);
        expect(result.value.length, greaterThan(0));
        expect(result.value.first.constellation, 'Orion');
      });

      test('empty constellation returns empty list', () async {
        final Result<List<Star>> result = await repository.searchByConstellation('');

        expect(result.isSuccess, true);
        expect(result.value, isEmpty);
      });
    });

    group('getByHipId', () {
      test('gets Sirius by Hipparcos ID', () async {
        final Result<Star?> result = await repository.getByHipId(32349);

        expect(result.isSuccess, true);
        expect(result.value, isNotNull);
        expect(result.value!.name, 'Sirius');
      });

      test('non-existent HIP ID returns null', () async {
        final Result<Star?> result = await repository.getByHipId(999999);

        expect(result.isSuccess, true);
        expect(result.value, isNull);
      });
    });

    group('getBrightestStars', () {
      test('returns stars ordered by magnitude', () async {
        final Result<List<Star>> result = await repository.getBrightestStars();

        expect(result.isSuccess, true);
        expect(result.value.length, greaterThan(0));

        // Check ordering (brightest first)
        for (int i = 0; i < result.value.length - 1; i++) {
          if (result.value[i].magnitude != null &&
              result.value[i + 1].magnitude != null) {
            expect(
              result.value[i].magnitude,
              lessThanOrEqualTo(result.value[i + 1].magnitude!),
            );
          }
        }
      });

      test('respects magnitude limit', () async {
        final Result<List<Star>> result = await repository.getBrightestStars(maxMagnitude: 1);

        expect(result.isSuccess, true);
        for (final Star star in result.value) {
          if (star.magnitude != null) {
            expect(star.magnitude, lessThanOrEqualTo(1.0));
          }
        }
      });
    });

    group('getAll', () {
      test('returns multiple stars', () async {
        final Result<List<Star>> result = await repository.getAll(limit: 10);

        expect(result.isSuccess, true);
        expect(result.value.length, greaterThan(0));
      });
    });

    group('performance (AC #3)', () {
      test('search query completes in < 100ms', () async {
        final Stopwatch stopwatch = Stopwatch()..start();

        await repository.searchByName('Sirius');

        stopwatch.stop();

        // AC #3: Database queries complete in < 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}
