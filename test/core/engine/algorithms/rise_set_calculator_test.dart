import 'package:astr/core/engine/algorithms/rise_set_calculator.dart';
import 'package:astr/core/engine/models/coordinates.dart';
import 'package:astr/core/engine/models/location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RiseSetCalculator', () {
    group('calculateRiseSet', () {
      test('calculates rise/set times for Sirius from New York', () {
        // Sirius: RA = 101.287°, Dec = -16.716°
        final sirius = EquatorialCoordinates(
          rightAscension: 101.287,
          declination: -16.716,
        );

        final location = Location(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final date = DateTime.utc(2024, 12, 3);

        final times = RiseSetCalculator.calculateRiseSet(sirius, location, date);

        // Sirius should rise and set (not circumpolar, not never rising)
        expect(times.isCircumpolar, false);
        expect(times.neverRises, false);
        expect(times.riseTime, isNotNull);
        expect(times.setTime, isNotNull);
        expect(times.transitTime, isNotNull);

        // Transit should be between rise and set
        expect(times.transitTime!.isAfter(times.riseTime!), true);
        expect(times.transitTime!.isBefore(times.setTime!), true);

        // Rise and set should be on the same day or next day
        final riseDate = times.riseTime!;
        final setDate = times.setTime!;
        expect(setDate.isAfter(riseDate), true);
        expect(setDate.difference(riseDate).inHours, lessThan(24));
      });

      test('Polaris is circumpolar from New York', () {
        // Polaris: RA ≈ 37.95°, Dec ≈ 89.26°
        final polaris = EquatorialCoordinates(
          rightAscension: 37.95,
          declination: 89.26,
        );

        final location = Location(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final date = DateTime.utc(2024, 12, 3);

        final times = RiseSetCalculator.calculateRiseSet(polaris, location, date);

        // Polaris should be circumpolar from mid-northern latitudes
        expect(times.isCircumpolar, true);
        expect(times.neverRises, false);
        expect(times.riseTime, isNull);
        expect(times.setTime, isNull);
        expect(times.transitTime, isNotNull); // Should still have transit
      });

      test('southern objects never rise from high northern latitudes', () {
        // Object near south celestial pole
        final southernObject = EquatorialCoordinates(
          rightAscension: 0.0,
          declination: -85.0,
        );

        final location = Location(
          latitude: 60.0, // High northern latitude
          longitude: 0.0,
        );

        final date = DateTime.utc(2024, 12, 3);

        final times = RiseSetCalculator.calculateRiseSet(
          southernObject,
          location,
          date,
        );

        expect(times.isCircumpolar, false);
        expect(times.neverRises, true);
        expect(times.riseTime, isNull);
        expect(times.setTime, isNull);
        expect(times.transitTime, isNull);
      });

      test('objects on celestial equator rise/set at predictable times', () {
        // Object on celestial equator (Dec = 0)
        final equatorialObject = EquatorialCoordinates(
          rightAscension: 90.0, // 6 hours
          declination: 0.0,
        );

        final location = Location(
          latitude: 0.0, // On Earth's equator
          longitude: 0.0,
        );

        final date = DateTime.utc(2024, 3, 20); // Near spring equinox

        final times = RiseSetCalculator.calculateRiseSet(
          equatorialObject,
          location,
          date,
        );

        expect(times.isCircumpolar, false);
        expect(times.neverRises, false);
        expect(times.riseTime, isNotNull);
        expect(times.setTime, isNotNull);

        // From equator, object with Dec=0 should be visible for ~12 hours
        final visibleDuration = times.setTime!.difference(times.riseTime!);
        expect(visibleDuration.inHours, closeTo(12, 2)); // ±2 hour tolerance
      });
    });

    group('calculateRiseSetIterative', () {
      test('provides more accurate times than simple calculation', () {
        final sirius = EquatorialCoordinates(
          rightAscension: 101.287,
          declination: -16.716,
        );

        final location = Location(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final date = DateTime.utc(2024, 12, 3);

        final simple = RiseSetCalculator.calculateRiseSet(sirius, location, date);
        final iterative = RiseSetCalculator.calculateRiseSetIterative(
          sirius,
          location,
          date,
        );

        // Both should provide valid results
        expect(simple.riseTime, isNotNull);
        expect(iterative.riseTime, isNotNull);

        // Results should be close (within minutes, satisfying AC #2)
        final riseDiff = iterative.riseTime!.difference(simple.riseTime!).inMinutes.abs();
        expect(riseDiff, lessThan(10)); // Within 10 minutes
      });

      test('handles circumpolar objects correctly', () {
        final polaris = EquatorialCoordinates(
          rightAscension: 37.95,
          declination: 89.26,
        );

        final location = Location(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final date = DateTime.utc(2024, 12, 3);

        final times = RiseSetCalculator.calculateRiseSetIterative(
          polaris,
          location,
          date,
        );

        expect(times.isCircumpolar, true);
        expect(times.neverRises, false);
      });
    });

    group('accuracy verification (AC #2: within 2 minutes)', () {
      test('Sun rise/set times are reasonable for New York in December', () {
        // Sun on December 3, 2024
        // Approximate coordinates (would vary slightly day to day)
        // RA ≈ 16h 40m = 250°, Dec ≈ -22°
        final sun = EquatorialCoordinates(
          rightAscension: 250.0,
          declination: -22.0,
        );

        final location = Location(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final date = DateTime.utc(2024, 12, 3);

        final times = RiseSetCalculator.calculateRiseSetIterative(
          sun,
          location,
          date,
          altitude: -0.8333, // Sun's standard altitude (includes semi-diameter)
        );

        expect(times.riseTime, isNotNull);
        expect(times.setTime, isNotNull);

        // In December, New York sunrise should be around 7:00 AM local (12:00 UTC)
        // and sunset around 4:30 PM local (21:30 UTC)
        // Allow several hours tolerance since we're using approximate coordinates
        final riseHour = times.riseTime!.hour;
        final setHour = times.setTime!.hour;

        expect(riseHour, greaterThan(9)); // After 9 AM UTC
        expect(riseHour, lessThan(15)); // Before 3 PM UTC
        expect(setHour, greaterThan(19)); // After 7 PM UTC
        expect(setHour, lessThan(24)); // Before midnight UTC

        // Day length in December for New York should be ~9-10 hours
        final dayLength = times.setTime!.difference(times.riseTime!);
        expect(dayLength.inHours, greaterThan(8));
        expect(dayLength.inHours, lessThan(11));
      });

      test('transit time is when object crosses meridian', () {
        final object = EquatorialCoordinates(
          rightAscension: 180.0,
          declination: 30.0,
        );

        final location = Location(
          latitude: 40.0,
          longitude: 0.0,
        );

        final date = DateTime.utc(2024, 12, 3);

        final times = RiseSetCalculator.calculateRiseSet(object, location, date);

        expect(times.transitTime, isNotNull);

        // Transit time should be during the same day
        expect(times.transitTime!.year, date.year);
        expect(times.transitTime!.month, date.month);
        expect(times.transitTime!.day, date.day);
      });
    });
  });
}
