
import 'dart:math';
import 'package:astr/core/engine/algorithms/coordinate_transformations.dart';
import 'package:astr/core/engine/algorithms/time_utils.dart';
import 'package:astr/core/engine/models/coordinates.dart';
import 'package:astr/core/engine/models/location.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweph/sweph.dart';

void main() {
  group('Astro Audit - Dart Native Verifications', () {
    
    // 1. Julian Date
    test('Julian Date - Standard Epochs', () {
      // Source: NASA / USNO / Meeus
      // J2000.0: 2000 Jan 1, 12:00 UTC -> 2451545.0
      expect(
        TimeUtils.dateTimeToJulianDate(DateTime.utc(2000, 1, 1, 12)),
        closeTo(2451545.0, 0.000001),
        reason: 'J2000.0 Mismatch'
      );

      // Unix Epoch: 1970 Jan 1, 00:00 UTC -> 2440587.5
      expect(
        TimeUtils.dateTimeToJulianDate(DateTime.utc(1970, 1)),
        closeTo(2440587.5, 0.000001),
        reason: 'Unix Epoch Mismatch'
      );
      
      // 2024 Jan 1, 00:00 UTC -> 2460310.5
      expect(
         TimeUtils.dateTimeToJulianDate(DateTime.utc(2024, 1)),
         closeTo(2460310.5, 0.000001),
         reason: '2024 Start Mismatch'
      );
    });

    test('GMST Check - Specific Date', () {
       // 2024 Jan 1, 00:00:00 UTC
       // Expected GMST: 6h 40m 10s approx = 100.04 degrees.
       // Let's refine:
       // JD = 2460310.5
       // T = 0.23998631
       // GMST = 100.46061837 + 36000.77005361 * T + ... (Meeus 12.2) 
       // Note: Meeus 12.2 is valid for Mean Sidereal Time at Greenwich at 0h UT.
       // TimeUtils.greenwichMeanSiderealTime uses the linear combination form.
       
       final DateTime time = DateTime.utc(2024, 1);
       final double gmst = TimeUtils.greenwichMeanSiderealTime(time);
       print('GMST (2024-01-01): $gmst');
       
       // Allow 0.5 degree leeway for simple formula diffs, but usually should match < 0.1
       expect(gmst, closeTo(100.0, 0.5), reason: 'GMST should be approx 6h 40m');
    });

    // 2. Coordinate Transformations - Geometric Logic Checks
    // These tests do not rely on fractional LST accuracy, but verify the Geometry.
    
    test('Geometric Audit: Meridian Transit (Due South)', () {
      // Scenario: Object is exactly on the Meridian (RA = LST).
      // Location: Equator (0,0) for simplicity.
      // Object: Declination 0 (Celestial Equator).
      // Expected: Altitude 90 (Zenith), Azimuth Indeterminate or defined as S/N.
      
      // Let's settle for Declination -10 (South of Zenith).
      // At Lat 0, Dec -10. Object should be due South (Az 180) at Altitude 80.
      
      const double lat = 0;
      const double lon = 0;
      final DateTime time = DateTime.utc(2024, 1); // Arbitrary time
      
      // 1. Calculate LST for this time/loc
      final double lst = TimeUtils.localSiderealTime(time, lon);
      
      // 2. Set Object RA = LST (Hour Angle = 0)
      final double ra = lst;
      const double dec = -10;
      
      final HorizontalCoordinates horiz = CoordinateTransformations.equatorialToHorizontal(
        EquatorialCoordinates(rightAscension: ra, declination: dec),
        const Location(latitude: lat, longitude: lon),
        time
      );
      
      print('Meridian Check (South): Alt=${horiz.altitude}, Az=${horiz.azimuth}');
      
      // Expect Azimuth 180 (South)
      // Note: If algorithm uses North = 0, South = 180.
      expect(horiz.azimuth, closeTo(180, 0.1), reason: 'Meridian Transit should be Due South (180)');
      expect(horiz.altitude, closeTo(80, 0.1), reason: 'Altitude should be 90 - |Lat - Dec|');
    });

    test('Geometric Audit: Meridian Transit (Due North)', () {
      // Scenario: Object transit North of Zenith.
      // Lat: 0. Dec: +10.
      // Should be Azimuth 0 (North), Altitude 80.
      
      const double lat = 0;
      const double lon = 0;
      final DateTime time = DateTime.utc(2024, 1);
      final double lst = TimeUtils.localSiderealTime(time, lon);
      
      final double ra = lst;
      const double dec = 10;
      
      final HorizontalCoordinates horiz = CoordinateTransformations.equatorialToHorizontal(
        EquatorialCoordinates(rightAscension: ra, declination: dec),
        const Location(latitude: lat, longitude: lon),
        time
      );

       print('Meridian Check (North): Alt=${horiz.altitude}, Az=${horiz.azimuth}');

       expect(horiz.azimuth, closeTo(0, 0.1), reason: 'Meridian Transit North should be Due North (0)'); // Or 360
       expect(horiz.altitude, closeTo(80, 0.1));
    });

    test('Geometric Audit: Setting Force (West)', () {
      // Scenario: Object is setting due West.
      // Lat 0. Dec 0.
      // Hour Angle should be 6h (90 deg).
      // RA = LST - 90.
      
      const double lat = 0;
      const double lon = 0;
      final DateTime time = DateTime.utc(2024, 1);
      final double lst = TimeUtils.localSiderealTime(time, lon);
      
      final double ra = TimeUtils.normalizeDegrees(lst - 90);
      const double dec = 0;
      
      final HorizontalCoordinates horiz = CoordinateTransformations.equatorialToHorizontal(
        EquatorialCoordinates(rightAscension: ra, declination: dec),
        const Location(latitude: lat, longitude: lon),
        time
      );
      
      print('West Check: Alt=${horiz.altitude}, Az=${horiz.azimuth}');
      
      expect(horiz.altitude, closeTo(0, 0.1), reason: 'Should be on Horizon');
      expect(horiz.azimuth, closeTo(270, 0.1), reason: 'Should be Due West (270)');
    });
    
    test('Geometric Audit: Rising Force (East)', () {
      // Scenario: Object is rising due East.
      // Lat 0. Dec 0.
      // Hour Angle should be -6h (270 deg).
      // RA = LST + 90.
      
      const double lat = 0;
      const double lon = 0;
      final DateTime time = DateTime.utc(2024, 1);
      final double lst = TimeUtils.localSiderealTime(time, lon);
      
      final double ra = TimeUtils.normalizeDegrees(lst + 90);
      const double dec = 0;
      
      final HorizontalCoordinates horiz = CoordinateTransformations.equatorialToHorizontal(
        EquatorialCoordinates(rightAscension: ra, declination: dec),
        const Location(latitude: lat, longitude: lon),
        time
      );
      
      print('East Check: Alt=${horiz.altitude}, Az=${horiz.azimuth}');
      
      expect(horiz.altitude, closeTo(0, 0.1), reason: 'Should be on Horizon');
      expect(horiz.azimuth, closeTo(90, 0.1), reason: 'Should be Due East (90)');
    });
    
    test('Polaris Check (Northern Hemisphere)', () {
      const double lat = 45;
      const double lon = 0;
      final DateTime time = DateTime.utc(2024, 1); 
      
      // Polaris approx J2000
      const double ra = 37.95; // 2h 31m
      const double dec = 89.26;
      
      final HorizontalCoordinates horiz = CoordinateTransformations.equatorialToHorizontal(
        const EquatorialCoordinates(rightAscension: ra, declination: dec),
        const Location(latitude: lat, longitude: lon),
        time
      );
      
      print('Polaris Check: Alt=${horiz.altitude}, Az=${horiz.azimuth}');
      // Should be near North (0/360) and Altitude ~Lat (45)
      expect(horiz.altitude, closeTo(45, 2.0)); // Allowing large leeway due to LST rotation
      // Azimuth depends on LST but should be within circle around North Pole.
      // 89.26 dec = 0.74 deg from pole.
      // So Altitude 45 +/- 0.74.
      // Azimuth can be anything depending on hour angle.
      // But verifying it doesn't crash or flip to South.
    });

    test('South Pole Check (Southern Hemisphere)', () {
      const double lat = -45; // South
      const double lon = 0;
      final DateTime time = DateTime.utc(2024, 1); 
      
      // Sigma Octantis (South Star) approx
      const double ra = 315;
      const double dec = -89;
      
      final HorizontalCoordinates horiz = CoordinateTransformations.equatorialToHorizontal(
        const EquatorialCoordinates(rightAscension: ra, declination: dec),
        const Location(latitude: lat, longitude: lon),
        time
      );
      
      print('South Pole Check: Alt=${horiz.altitude}, Az=${horiz.azimuth}');
      // Should be near South (180) and Altitude 45.
      expect(horiz.altitude, closeTo(45, 2.0));
      // Azimuth within circle around South Pole (180).
    });

  });
}
