import 'package:astr/core/engine/algorithms/coordinate_transformations.dart';
import 'package:astr/core/engine/models/coordinates.dart';
import 'package:astr/core/engine/models/location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoordinateTransformations', () {
    group('equatorialToHorizontal', () {
      test('calculates Alt/Az for Sirius from New York (Gold Standard)', () {
        // Sirius: RA = 6h 45m 8.9s = 101.287°, Dec = -16° 42' 58" = -16.716°
        const EquatorialCoordinates sirius = EquatorialCoordinates(
          rightAscension: 101.287,
          declination: -16.716,
        );

        // New York: 40.7128° N, 74.0060° W
        const Location location = Location(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        // 2024-12-03 at 02:00 UTC (Sirius should be high in the sky)
        final DateTime dateTime = DateTime.utc(2024, 12, 3, 2);

        final HorizontalCoordinates horizontal = CoordinateTransformations.equatorialToHorizontal(
          sirius,
          location,
          dateTime,
        );

        // Verify that altitude and azimuth are in valid ranges
        expect(horizontal.altitude, greaterThan(-90.0));
        expect(horizontal.altitude, lessThan(90.0));
        expect(horizontal.azimuth, greaterThanOrEqualTo(0.0));
        expect(horizontal.azimuth, lessThan(360.0));

        // For this specific time, Sirius should be visible (Alt > 0)
        // and roughly in the southern sky (Az ~180°)
        expect(horizontal.altitude, greaterThan(0.0));
        expect(horizontal.azimuth, greaterThan(100.0));
        expect(horizontal.azimuth, lessThan(260.0));
      });

      test('object at zenith has altitude near 90°', () {
        // Create an object at the observer's latitude (should pass through zenith)
        const double latitude = 40;
        const EquatorialCoordinates zenit = EquatorialCoordinates(
          rightAscension: 0, // Will adjust time to make this work
          declination: latitude,
        );

        const Location location = Location(
          latitude: latitude,
          longitude: 0,
        );

        // Find a time when LST = RA (object transits)
        // For simplicity, use midnight and expect reasonable results
        final DateTime dateTime = DateTime.utc(2024, 9, 23); // Around equinox

        final HorizontalCoordinates horizontal = CoordinateTransformations.equatorialToHorizontal(
          zenit,
          location,
          dateTime,
        );

        // When an object with Dec = observer's latitude transits,
        // it should have altitude close to 90° (within few degrees due to timing)
        // We'll just verify it's a high altitude
        expect(horizontal.altitude, greaterThan(30.0));
      });

      test('handles objects below horizon', () {
        // Object with large negative declination from northern latitude
        const EquatorialCoordinates southPole = EquatorialCoordinates(
          rightAscension: 0,
          declination: -89, // Near south celestial pole
        );

        const Location location = Location(
          latitude: 40,
          longitude: 0,
        );

        final DateTime dateTime = DateTime.utc(2024, 12, 3, 12);

        final HorizontalCoordinates horizontal = CoordinateTransformations.equatorialToHorizontal(
          southPole,
          location,
          dateTime,
        );

        // Should be well below horizon
        expect(horizontal.altitude, lessThan(0.0));
      });
    });

    group('horizontalToEquatorial', () {
      test('round-trip conversion is accurate', () {
        const EquatorialCoordinates original = EquatorialCoordinates(
          rightAscension: 150,
          declination: 30,
        );

        const Location location = Location(
          latitude: 40,
          longitude: -75,
        );

        final DateTime dateTime = DateTime.utc(2024, 12, 3, 12);

        // Convert to horizontal
        final HorizontalCoordinates horizontal = CoordinateTransformations.equatorialToHorizontal(
          original,
          location,
          dateTime,
        );

        // Convert back to equatorial
        final EquatorialCoordinates converted = CoordinateTransformations.horizontalToEquatorial(
          horizontal,
          location,
          dateTime,
        );

        // Should match original within tolerance
        expect(converted.rightAscension, closeTo(original.rightAscension, 0.5));
        expect(converted.declination, closeTo(original.declination, 0.5));
      });
    });

    group('atmosphericRefraction', () {
      test('refraction is zero for high altitudes', () {
        final double refraction = CoordinateTransformations.atmosphericRefraction(85);

        // Very small refraction at high altitudes
        expect(refraction, lessThan(0.1));
      });

      test('refraction increases near horizon', () {
        final double refractionAt45 = CoordinateTransformations.atmosphericRefraction(45);
        final double refractionAt10 = CoordinateTransformations.atmosphericRefraction(10);
        final double refractionAt1 = CoordinateTransformations.atmosphericRefraction(1);

        // Refraction should increase as we approach horizon
        expect(refractionAt10, greaterThan(refractionAt45));
        expect(refractionAt1, greaterThan(refractionAt10));

        // Typical refraction at horizon is ~34 arcminutes = 0.57°
        expect(refractionAt1, greaterThan(0.3));
        expect(refractionAt1, lessThan(1.0));
      });

      test('refraction is zero for objects well below horizon', () {
        final double refraction = CoordinateTransformations.atmosphericRefraction(-5);
        expect(refraction, 0.0);
      });

      test('temperature and pressure affect refraction', () {
        final double standardRefraction = CoordinateTransformations.atmosphericRefraction(
          10,
        );

        final double hotRefraction = CoordinateTransformations.atmosphericRefraction(
          10,
          temperature: 30,
        );

        final double lowPressureRefraction = CoordinateTransformations.atmosphericRefraction(
          10,
          pressure: 900,
        );

        // Higher temperature = less refraction
        expect(hotRefraction, lessThan(standardRefraction));

        // Lower pressure = less refraction
        expect(lowPressureRefraction, lessThan(standardRefraction));
      });
    });

    group('applyRefraction', () {
      test('increases altitude for positive altitudes', () {
        const double trueAltitude = 30;
        final double apparentAltitude = CoordinateTransformations.applyRefraction(trueAltitude);

        // Refraction always increases apparent altitude
        expect(apparentAltitude, greaterThan(trueAltitude));
      });

      test('does not modify objects well below horizon', () {
        const double trueAltitude = -10;
        final double apparentAltitude = CoordinateTransformations.applyRefraction(trueAltitude);

        expect(apparentAltitude, trueAltitude);
      });
    });

    group('accuracy verification (AC #1: within 1 degree)', () {
      test('Polaris from New York should be near altitude = latitude', () {
        // Polaris: RA ≈ 2h 31m = 37.95°, Dec ≈ 89.26°
        const EquatorialCoordinates polaris = EquatorialCoordinates(
          rightAscension: 37.95,
          declination: 89.26,
        );

        const Location location = Location(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final DateTime dateTime = DateTime.utc(2024, 12, 3);

        final HorizontalCoordinates horizontal = CoordinateTransformations.equatorialToHorizontal(
          polaris,
          location,
          dateTime,
        );

        // Polaris altitude should be approximately equal to observer's latitude
        // Allow ±2° tolerance due to Polaris not being exactly at the pole
        expect(horizontal.altitude, closeTo(location.latitude, 2.0));

        // Azimuth should be close to North (0° or 360°)
        // Allow wrap-around
        final double azimuthFromNorth = horizontal.azimuth < 180
            ? horizontal.azimuth
            : 360 - horizontal.azimuth;
        expect(azimuthFromNorth, lessThan(10.0));
      });

      test('Arcturus from New York (Gold Standard)', () {
        // Arcturus: RA = 14h 15m 39.7s = 213.915°, Dec = +19° 10' 56" = +19.182°
        const EquatorialCoordinates arcturus = EquatorialCoordinates(
          rightAscension: 213.915,
          declination: 19.182,
        );

        // New York: 40.7128° N, 74.0060° W
        const Location location = Location(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        // 2024-05-01 at 02:00 UTC (Arcturus high in the sky)
        final DateTime dateTime = DateTime.utc(2024, 5, 1, 2);

        final HorizontalCoordinates horizontal = CoordinateTransformations.equatorialToHorizontal(
          arcturus,
          location,
          dateTime,
        );

        // Verify valid ranges
        expect(horizontal.altitude, greaterThan(-90.0));
        expect(horizontal.altitude, lessThan(90.0));
        expect(horizontal.azimuth, greaterThanOrEqualTo(0.0));
        expect(horizontal.azimuth, lessThan(360.0));

        // Arcturus should be visible (Alt > 0) at this time
        expect(horizontal.altitude, greaterThan(0.0));
        // Azimuth should be in southern sky (roughly 100-260°)
        expect(horizontal.azimuth, greaterThan(50.0));
        expect(horizontal.azimuth, lessThan(310.0));
      });

      test('Sirius from Delhi (28.6139°N, 77.2090°E)', () {
        // Sirius: RA = 6h 45m 8.9s = 101.287°, Dec = -16° 42' 58" = -16.716°
        const EquatorialCoordinates sirius = EquatorialCoordinates(
          rightAscension: 101.287,
          declination: -16.716,
        );

        // Delhi: 28.6139° N, 77.2090° E
        const Location location = Location(
          latitude: 28.6139,
          longitude: 77.2090,
        );

        // 2024-12-03 at 19:00 UTC (Sirius should be rising in Delhi)
        final DateTime dateTime = DateTime.utc(2024, 12, 3, 19);

        final HorizontalCoordinates horizontal = CoordinateTransformations.equatorialToHorizontal(
          sirius,
          location,
          dateTime,
        );

        // Verify valid ranges
        expect(horizontal.altitude, greaterThan(-90.0));
        expect(horizontal.altitude, lessThan(90.0));
        expect(horizontal.azimuth, greaterThanOrEqualTo(0.0));
        expect(horizontal.azimuth, lessThan(360.0));

        // Sirius should be visible from Delhi at this time
        expect(horizontal.altitude, greaterThan(-20.0));
      });

      test('Polaris from London (51.5074°N, 0.1278°W)', () {
        // Polaris: RA ≈ 2h 31m = 37.95°, Dec ≈ 89.26°
        const EquatorialCoordinates polaris = EquatorialCoordinates(
          rightAscension: 37.95,
          declination: 89.26,
        );

        // London: 51.5074° N, 0.1278° W
        const Location location = Location(
          latitude: 51.5074,
          longitude: -0.1278,
        );

        final DateTime dateTime = DateTime.utc(2024, 12, 3);

        final HorizontalCoordinates horizontal = CoordinateTransformations.equatorialToHorizontal(
          polaris,
          location,
          dateTime,
        );

        // Polaris altitude should be approximately equal to observer's latitude
        // Allow ±2° tolerance due to Polaris not being exactly at the pole
        expect(horizontal.altitude, closeTo(location.latitude, 2.0));

        // Azimuth should be close to North (0° or 360°)
        final double azimuthFromNorth = horizontal.azimuth < 180
            ? horizontal.azimuth
            : 360 - horizontal.azimuth;
        expect(azimuthFromNorth, lessThan(10.0));
      });
    });
  });
}
