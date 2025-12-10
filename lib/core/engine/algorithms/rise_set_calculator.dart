import 'dart:math' as math;
import 'package:astr/core/engine/algorithms/coordinate_transformations.dart';
import 'package:astr/core/engine/algorithms/time_utils.dart';
import 'package:astr/core/engine/models/coordinates.dart';
import 'package:astr/core/engine/models/location.dart';
import 'package:astr/core/engine/models/rise_set_times.dart';

/// Calculates rise, transit, and set times for celestial objects
/// Based on Jean Meeus "Astronomical Algorithms", Chapter 15
class RiseSetCalculator {
  /// Standard altitude for rise/set calculations (accounts for refraction and semi-diameter)
  /// -0.5667 degrees for stars and planets
  /// -0.8333 degrees for the Sun (adds solar semi-diameter)
  /// +0.125 degrees for the Moon (subtracts lunar semi-diameter)
  static const double standardAltitude = -0.5667;

  /// Calculates rise, transit, and set times for a celestial object
  ///
  /// [coordinates] The equatorial coordinates of the object (RA/Dec)
  /// [location] Observer's geographic location
  /// [date] The date for which to calculate (time component is ignored, uses local midnight)
  /// [altitude] The altitude threshold for rise/set (default: standard refraction)
  ///
  /// Returns [RiseSetTimes] with rise, transit, and set times
  static RiseSetTimes calculateRiseSet(
    EquatorialCoordinates coordinates,
    Location location,
    DateTime date, {
    double altitude = standardAltitude,
  }) {
    final double ra = coordinates.rightAscension;
    final double dec = coordinates.declination;
    final double lat = location.latitude;
    final double lon = location.longitude;

    // Check for circumpolar or never rising conditions
    final CircumpolarCheck check = _checkCircumpolar(dec, lat, altitude);
    if (check.isCircumpolar) {
      // Calculate only transit time for circumpolar objects
      final DateTime? transit = _calculateTransit(ra, lon, date);
      return RiseSetTimes(
        transitTime: transit,
        isCircumpolar: true,
      );
    }
    if (check.neverRises) {
      return RiseSetTimes(neverRises: true);
    }

    // Calculate approximate hour angles for rise and set
    final double h0 = _calculateHourAngle(dec, lat, altitude);

    // Calculate transit time (when object crosses meridian)
    final DateTime? transit = _calculateTransit(ra, lon, date);
    if (transit == null) {
      // Shouldn't happen, but handle gracefully
      return RiseSetTimes(neverRises: true);
    }

    // Calculate rise and set times relative to transit
    final Duration riseOffset = Duration(
      milliseconds: ((-h0 / 360.0) * 24.0 * 60.0 * 60.0 * 1000.0).round(),
    );
    final Duration setOffset = Duration(
      milliseconds: ((h0 / 360.0) * 24.0 * 60.0 * 60.0 * 1000.0).round(),
    );

    final DateTime riseTime = transit.add(riseOffset);
    final DateTime setTime = transit.add(setOffset);

    return RiseSetTimes(
      riseTime: riseTime,
      transitTime: transit,
      setTime: setTime,
    );
  }

  /// Checks if an object is circumpolar or never rises
  static CircumpolarCheck _checkCircumpolar(
    double declination,
    double latitude,
    double altitude,
  ) {
    final double latRad = TimeUtils.degreesToRadians(latitude);
    final double decRad = TimeUtils.degreesToRadians(declination);
    final double altRad = TimeUtils.degreesToRadians(altitude);

    // Calculate the limiting declination
    // For circumpolar: Dec > 90° - Lat + altitude
    // For never rising: Dec < -90° + Lat + altitude
    final double cosH0 = (math.sin(altRad) - math.sin(latRad) * math.sin(decRad)) /
        (math.cos(latRad) * math.cos(decRad));

    if (cosH0 > 1.0) {
      // Object never rises above the horizon
      return CircumpolarCheck(neverRises: true);
    } else if (cosH0 < -1.0) {
      // Object is circumpolar (always above horizon)
      return CircumpolarCheck(isCircumpolar: true);
    }

    return CircumpolarCheck();
  }

