import 'dart:math' as math;

/// Utilities for time and date conversions used in astronomical calculations
/// Based on Jean Meeus "Astronomical Algorithms" (2nd edition)
class TimeUtils {
  /// Converts a DateTime to Julian Date (JD)
  ///
  /// The Julian Date is the number of days since January 1, 4713 BC (proleptic Julian calendar)
  /// at 12:00:00 Universal Time.
  ///
  /// Algorithm from Meeus, Chapter 7
  static double dateTimeToJulianDate(DateTime dateTime) {
    // Convert to UTC
    final DateTime utc = dateTime.toUtc();

    int year = utc.year;
    int month = utc.month;
    final int day = utc.day;
    final double fractionalDay = day +
        (utc.hour + (utc.minute + utc.second / 60.0) / 60.0) / 24.0;

    // January and February are counted as months 13 and 14 of the previous year
    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    // Gregorian calendar correction
    final int a = (year / 100).floor();
    final int b = 2 - a + (a / 4).floor();

    final double jd = (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        fractionalDay +
        b -
        1524.5;

    return jd;
  }

  /// Converts Julian Date to DateTime
  static DateTime julianDateToDateTime(double jd) {
    // Add 0.5 to shift from midnight to noon
    final double jdAdjusted = jd + 0.5;
    final int z = jdAdjusted.floor();
    final double f = jdAdjusted - z;

    int a = z;
    if (z >= 2299161) {
      // Gregorian calendar
      final int alpha = ((z - 1867216.25) / 36524.25).floor();
      a = z + 1 + alpha - (alpha / 4).floor();
    }

    final int b = a + 1524;
    final int c = ((b - 122.1) / 365.25).floor();
    final int d = (365.25 * c).floor();
    final int e = ((b - d) / 30.6001).floor();

    final double day = b - d - (30.6001 * e).floor() + f;

    final int month = e < 14 ? e - 1 : e - 13;
    final int year = month > 2 ? c - 4716 : c - 4715;

    final int dayInt = day.floor();
    final double fractionalDay = day - dayInt;
    final int hour = (fractionalDay * 24).floor();
    final int minute = ((fractionalDay * 24 - hour) * 60).floor();
    final int second = (((fractionalDay * 24 - hour) * 60 - minute) * 60).floor();

    return DateTime.utc(year, month, dayInt, hour, minute, second);
  }

  /// Calculates the number of Julian centuries since J2000.0 (2000 January 1.5)
  ///
  /// T = (JD - 2451545.0) / 36525
  static double julianCenturiesSinceJ2000(double jd) {
    return (jd - 2451545.0) / 36525.0;
  }

  /// Calculates Greenwich Mean Sidereal Time (GMST) in degrees
  ///
  /// Algorithm from Meeus, Chapter 12
  static double greenwichMeanSiderealTime(DateTime dateTime) {
    final double jd = dateTimeToJulianDate(dateTime);
    final double t = julianCenturiesSinceJ2000(jd);

    // GMST at 0h UT
    final double jd0 = dateTimeToJulianDate(DateTime.utc(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    ));
    final double t0 = julianCenturiesSinceJ2000(jd0);

    // Calculate GMST in seconds
    double gmst = 280.46061837 +
        360.98564736629 * (jd - 2451545.0) +
        0.000387933 * t * t -
        t * t * t / 38710000.0;

    // Normalize to 0-360 degrees
    gmst = gmst % 360.0;
    if (gmst < 0) gmst += 360.0;

    return gmst;
  }

  /// Calculates Local Sidereal Time (LST) in degrees
  ///
  /// LST = GMST + observer's longitude
  /// [longitude] in degrees (East is positive)
  static double localSiderealTime(DateTime dateTime, double longitude) {
    double lst = greenwichMeanSiderealTime(dateTime) + longitude;

    // Normalize to 0-360 degrees
    lst = lst % 360.0;
    if (lst < 0) lst += 360.0;

    return lst;
  }

  /// Normalizes an angle to the range [0, 360) degrees
  static double normalizeDegrees(double degrees) {
    double normalized = degrees % 360.0;
    if (normalized < 0) normalized += 360.0;
    return normalized;
  }

  /// Normalizes an angle to the range [-180, 180) degrees
  static double normalizeDegreesSymmetric(double degrees) {
    double normalized = degrees % 360.0;
    if (normalized < -180) {
      normalized += 360.0;
    } else if (normalized >= 180) {
      normalized -= 360.0;
    }
    return normalized;
  }

  /// Converts degrees to radians
  static double degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  /// Converts radians to degrees
  static double radiansToDegrees(double radians) {
    return radians * 180.0 / math.pi;
  }
}
