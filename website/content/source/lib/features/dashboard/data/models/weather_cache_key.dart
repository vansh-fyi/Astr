/// Cache key generation utilities for weather caching.
///
/// Key formats:
/// - Standard: `weather_{h3Index}_{YYYY-MM-DD}`
/// - Daily: `weather_{h3Index}_daily_{YYYY-MM-DD}`
/// - Hourly: `weather_{h3Index}_hourly_{YYYY-MM-DD}`
///
/// Date is normalized to midnight UTC for consistent lookup.
class WeatherCacheKeyGenerator {
  /// Generates a cache key from H3 index and date.
  ///
  /// Date is normalized to midnight UTC to ensure consistent keys
  /// regardless of timezone or time of day.
  static String generate(String h3Index, DateTime date) {
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    final dateStr = _formatDate(normalizedDate);
    return 'weather_${h3Index}_$dateStr';
  }

  /// Generates a daily forecast cache key.
  ///
  /// Format: `weather_{h3Index}_daily_{YYYY-MM-DD}`
  /// Used for 7-day individual forecast caching (Story 3.2).
  static String generateDaily(String h3Index, DateTime date) {
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    final dateStr = _formatDate(normalizedDate);
    return 'weather_${h3Index}_daily_$dateStr';
  }

  /// Formats date as YYYY-MM-DD ISO 8601 format.
  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Normalizes a DateTime to midnight UTC for cache key consistency.
  static DateTime normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }
}
