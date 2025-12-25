import 'package:astr/core/engine/astro_engine.dart';
import 'package:astr/core/engine/models/celestial_object.dart';
import 'package:astr/core/engine/models/coordinates.dart';
import 'package:astr/core/engine/models/location.dart';
import 'package:astr/core/engine/models/result.dart';
import 'package:astr/core/engine/models/rise_set_times.dart';
import 'package:astr/core/error/failure.dart';
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
        const CelestialObject sirius = CelestialObject(
          id: 'HIP32349',
          name: 'Sirius',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 101.287,
            declination: -16.716,
          ),
          magnitude: -1.46,
        );

        const Location location = Location(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final DateTime dateTime = DateTime.utc(2024, 12, 3, 2);

        final Result<HorizontalCoordinates> result = await engine.calculatePosition(sirius, location, dateTime);

        expect(result.isSuccess, true);
        expect(result.value.altitude, greaterThan(-90.0));
        expect(result.value.altitude, lessThan(90.0));
        expect(result.value.azimuth, greaterThanOrEqualTo(0.0));
        expect(result.value.azimuth, lessThan(360.0));
      });

      test('calculates consistent positions for the same inputs', () async {
        const CelestialObject object = CelestialObject(
          id: 'test',
          name: 'Test Object',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 150,
            declination: 30,
          ),
        );

        const Location location = Location(latitude: 40, longitude: -75);
        final DateTime dateTime = DateTime.utc(2024, 12, 3, 12);

        final Result<HorizontalCoordinates> result1 = await engine.calculatePosition(object, location, dateTime);
        final Result<HorizontalCoordinates> result2 = await engine.calculatePosition(object, location, dateTime);

        expect(result1.isSuccess, true);
        expect(result2.isSuccess, true);
        expect(result1.value.altitude, closeTo(result2.value.altitude, 0.001));
        expect(result1.value.azimuth, closeTo(result2.value.azimuth, 0.001));
      });

      test('returns Failure when engine is disposed', () async {
        const CelestialObject object = CelestialObject(
          id: 'test',
          name: 'Test',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 0,
            declination: 0,
          ),
        );

        const Location location = Location(latitude: 0, longitude: 0);
        final DateTime dateTime = DateTime.utc(2024, 12, 3);

        await engine.dispose();

        final Result<HorizontalCoordinates> result = await engine.calculatePosition(object, location, dateTime);

        expect(result.isFailure, true);
        expect(result.failure.message, contains('disposed'));
      });

      test('position changes over time for the same object', () async {
        const CelestialObject object = CelestialObject(
          id: 'test',
          name: 'Test Object',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 150,
            declination: 30,
          ),
        );

        const Location location = Location(latitude: 40, longitude: -75);

        final DateTime time1 = DateTime.utc(2024, 12, 3, 12);
        final DateTime time2 = DateTime.utc(2024, 12, 3, 18);

        final Result<HorizontalCoordinates> result1 = await engine.calculatePosition(object, location, time1);
        final Result<HorizontalCoordinates> result2 = await engine.calculatePosition(object, location, time2);

        expect(result1.isSuccess, true);
        expect(result2.isSuccess, true);

        // Position should be different after 6 hours
        final double altDiff = (result1.value.altitude - result2.value.altitude).abs();
        final double azDiff = (result1.value.azimuth - result2.value.azimuth).abs();

        expect(altDiff, greaterThan(1.0)); // Should differ by more than 1 degree
      });
    });

    group('calculateRiseSet', () {
      test('returns Success with valid rise/set times', () async {
        const CelestialObject sirius = CelestialObject(
          id: 'HIP32349',
          name: 'Sirius',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 101.287,
            declination: -16.716,
          ),
          magnitude: -1.46,
        );

        const Location location = Location(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final DateTime date = DateTime.utc(2024, 12, 3);

        final Result<RiseSetTimes> result = await engine.calculateRiseSet(sirius, location, date);

        expect(result.isSuccess, true);
        expect(result.value.isCircumpolar, false);
        expect(result.value.neverRises, false);
        expect(result.value.riseTime, isNotNull);
        expect(result.value.transitTime, isNotNull);
        expect(result.value.setTime, isNotNull);
      });

      test('identifies circumpolar objects', () async {
        const CelestialObject polaris = CelestialObject(
          id: 'polaris',
          name: 'Polaris',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 37.95,
            declination: 89.26,
          ),
          magnitude: 2,
        );

        const Location location = Location(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final DateTime date = DateTime.utc(2024, 12, 3);

        final Result<RiseSetTimes> result = await engine.calculateRiseSet(polaris, location, date);

        expect(result.isSuccess, true);
        expect(result.value.isCircumpolar, true);
        expect(result.value.riseTime, isNull);
        expect(result.value.setTime, isNull);
      });

      test('identifies objects that never rise', () async {
        const CelestialObject southernObject = CelestialObject(
          id: 'southern',
          name: 'Southern Object',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 0,
            declination: -85,
          ),
        );

        const Location location = Location(
          latitude: 60,
          longitude: 0,
        );

        final DateTime date = DateTime.utc(2024, 12, 3);

        final Result<RiseSetTimes> result = await engine.calculateRiseSet(southernObject, location, date);

        expect(result.isSuccess, true);
        expect(result.value.neverRises, true);
        expect(result.value.riseTime, isNull);
        expect(result.value.setTime, isNull);
      });

      test('returns Failure when engine is disposed', () async {
        const CelestialObject object = CelestialObject(
          id: 'test',
          name: 'Test',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 0,
            declination: 0,
          ),
        );

        const Location location = Location(latitude: 0, longitude: 0);
        final DateTime date = DateTime.utc(2024, 12, 3);

        await engine.dispose();

        final Result<RiseSetTimes> result = await engine.calculateRiseSet(object, location, date);

        expect(result.isFailure, true);
        expect(result.failure.message, contains('disposed'));
      });
    });

    group('Result pattern usage', () {
      test('Success result provides value', () async {
        const CelestialObject object = CelestialObject(
          id: 'test',
          name: 'Test',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 0,
            declination: 0,
          ),
        );

        const Location location = Location(latitude: 0, longitude: 0);
        final DateTime dateTime = DateTime.utc(2024, 12, 3);

        final Result<HorizontalCoordinates> result = await engine.calculatePosition(object, location, dateTime);

        // Test fold method
        final String folded = result.fold(
          (HorizontalCoordinates value) => 'Success: ${value.altitude}',
          (Failure failure) => 'Failure: ${failure.message}',
        );

        expect(folded, startsWith('Success:'));
      });

      test('Failure result provides error information', () async {
        const CelestialObject object = CelestialObject(
          id: 'test',
          name: 'Test',
          type: CelestialObjectType.star,
          coordinates: EquatorialCoordinates(
            rightAscension: 0,
            declination: 0,
          ),
        );

        const Location location = Location(latitude: 0, longitude: 0);
        final DateTime dateTime = DateTime.utc(2024, 12, 3);

        await engine.dispose();

        final Result<HorizontalCoordinates> result = await engine.calculatePosition(object, location, dateTime);

        // Test fold method with failure
        final String folded = result.fold(
          (HorizontalCoordinates value) => 'Success',
          (Failure failure) => 'Failure: ${failure.message}',
        );

        expect(folded, startsWith('Failure:'));
        expect(folded, contains('disposed'));
      });
    });

    group('performance requirements (AC #3)', () {
      test('engine can handle multiple calculations quickly', () async {
        final List<CelestialObject> objects = List.generate(
          10,
          (int i) => CelestialObject(
            id: 'star$i',
            name: 'Star $i',
            type: CelestialObjectType.star,
            coordinates: EquatorialCoordinates(
              rightAscension: i * 30.0,
              declination: i * 10.0 - 45.0,
            ),
          ),
        );

        const Location location = Location(latitude: 40, longitude: -75);
        final DateTime dateTime = DateTime.utc(2024, 12, 3, 12);

        final Stopwatch stopwatch = Stopwatch()..start();

        for (final CelestialObject object in objects) {
          final Result<HorizontalCoordinates> result = await engine.calculatePosition(object, location, dateTime);
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
        final Result<HorizontalCoordinates> result = await engine.calculatePosition(
          const CelestialObject(
            id: 'test',
            name: 'Test',
            type: CelestialObjectType.star,
            coordinates: EquatorialCoordinates(
              rightAscension: 0,
              declination: 0,
            ),
          ),
          const Location(latitude: 0, longitude: 0),
          DateTime.utc(2024, 12, 3),
        );

        expect(result.isFailure, true);
      });
    });
  });
}
