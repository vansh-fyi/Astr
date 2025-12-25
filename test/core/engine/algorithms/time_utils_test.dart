import 'package:astr/core/engine/algorithms/time_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeUtils', () {
    group('dateTimeToJulianDate', () {
      test('converts J2000.0 epoch correctly', () {
        // J2000.0 is January 1, 2000 at 12:00:00 TT
        // Which is approximately 2000-01-01 11:58:56 UTC
        final DateTime dateTime = DateTime.utc(2000, 1, 1, 12);
        final double jd = TimeUtils.dateTimeToJulianDate(dateTime);

        // Expected JD for J2000.0 is 2451545.0
        expect(jd, closeTo(2451545.0, 0.001));
      });

      test('converts year 2024 correctly', () {
        final DateTime dateTime = DateTime.utc(2024, 12, 3);
        final double jd = TimeUtils.dateTimeToJulianDate(dateTime);

        // Expected JD (calculated using external tools)
        // 2024-12-03 00:00:00 UTC = JD 2460647.5
        expect(jd, closeTo(2460647.5, 0.001));
      });

      test('handles fractional days correctly', () {
        final DateTime dateTime = DateTime.utc(2024, 12, 3, 12);
        final double jd = TimeUtils.dateTimeToJulianDate(dateTime);

        // 12 hours = 0.5 days
        expect(jd, closeTo(2460648.0, 0.001));
      });
    });

    group('julianDateToDateTime', () {
      test('converts J2000.0 epoch correctly', () {
        final DateTime dateTime = TimeUtils.julianDateToDateTime(2451545);

        expect(dateTime.year, 2000);
        expect(dateTime.month, 1);
        expect(dateTime.day, 1);
        expect(dateTime.hour, 12);
      });

      test('round-trip conversion is accurate', () {
        final DateTime original = DateTime.utc(2024, 6, 15, 18, 30, 45);
        final double jd = TimeUtils.dateTimeToJulianDate(original);
        final DateTime converted = TimeUtils.julianDateToDateTime(jd);

        expect(converted.year, original.year);
        expect(converted.month, original.month);
        expect(converted.day, original.day);
        expect(converted.hour, original.hour);
        expect(converted.minute, original.minute);
        // Seconds may have minor precision loss
        expect(converted.second, closeTo(original.second, 1));
      });
    });

    group('julianCenturiesSinceJ2000', () {
      test('returns 0 for J2000.0', () {
        final double t = TimeUtils.julianCenturiesSinceJ2000(2451545);
        expect(t, closeTo(0.0, 0.00001));
      });

      test('calculates century correctly', () {
        // One Julian century = 36525 days
        const double jd = 2451545.0 + 36525.0;
        final double t = TimeUtils.julianCenturiesSinceJ2000(jd);
        expect(t, closeTo(1.0, 0.00001));
      });
    });

    group('greenwichMeanSiderealTime', () {
      test('calculates GMST for known date', () {
        // Test case from Meeus Example 12.a
        // 1987 April 10, 0h UT
        final DateTime dateTime = DateTime.utc(1987, 4, 10);
        final double gmst = TimeUtils.greenwichMeanSiderealTime(dateTime);

        // Expected GMST: 13h 10m 46.3668s = 197.6932° (approximately)
        // Allow ±1 degree tolerance for this test
        expect(gmst, closeTo(197.69, 1.0));
      });

      test('GMST is in valid range', () {
        final DateTime dateTime = DateTime.utc(2024, 12, 3, 12);
        final double gmst = TimeUtils.greenwichMeanSiderealTime(dateTime);

        expect(gmst, greaterThanOrEqualTo(0.0));
        expect(gmst, lessThan(360.0));
      });
    });

    group('localSiderealTime', () {
      test('adds longitude to GMST correctly', () {
        final DateTime dateTime = DateTime.utc(2024, 12, 3);
        const double longitude = 45; // 45° East

        final double gmst = TimeUtils.greenwichMeanSiderealTime(dateTime);
        final double lst = TimeUtils.localSiderealTime(dateTime, longitude);

        // LST should be GMST + longitude (normalized)
        final double expected = (gmst + longitude) % 360.0;
        expect(lst, closeTo(expected, 0.01));
      });

      test('LST is in valid range', () {
        final DateTime dateTime = DateTime.utc(2024, 12, 3, 12);
        final double lst = TimeUtils.localSiderealTime(dateTime, -74); // New York

        expect(lst, greaterThanOrEqualTo(0.0));
        expect(lst, lessThan(360.0));
      });
    });

    group('angle normalization', () {
      test('normalizeDegrees handles positive values', () {
        expect(TimeUtils.normalizeDegrees(45), 45.0);
        expect(TimeUtils.normalizeDegrees(360), 0.0);
        expect(TimeUtils.normalizeDegrees(405), 45.0);
      });

      test('normalizeDegrees handles negative values', () {
        expect(TimeUtils.normalizeDegrees(-45), 315.0);
        expect(TimeUtils.normalizeDegrees(-360), 0.0);
        expect(TimeUtils.normalizeDegrees(-405), 315.0);
      });

      test('normalizeDegreesSymmetric keeps range [-180, 180)', () {
        expect(TimeUtils.normalizeDegreesSymmetric(45), 45.0);
        expect(TimeUtils.normalizeDegreesSymmetric(180), -180.0);
        expect(TimeUtils.normalizeDegreesSymmetric(-45), -45.0);
        expect(TimeUtils.normalizeDegreesSymmetric(270), -90.0);
      });
    });

    group('angle conversions', () {
      test('degreesToRadians converts correctly', () {
        expect(TimeUtils.degreesToRadians(0), 0.0);
        expect(TimeUtils.degreesToRadians(180), closeTo(3.14159265, 0.00001));
        expect(TimeUtils.degreesToRadians(90), closeTo(1.57079633, 0.00001));
      });

      test('radiansToDegrees converts correctly', () {
        expect(TimeUtils.radiansToDegrees(0), 0.0);
        expect(TimeUtils.radiansToDegrees(3.14159265), closeTo(180.0, 0.00001));
        expect(TimeUtils.radiansToDegrees(1.57079633), closeTo(90.0, 0.00001));
      });

      test('round-trip conversion is accurate', () {
        const double degrees = 123.456;
        final double radians = TimeUtils.degreesToRadians(degrees);
        final double backToDegrees = TimeUtils.radiansToDegrees(radians);
        expect(backToDegrees, closeTo(degrees, 0.00001));
      });
    });
  });
}
