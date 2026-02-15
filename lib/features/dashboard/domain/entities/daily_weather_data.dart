import 'package:equatable/equatable.dart';
import 'weather.dart';

/// Weather data for a single day.
///
/// The [isStale] flag indicates whether this data is older than 24 hours
/// and should be displayed with a "stale data" warning (FR-09).
class DailyWeatherData extends Equatable {
  const DailyWeatherData({
    required this.date,
    required this.weather,
    required this.weatherCode,
    this.isStale = false,
  });

  final DateTime date;
  final Weather weather;
  final int weatherCode;

  /// Indicates whether this weather data is older than 24 hours (FR-09).
  final bool isStale;

  /// Creates a copy with optionally modified fields.
  DailyWeatherData copyWith({
    DateTime? date,
    Weather? weather,
    int? weatherCode,
    bool? isStale,
  }) {
    return DailyWeatherData(
      date: date ?? this.date,
      weather: weather ?? this.weather,
      weatherCode: weatherCode ?? this.weatherCode,
      isStale: isStale ?? this.isStale,
    );
  }

  @override
  List<Object?> get props => <Object?>[date, weather, weatherCode, isStale];
}
