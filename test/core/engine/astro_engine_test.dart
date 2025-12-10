import 'package:astr/core/engine/astro_engine.dart';
import 'package:astr/core/engine/models/celestial_object.dart';
import 'package:astr/core/engine/models/coordinates.dart';
import 'package:astr/core/engine/models/location.dart';
import 'package:astr/core/engine/models/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AstroEngine', () {
    late AstroEngine engine;

    setUp(() {
      engine = AstroEngine();
    });

    tearDown(() async {
      await engine.dispose();
    });

    group('calculatePosition', () {
      test('returns Success with valid coordinates', () async {
        final sirius = CelestialObject(
          id: 'HIP32349',
          name: 'Sirius',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 101.287,
            declination: -16.716,
          ),
          magnitude: -1.46,
        );

        final location = Location(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final dateTime = DateTime.utc(2024, 12, 3, 2, 0, 0);

        final result = await engine.calculatePosition(sirius, location, dateTime);

        expect(result.isSuccess, true);
        expect(result.value.altitude, greaterThan(-90.0));
        expect(result.value.altitude, lessThan(90.0));
        expect(result.value.azimuth, greaterThanOrEqualTo(0.0));
        expect(result.value.azimuth, lessThan(360.0));
      });

      test('calculates consistent positions for the same inputs', () async {
        final object = CelestialObject(
          id: 'test',
          name: 'Test Object',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 150.0,
            declination: 30.0,
          ),
        );

        final location = Location(latitude: 40.0, longitude: -75.0);
        final dateTime = DateTime.utc(2024, 12, 3, 12, 0, 0);

        final result1 = await engine.calculatePosition(object, location, dateTime);
        final result2 = await engine.calculatePosition(object, location, dateTime);

        expect(result1.isSuccess, true);
        expect(result2.isSuccess, true);
        expect(result1.value.altitude, closeTo(result2.value.altitude, 0.001));
        expect(result1.value.azimuth, closeTo(result2.value.azimuth, 0.001));
      });

      test('returns Failure when engine is disposed', () async {
        final object = CelestialObject(
          id: 'test',
          name: 'Test',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 0.0,
            declination: 0.0,
          ),
        );

        final location = Location(latitude: 0.0, longitude: 0.0);
        final dateTime = DateTime.utc(2024, 12, 3);

        await engine.dispose();

        final result = await engine.calculatePosition(object, location, dateTime);

        expect(result.isFailure, true);
        expect(result.failure.message, contains('disposed'));
      });

      test('position changes over time for the same object', () async {
        final object = CelestialObject(
          id: 'test',
          name: 'Test Object',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 150.0,
            declination: 30.0,
          ),
        );

        final location = Location(latitude: 40.0, longitude: -75.0);

        final time1 = DateTime.utc(2024, 12, 3, 12, 0, 0);
        final time2 = DateTime.utc(2024, 12, 3, 18, 0, 0);

        final result1 = await engine.calculatePosition(object, location, time1);
        final result2 = await engine.calculatePosition(object, location, time2);

        expect(result1.isSuccess, true);
        expect(result2.isSuccess, true);

        // Position should be different after 6 hours
        final altDiff = (result1.value.altitude - result2.value.altitude).abs();
        final azDiff = (result1.value.azimuth - result2.value.azimuth).abs();

        expect(altDiff, greaterThan(1.0)); // Should differ by more than 1 degree
      });
    });

    group('calculateRiseSet', () {
      test('returns Success with valid rise/set times', () async {
        final sirius = CelestialObject(
          id: 'HIP32349',
          name: 'Sirius',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 101.287,
            declination: -16.716,
          ),
          magnitude: -1.46,
        );

        final location = Location(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final date = DateTime.utc(2024, 12, 3);

        final result = await engine.calculateRiseSet(sirius, location, date);

        expect(result.isSuccess, true);
        expect(result.value.isCircumpolar, false);
        expect(result.value.neverRises, false);
        expect(result.value.riseTime, isNotNull);
        expect(result.value.transitTime, isNotNull);
        expect(result.value.setTime, isNotNull);
      });

      test('identifies circumpolar objects', () async {
        final polaris = CelestialObject(
          id: 'polaris',
          name: 'Polaris',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 37.95,
            declination: 89.26,
          ),
          magnitude: 2.0,
        );

        final location = Location(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final date = DateTime.utc(2024, 12, 3);

        final result = await engine.calculateRiseSet(polaris, location, date);

        expect(result.isSuccess, true);
        expect(result.value.isCircumpolar, true);
        expect(result.value.riseTime, isNull);
        expect(result.value.setTime, isNull);
      });

      test('identifies objects that never rise', () async {
        final southernObject = CelestialObject(
          id: 'southern',
          name: 'Southern Object',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 0.0,
            declination: -85.0,
          ),
        );

        final location = Location(
          latitude: 60.0,
          longitude: 0.0,
        );

        final date = DateTime.utc(2024, 12, 3);

        final result = await engine.calculateRiseSet(southernObject, location, date);

        expect(result.isSuccess, true);
        expect(result.value.neverRises, true);
        expect(result.value.riseTime, isNull);
        expect(result.value.setTime, isNull);
      });

      test('returns Failure when engine is disposed', () async {
        final object = CelestialObject(
          id: 'test',
          name: 'Test',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 0.0,
            declination: 0.0,
          ),
        );

        final location = Location(latitude: 0.0, longitude: 0.0);
        final date = DateTime.utc(2024, 12, 3);

        await engine.dispose();

        final result = await engine.calculateRiseSet(object, location, date);

        expect(result.isFailure, true);
        expect(result.failure.message, contains('disposed'));
      });
    });

    group('Result pattern usage', () {
      test('Success result provides value', () async {
        final object = CelestialObject(
          id: 'test',
          name: 'Test',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 0.0,
            declination: 0.0,
          ),
        );

        final location = Location(latitude: 0.0, longitude: 0.0);
        final dateTime = DateTime.utc(2024, 12, 3);

        final result = await engine.calculatePosition(object, location, dateTime);

        // Test fold method
        final folded = result.fold(
          (value) => 'Success: ${value.altitude}',
          (failure) => 'Failure: ${failure.message}',
        );

        expect(folded, startsWith('Success:'));
      });

      test('Failure result provides error information', () async {
        final object = CelestialObject(
          id: 'test',
          name: 'Test',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 0.0,
            declination: 0.0,
          ),
        );

        final location = Location(latitude: 0.0, longitude: 0.0);
        final dateTime = DateTime.utc(2024, 12, 3);

        await engine.dispose();

        final result = await engine.calculatePosition(object, location, dateTime);

        // Test fold method with failure
        final folded = result.fold(
          (value) => 'Success',
          (failure) => 'Failure: ${failure.message}',
        );

        expect(folded, startsWith('Failure:'));
        expect(folded, contains('disposed'));
      });
    });

    group('performance requirements (AC #3)', () {
      test('engine can handle multiple calculations quickly', () async {
        final objects = List.generate(
          10,
          (i) => CelestialObject(
            id: 'star$i',
            name: 'Star $i',
            type: CelestialObjectType.star,
            coordinates: EquatorialCoordinates(
              rightAscension: i * 30.0,
              declination: i * 10.0 - 45.0,
            ),
          ),
        );

        final location = Location(latitude: 40.0, longitude: -75.0);
        final dateTime = DateTime.utc(2024, 12, 3, 12, 0, 0);

        final stopwatch = Stopwatch()..start();

        for (final object in objects) {
          final result = await engine.calculatePosition(object, location, dateTime);
          expect(result.isSuccess, true);
        }

        stopwatch.stop();

        // 10 calculations should complete in reasonable time
        // Allow up to 500ms for 10 calculations (50ms per calculation)
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });
    });

    group('dispose', () {
      test('can be called multiple times safely', () async {
        await engine.dispose();
        await engine.dispose(); // Should not throw

        // Verify engine is disposed
        final result = await engine.calculatePosition(
          CelestialObject(
            id: 'test',
            name: 'Test',
            type: CelestialObjectType.star,
            coordinates: EquatorialCoordinates(
              rightAscension: 0.0,
              declination: 0.0,
            ),
          ),
          Location(latitude: 0.0, longitude: 0.0),
          DateTime.utc(2024, 12, 3),
        );

        expect(result.isFailure, true);
      });
    });
  });
}
