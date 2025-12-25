import 'dart:io';

import 'package:astr/core/engine/astro_engine.dart';
import 'package:astr/core/engine/database/database_service.dart';
import 'package:astr/core/engine/database/dso_repository.dart';
import 'package:astr/core/engine/database/star_repository.dart';
import 'package:astr/core/engine/models/coordinates.dart';
import 'package:astr/core/engine/models/dso.dart';
import 'package:astr/core/engine/models/location.dart';
import 'package:astr/core/engine/models/result.dart';
import 'package:astr/core/engine/models/rise_set_times.dart';
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

  group('Database Integration with AstroEngine (AC #4)', () {
    late DatabaseService databaseService;
    late StarRepository starRepository;
    late DsoRepository dsoRepository;
    late AstroEngine astroEngine;

    setUpAll(() async {
      // Copy database from assets to test directory
      final Directory testDir = await Directory.systemTemp.createTemp('astr_test_');
      final String testDbPath = join(testDir.path, 'astr_test.db');
      final File assetDb = File('assets/db/astr.db');
      await assetDb.copy(testDbPath);

      databaseService = DatabaseService(testDatabasePath: testDbPath);
      await databaseService.initialize();
      starRepository = StarRepository(databaseService);
      dsoRepository = DsoRepository(databaseService);
      astroEngine = AstroEngine();
    });

    tearDownAll(() async {
      await databaseService.close();
      await astroEngine.dispose();
    });

    test('Star from database can be passed to AstroEngine.calculatePosition', () async {
      // Get a star from the database
      final Result<List<Star>> starResult = await starRepository.searchByName('Sirius');
      expect(starResult.isSuccess, true);
      expect(starResult.value.isNotEmpty, true);

      final Star sirius = starResult.value.first;

      // Create location (New York)
      const Location location = Location(
        latitude: 40.7128,
        longitude: -74.0060,
      );

      // Calculate position using AstroEngine
      final Result<HorizontalCoordinates> positionResult = await astroEngine.calculatePosition(
        sirius,
        location,
        DateTime.utc(2024, 12, 3, 2),
      );

      // Verify calculation succeeded
      expect(positionResult.isSuccess, true);
      expect(positionResult.value.altitude, greaterThan(-90.0));
      expect(positionResult.value.altitude, lessThan(90.0));
      expect(positionResult.value.azimuth, greaterThanOrEqualTo(0.0));
      expect(positionResult.value.azimuth, lessThan(360.0));
    });

    test('DSO from database can be passed to AstroEngine.calculatePosition', () async {
      // Get a DSO from the database
      final Result<List<DSO>> dsoResult = await dsoRepository.searchByName('Andromeda');
      expect(dsoResult.isSuccess, true);
      expect(dsoResult.value.isNotEmpty, true);

      final DSO andromeda = dsoResult.value.first;

      // Create location (New York)
      const Location location = Location(
        latitude: 40.7128,
        longitude: -74.0060,
      );

      // Calculate position using AstroEngine
      final Result<HorizontalCoordinates> positionResult = await astroEngine.calculatePosition(
        andromeda,
        location,
        DateTime.utc(2024, 12, 3, 2),
      );

      // Verify calculation succeeded
      expect(positionResult.isSuccess, true);
      expect(positionResult.value.altitude, greaterThan(-90.0));
      expect(positionResult.value.altitude, lessThan(90.0));
      expect(positionResult.value.azimuth, greaterThanOrEqualTo(0.0));
      expect(positionResult.value.azimuth, lessThan(360.0));
    });

    test('Star from database can be passed to AstroEngine.calculateRiseSet', () async {
      // Get a star from the database
      final Result<List<Star>> starResult = await starRepository.searchByName('Sirius');
      expect(starResult.isSuccess, true);

      final Star sirius = starResult.value.first;

      // Create location (New York)
      const Location location = Location(
        latitude: 40.7128,
        longitude: -74.0060,
      );

      // Calculate rise/set times
      final Result<RiseSetTimes> riseSetResult = await astroEngine.calculateRiseSet(
        sirius,
        location,
        DateTime.utc(2024, 12, 3),
      );

      // Verify calculation succeeded
      expect(riseSetResult.isSuccess, true);
      // Sirius is not circumpolar from New York
      expect(riseSetResult.value.isCircumpolar, false);
      expect(riseSetResult.value.neverRises, false);
      expect(riseSetResult.value.riseTime, isNotNull);
      expect(riseSetResult.value.setTime, isNotNull);
    });

    test('DSO from database can be passed to AstroEngine.calculateRiseSet', () async {
      // Get a DSO from the database
      final Result<List<DSO>> dsoResult = await dsoRepository.searchByName('Andromeda');
      expect(dsoResult.isSuccess, true);

      final DSO andromeda = dsoResult.value.first;

      // Create location (New York)
      const Location location = Location(
        latitude: 40.7128,
        longitude: -74.0060,
      );

      // Calculate rise/set times
      final Result<RiseSetTimes> riseSetResult = await astroEngine.calculateRiseSet(
        andromeda,
        location,
        DateTime.utc(2024, 12, 3),
      );

      // Verify calculation succeeded
      expect(riseSetResult.isSuccess, true);
      expect(riseSetResult.value.riseTime, isNotNull);
      expect(riseSetResult.value.setTime, isNotNull);
    });

    test('database and engine work together in realistic workflow', () async {
      // User searches for "Vega"
      final Result<List<Star>> searchResult = await starRepository.searchByName('Vega');
      expect(searchResult.isSuccess, true);
      expect(searchResult.value.isNotEmpty, true);

      final Star vega = searchResult.value.first;

      // User wants to know if Vega is visible now
      const Location location = Location(latitude: 40.7128, longitude: -74.0060);
      final DateTime now = DateTime.utc(2024, 12, 3, 20);

      final Result<HorizontalCoordinates> positionResult = await astroEngine.calculatePosition(vega, location, now);
      expect(positionResult.isSuccess, true);

      // Check if above horizon
      final bool isVisible = positionResult.value.altitude > 0;

      // User wants rise/set times for planning
      final Result<RiseSetTimes> riseSetResult = await astroEngine.calculateRiseSet(
        vega,
        location,
        now,
      );

      expect(riseSetResult.isSuccess, true);

      // This demonstrates the complete workflow:
      // Database -> Repository -> Model -> Engine -> Result
      expect(isVisible, isA<bool>());
    });
  });
}
