/// Timezone utilities for location-based date calculations.
///
/// Uses simple UTC offset calculation from longitude to determine
/// the local timezone of a geographic location.
class TimezoneHelper {
  /// Calculates approximate UTC offset from longitude.
  ///
  /// This uses the simple formula: offset = longitude / 15 (rounded).
  /// Not perfectly accurate for DST or complex timezone boundaries,
  /// but sufficient for day-level forecast calculations.
  ///
  /// Returns offset in hours from UTC.
  static int estimateUtcOffset(double longitude) {
    return (longitude / 15.0).round().clamp(-12, 14);
  }

  /// Gets the current DateTime at the given location (approximate).
  ///
  /// Uses longitude to estimate the UTC offset.
  static DateTime getNow(double longitude) {
    final int offsetHours = estimateUtcOffset(longitude);
    return DateTime.now().toUtc().add(Duration(hours: offsetHours));
  }

  /// Gets "today" at midnight for the given location.
  static DateTime getToday(double longitude) {
    final DateTime locationNow = getNow(longitude);
    return DateTime.utc(locationNow.year, locationNow.month, locationNow.day);
  }

  /// Generates a list of dates for the next 7 days at the location.
  ///
  /// Returns dates starting from "today" (Day 0) through Day 6.
  static List<DateTime> get7DayRange(double longitude) {
    final DateTime today = getToday(longitude);
    return List<DateTime>.generate(7, (int i) => today.add(Duration(days: i)));
  }

  /// Generates a list of cache keys for 7 days at the location.
  ///
  /// Format: `weather_{h3Index}_daily_{YYYY-MM-DD}`
  static List<String> generateDailyKeys(String h3Index, double longitude) {
    final List<DateTime> dates = get7DayRange(longitude);
    return dates
        .map((DateTime date) =>
            'weather_${h3Index}_daily_${_formatDate(date)}')
        .toList();
  }

  /// Formats date as YYYY-MM-DD.
  static String _formatDate(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
