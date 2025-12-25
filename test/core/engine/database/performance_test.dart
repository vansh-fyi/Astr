import 'dart:io';

import 'package:astr/core/engine/database/database_service.dart';
import 'package:astr/core/engine/database/dso_repository.dart';
import 'package:astr/core/engine/database/star_repository.dart';
import 'package:astr/core/engine/models/dso.dart';
import 'package:astr/core/engine/models/result.dart';
import 'package:astr/core/engine/models/star.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Performance Test for Database Queries (AC #3)
///
/// Validates that database queries complete in < 100ms
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Performance (AC #3)', () {
    late DatabaseService databaseService;
    late StarRepository starRepository;
    late DsoRepository dsoRepository;

    setUpAll(() async {
      // Copy database from assets to test directory
      final Directory testDir = await Directory.systemTemp.createTemp('astr_perf_test_');
      final String testDbPath = join(testDir.path, 'astr_test.db');
      final File assetDb = File('assets/db/astr.db');
      await assetDb.copy(testDbPath);

      databaseService = DatabaseService(testDatabasePath: testDbPath);
      await databaseService.initialize();
      starRepository = StarRepository(databaseService);
      dsoRepository = DsoRepository(databaseService);
    });

    tearDownAll(() async {
      await databaseService.close();
    });

    test('star search by name completes in < 100ms', () async {
      final Stopwatch stopwatch = Stopwatch()..start();
      
      final Result<List<Star>> result = await starRepository.searchByName('Sirius');
      
      stopwatch.stop();
      final int elapsedMs = stopwatch.elapsedMilliseconds;

      expect(result.isSuccess, true);
      expect(elapsedMs, lessThan(100), 
        reason: 'Star search must complete in < 100ms (actual: ${elapsedMs}ms)');
    });

    test('dso search by name completes in < 100ms', () async {
      final Stopwatch stopwatch = Stopwatch()..start();
      
      final Result<List<DSO>> result = await dsoRepository.searchByName('Andromeda');
      
      stopwatch.stop();
      final int elapsedMs = stopwatch.elapsedMilliseconds;

      expect(result.isSuccess, true);
      expect(elapsedMs, lessThan(100), 
        reason: 'DSO search must complete in < 100ms (actual: ${elapsedMs}ms)');
    });

    test('star search by constellation completes in < 100ms', () async {
      final Stopwatch stopwatch = Stopwatch()..start();
      
      final Result<List<Star>> result = await starRepository.searchByConstellation('Orion');
      
      stopwatch.stop();
      final int elapsedMs = stopwatch.elapsedMilliseconds;

      expect(result.isSuccess, true);
      expect(elapsedMs, lessThan(100), 
        reason: 'Constellation search must complete in < 100ms (actual: ${elapsedMs}ms)');
    });

    test('dso search by type completes in < 100ms', () async {
      final Stopwatch stopwatch = Stopwatch()..start();
      
      final Result<List<DSO>> result = await dsoRepository.searchByType(DSOType.galaxy);
      
      stopwatch.stop();
      final int elapsedMs = stopwatch.elapsedMilliseconds;

      expect(result.isSuccess, true);
      expect(elapsedMs, lessThan(100), 
        reason: 'DSO type search must complete in < 100ms (actual: ${elapsedMs}ms)');
    });

    test('get brightest stars completes in < 100ms', () async {
      final Stopwatch stopwatch = Stopwatch()..start();
      
      final Result<List<Star>> result = await starRepository.getBrightestStars(limit: 50);
      
      stopwatch.stop();
      final int elapsedMs = stopwatch.elapsedMilliseconds;

      expect(result.isSuccess, true);
      expect(elapsedMs, lessThan(100), 
        reason: 'Brightest stars query must complete in < 100ms (actual: ${elapsedMs}ms)');
    });

    test('multiple consecutive queries maintain performance', () async {
      final List<int> timings = <int>[];

      // Run 10 queries and measure each
      for (int i = 0; i < 10; i++) {
        final Stopwatch stopwatch = Stopwatch()..start();
        await starRepository.searchByName('Vega');
        stopwatch.stop();
        timings.add(stopwatch.elapsedMilliseconds);
      }

      // All queries should be under 100ms
      for (int i = 0; i < timings.length; i++) {
        expect(timings[i], lessThan(100), 
          reason: 'Query $i must complete in < 100ms (actual: ${timings[i]}ms)');
      }

      // Average should be well under 100ms
      final double avgMs = timings.reduce((int a, int b) => a + b) / timings.length;
      expect(avgMs, lessThan(50), 
        reason: 'Average query time should be < 50ms for good UX (actual: ${avgMs.toStringAsFixed(1)}ms)');
    });

    test('database initialization completes quickly', () async {
      // Create a new service to test initialization time
      final Directory testDir = await Directory.systemTemp.createTemp('astr_init_test_');
      final String testDbPath = join(testDir.path, 'astr_init.db');
      final File assetDb = File('assets/db/astr.db');
      await assetDb.copy(testDbPath);

      final DatabaseService testService = DatabaseService(testDatabasePath: testDbPath);

      final Stopwatch stopwatch = Stopwatch()..start();
      final Result<void> result = await testService.initialize();
      stopwatch.stop();
      final int elapsedMs = stopwatch.elapsedMilliseconds;

      expect(result.isSuccess, true);
      expect(elapsedMs, lessThan(500), 
        reason: 'Database initialization should be quick (actual: ${elapsedMs}ms)');

      await testService.close();
    });
  });
}
