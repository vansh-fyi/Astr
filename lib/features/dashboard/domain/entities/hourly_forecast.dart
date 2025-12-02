import 'package:equatable/equatable.dart';
import 'weather.dart';

class HourlyForecast extends Equatable {
  final DateTime time;
  final double cloudCover;
  final double temperatureC;
  final int humidity;
  final double windSpeedKph;
  final int seeingScore;
  final String seeingLabel;

  const HourlyForecast({
    required this.time,
    required this.cloudCover,
    required this.temperatureC,
    required this.humidity,
    required this.windSpeedKph,
    required this.seeingScore,
    required this.seeingLabel,
  });

  @override
  List<Object?> get props => [time, cloudCover, temperatureC, humidity, windSpeedKph, seeingScore, seeingLabel];
}
