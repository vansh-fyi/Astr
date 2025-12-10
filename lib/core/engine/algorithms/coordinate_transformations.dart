import 'dart:math' as math;
import 'package:astr/core/engine/algorithms/time_utils.dart';
import 'package:astr/core/engine/models/coordinates.dart';
import 'package:astr/core/engine/models/location.dart';

/// Coordinate transformation algorithms for astronomical calculations
/// Based on Jean Meeus "Astronomical Algorithms"
class CoordinateTransformations {
  /// Converts Equatorial coordinates (RA/Dec) to Horizontal coordinates (Alt/Az)
  ///
  /// [equatorial] The equatorial coordinates (RA in degrees, Dec in degrees)
  /// [location] Observer's geographic location
  /// [dateTime] The time of observation (UTC)
  ///
  /// Returns the horizontal coordinates (Altitude and Azimuth)
  ///
  /// Algorithm from Meeus, Chapter 13
  static HorizontalCoordinates equatorialToHorizontal(
    EquatorialCoordinates equatorial,
    Location location,
    DateTime dateTime,
  ) {
    // Calculate Local Sidereal Time
    final double lst = TimeUtils.localSiderealTime(dateTime, location.longitude);

    // Calculate Hour Angle (in degrees)
    // H = LST - RA
    double hourAngle = lst - equatorial.rightAscension;
    hourAngle = TimeUtils.normalizeDegreesSymmetric(hourAngle);

    // Convert to radians for calculations
    final double h = TimeUtils.degreesToRadians(hourAngle);
    final double dec = TimeUtils.degreesToRadians(equatorial.declination);
    final double lat = TimeUtils.degreesToRadians(location.latitude);

    // Calculate Altitude
    // sin(Alt) = sin(Dec) * sin(Lat) + cos(Dec) * cos(Lat) * cos(H)
    final double sinAlt = math.sin(dec) * math.sin(lat) +
        math.cos(dec) * math.cos(lat) * math.cos(h);
    final double altitude = math.asin(sinAlt);

    // Calculate Azimuth
    // cos(Az) = (sin(Dec) - sin(Alt) * sin(Lat)) / (cos(Alt) * cos(Lat))
    // sin(Az) = -sin(H) * cos(Dec) / cos(Alt)
    final double cosAlt = math.cos(altitude);
    final double cosAz = (math.sin(dec) - sinAlt * math.sin(lat)) /
        (cosAlt * math.cos(lat));
    final double sinAz = -math.sin(h) * math.cos(dec) / cosAlt;

    // Use atan2 to get the correct quadrant
    double azimuth = math.atan2(sinAz, cosAz);

    // Convert to degrees and normalize to 0-360 (North = 0, East = 90)
    azimuth = TimeUtils.radiansToDegrees(azimuth);
    azimuth = TimeUtils.normalizeDegrees(azimuth);

    return HorizontalCoordinates(
      altitude: TimeUtils.radiansToDegrees(altitude),
      azimuth: azimuth,
    );
  }

  /// Converts Horizontal coordinates (Alt/Az) to Equatorial coordinates (RA/Dec)
  ///
  /// [horizontal] The horizontal coordinates (Altitude and Azimuth in degrees)
  /// [location] Observer's geographic location
  /// [dateTime] The time of observation (UTC)
  ///
  /// Returns the equatorial coordinates (RA and Dec)
  static EquatorialCoordinates horizontalToEquatorial(
    HorizontalCoordinates horizontal,
    Location location,
    DateTime dateTime,
  ) {
    // Convert to radians
    final double alt = TimeUtils.degreesToRadians(horizontal.altitude);
    final double az = TimeUtils.degreesToRadians(horizontal.azimuth);
    final double lat = TimeUtils.degreesToRadians(location.latitude);

    // Calculate Declination
    // sin(Dec) = sin(Alt) * sin(Lat) + cos(Alt) * cos(Lat) * cos(Az)
    final double sinDec = math.sin(alt) * math.sin(lat) +
        math.cos(alt) * math.cos(lat) * math.cos(az);
    final double declination = math.asin(sinDec);

    // Calculate Hour Angle
    // cos(H) = (sin(Alt) - sin(Dec) * sin(Lat)) / (cos(Dec) * cos(Lat))
    // sin(H) = -sin(Az) * cos(Alt) / cos(Dec)
    final double cosDec = math.cos(declination);
    final double cosH = (math.sin(alt) - sinDec * math.sin(lat)) /
        (cosDec * math.cos(lat));
    final double sinH = -math.sin(az) * math.cos(alt) / cosDec;

    // Use atan2 to get the correct quadrant
    double hourAngle = math.atan2(sinH, cosH);
    hourAngle = TimeUtils.radiansToDegrees(hourAngle);

    // Calculate RA from Hour Angle
    // RA = LST - H
    final double lst = TimeUtils.localSiderealTime(dateTime, location.longitude);
    double rightAscension = lst - hourAngle;
    rightAscension = TimeUtils.normalizeDegrees(rightAscension);

    return EquatorialCoordinates(
      rightAscension: rightAscension,
      declination: TimeUtils.radiansToDegrees(declination),
    );
  }

  /// Calculates atmospheric refraction correction for altitude
  ///
  /// [apparentAltitude] The observed altitude in degrees
  /// [temperature] Temperature in Celsius (default: 10°C)
  /// [pressure] Atmospheric pressure in millibars (default: 1010 mb)
  ///
  /// Returns the refraction correction in degrees (to be subtracted from apparent altitude)
  ///
  /// Algorithm from Meeus, Chapter 16
  static double atmosphericRefraction(
    double apparentAltitude, {
    double temperature = 10.0,
    double pressure = 1010.0,
  }) {
    if (apparentAltitude < -1.0) {
      // Object is well below horizon, no meaningful refraction
      return 0.0;
    }

    // Convert to radians
    final double h = TimeUtils.degreesToRadians(apparentAltitude);

    // Simple refraction formula (Bennett, 1982)
    // R = 1.02 / tan(h + 10.3/(h + 5.11))  (in arcminutes)
    double refraction;

    if (apparentAltitude >= 15.0) {
      // Accurate formula for higher altitudes
      refraction = 0.00452 * pressure / ((273.0 + temperature) * math.tan(h));
    } else {
      // More complex formula for low altitudes
      final double denom = apparentAltitude + 10.3 / (apparentAltitude + 5.11);
      refraction = 1.02 / math.tan(TimeUtils.degreesToRadians(denom));

      // Convert from arcminutes to degrees
      refraction = refraction / 60.0;

      // Apply temperature and pressure corrections
      refraction = refraction * (pressure / 1010.0) * (283.0 / (273.0 + temperature));
    }

    return refraction;
  }

  /// Applies refraction correction to altitude
  ///
  /// [trueAltitude] The geometric (true) altitude in degrees
  /// [temperature] Temperature in Celsius
  /// [pressure] Atmospheric pressure in millibars
  ///
  /// Returns the apparent (observed) altitude in degrees
  static double applyRefraction(
    double trueAltitude, {
    double temperature = 10.0,
    double pressure = 1010.0,
  }) {
    if (trueAltitude < -5.0) {
      return trueAltitude; // Well below horizon
    }

    final double refraction = atmosphericRefraction(
      trueAltitude,
      temperature: temperature,
      pressure: pressure,
    );

    return trueAltitude + refraction;
  }
}
