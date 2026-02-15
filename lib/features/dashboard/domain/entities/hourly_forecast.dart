import 'package:equatable/equatable.dart';

/// Hourly weather forecast data.
///
/// The [isStale] flag indicates whether this data is older than 24 hours
/// and should be displayed with a "stale data" warning (FR-09).
class HourlyForecast extends Equatable {

  const HourlyForecast({
    required this.time,
    required this.cloudCover,
    required this.temperatureC,
    required this.humidity,
    required this.windSpeedKph,
    required this.seeingScore,
    required this.seeingLabel,
    this.isStale = false,
  });
  final DateTime time;
  final double cloudCover;
  final double temperatureC;
  final int humidity;
  final double windSpeedKph;
  final int seeingScore;
  final String seeingLabel;

  /// Indicates whether this weather data is older than 24 hours (FR-09).
  final bool isStale;

  /// Creates a copy with optionally modified fields.
  HourlyForecast copyWith({
    DateTime? time,
    double? cloudCover,
    double? temperatureC,
    int? humidity,
    double? windSpeedKph,
    int? seeingScore,
    String? seeingLabel,
    bool? isStale,
  }) {
    return HourlyForecast(
      time: time ?? this.time,
      cloudCover: cloudCover ?? this.cloudCover,
      temperatureC: temperatureC ?? this.temperatureC,
      humidity: humidity ?? this.humidity,
      windSpeedKph: windSpeedKph ?? this.windSpeedKph,
      seeingScore: seeingScore ?? this.seeingScore,
      seeingLabel: seeingLabel ?? this.seeingLabel,
      isStale: isStale ?? this.isStale,
    );
  }

  @override
  List<Object?> get props => <Object?>[time, cloudCover, temperatureC, humidity, windSpeedKph, seeingScore, seeingLabel, isStale];
}
