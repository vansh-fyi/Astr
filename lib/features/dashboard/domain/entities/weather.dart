import 'package:equatable/equatable.dart';

/// Weather conditions at a point in time.
///
/// The [isStale] flag indicates whether this data is older than 24 hours
/// and should be displayed with a "stale data" warning (FR-09).
///
/// The [lastUpdated] timestamp is used for the "Last Updated" indicator (FR-13).
class Weather extends Equatable {
  const Weather({
    required this.cloudCover,
    this.temperatureC,
    this.humidity,
    this.windSpeedKph,
    this.seeingScore,
    this.seeingLabel,
    this.isStale = false,
    this.lastUpdated,
  });

  final double cloudCover;
  final double? temperatureC;
  final double? humidity;
  final double? windSpeedKph;
  final int? seeingScore;
  final String? seeingLabel;

  /// Indicates whether this weather data is older than 24 hours (FR-09).
  final bool isStale;

  /// Timestamp when this weather data was last fetched/updated (FR-13).
  /// Used for displaying "Last Updated" indicator in dashboard header.
  final DateTime? lastUpdated;

  /// Creates a copy with optionally modified fields.
  Weather copyWith({
    double? cloudCover,
    double? temperatureC,
    double? humidity,
    double? windSpeedKph,
    int? seeingScore,
    String? seeingLabel,
    bool? isStale,
    DateTime? lastUpdated,
  }) {
    return Weather(
      cloudCover: cloudCover ?? this.cloudCover,
      temperatureC: temperatureC ?? this.temperatureC,
      humidity: humidity ?? this.humidity,
      windSpeedKph: windSpeedKph ?? this.windSpeedKph,
      seeingScore: seeingScore ?? this.seeingScore,
      seeingLabel: seeingLabel ?? this.seeingLabel,
      isStale: isStale ?? this.isStale,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        cloudCover,
        temperatureC,
        humidity,
        windSpeedKph,
        seeingScore,
        seeingLabel,
        isStale,
        lastUpdated,
      ];
}