  /// Calculates the hour angle at rise/set
  ///
  /// Returns the hour angle in degrees
  static double _calculateHourAngle(
    double declination,
    double latitude,
    double altitude,
  ) {
    final double latRad = TimeUtils.degreesToRadians(latitude);
    final double decRad = TimeUtils.degreesToRadians(declination);
    final double altRad = TimeUtils.degreesToRadians(altitude);

    // cos(H0) = (sin(h0) - sin(lat) * sin(dec)) / (cos(lat) * cos(dec))
    final double cosH0 = (math.sin(altRad) - math.sin(latRad) * math.sin(decRad)) /
        (math.cos(latRad) * math.cos(decRad));

    // Clamp to valid range (should be guaranteed by circumpolar check, but just in case)
    final double clampedCosH0 = cosH0.clamp(-1.0, 1.0);

    final double h0 = math.acos(clampedCosH0);
    return TimeUtils.radiansToDegrees(h0);
  }

  /// Calculates the transit time (when object crosses the meridian)
  ///
  /// [ra] Right ascension in degrees
  /// [longitude] Observer's longitude in degrees (East positive)
  /// [date] The date (local midnight)
  ///
  /// Returns the UTC DateTime of transit
  static DateTime? _calculateTransit(
    double ra,
    double longitude,
    DateTime date,
  ) {
    // Get midnight UTC for the given date
    final DateTime midnight = DateTime.utc(date.year, date.month, date.day);

    // Calculate GMST at midnight
    final double gmst0 = TimeUtils.greenwichMeanSiderealTime(midnight);

    // Calculate the transit time in decimal hours
    // Transit occurs when LST = RA
    // LST = GMST + longitude
    // So: GMST + longitude + (sidereal_rate * hours) = RA
    //
    // Approximate transit hour:
    // m0 = (RA - GMST0 - longitude) / 360  (in days)
    double m0 = (ra - gmst0 - longitude) / 360.0;

    // Normalize to 0-1 range (fraction of a day)
    m0 = m0 % 1.0;
    if (m0 < 0) m0 += 1.0;

    // Convert to DateTime
    final Duration offset = Duration(
      milliseconds: (m0 * 24.0 * 60.0 * 60.0 * 1000.0).round(),
    );

    return midnight.add(offset);
  }

  /// Calculates more accurate rise/set times using iterative refinement
  ///
  /// This method improves upon the approximate calculation by accounting for
  /// the object's motion and the Earth's rotation more precisely.
  ///
  /// Use this for higher accuracy when needed (within 1 minute)
  static RiseSetTimes calculateRiseSetIterative(
    EquatorialCoordinates coordinates,
    Location location,
    DateTime date, {
    double altitude = standardAltitude,
    int maxIterations = 3,
  }) {
    // Start with approximate times
    RiseSetTimes approximate = calculateRiseSet(
      coordinates,
      location,
      date,
      altitude: altitude,
    );

    if (approximate.isCircumpolar || approximate.neverRises) {
      return approximate;
    }

    // Refine rise and set times iteratively
    DateTime? refinedRise = approximate.riseTime;
    DateTime? refinedSet = approximate.setTime;

    for (int i = 0; i < maxIterations; i++) {
      if (refinedRise != null) {
        refinedRise = _refineTime(
          coordinates,
          location,
          refinedRise,
          altitude,
          isRising: true,
        );
      }

      if (refinedSet != null) {
        refinedSet = _refineTime(
          coordinates,
          location,
          refinedSet,
          altitude,
          isRising: false,
        );
      }
    }

    return RiseSetTimes(
      riseTime: refinedRise,
      transitTime: approximate.transitTime,
      setTime: refinedSet,
      isCircumpolar: false,
      neverRises: false,
    );
  }

  /// Refines a rise or set time using the actual calculated altitude
  static DateTime _refineTime(
    EquatorialCoordinates coordinates,
    Location location,
    DateTime approximateTime,
    double targetAltitude,
    {required bool isRising,
  }) {
    // Calculate actual horizontal coordinates at approximate time
    final HorizontalCoordinates horizontal = CoordinateTransformations.equatorialToHorizontal(
      coordinates,
      location,
      approximateTime,
    );

    // Calculate altitude error
    final double altitudeError = horizontal.altitude - targetAltitude;

    // If error is very small, we're done
    if (altitudeError.abs() < 0.01) {
      return approximateTime;
    }

    // Estimate time correction
    // Typical altitude change rate is ~15 degrees per hour near horizon
    // But this varies with declination and latitude
    final double estimatedRate = 15.0; // degrees per hour
    final double timeCorrection = -altitudeError / estimatedRate; // hours

    // Apply correction
    final Duration correction = Duration(
      milliseconds: (timeCorrection * 60.0 * 60.0 * 1000.0).round(),
    );

    return approximateTime.add(correction);
  }
}

/// Helper class to represent circumpolar check results
class CircumpolarCheck {
  final bool isCircumpolar;
  final bool neverRises;

  const CircumpolarCheck({
    this.isCircumpolar = false,
    this.neverRises = false,
  });
}
