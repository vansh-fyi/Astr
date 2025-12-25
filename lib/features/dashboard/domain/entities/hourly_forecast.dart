import 'package:equatable/equatable.dart';

class HourlyForecast extends Equatable {

  const HourlyForecast({
    required this.time,
    required this.cloudCover,
    required this.temperatureC,
    required this.humidity,
    required this.windSpeedKph,
    required this.seeingScore,
    required this.seeingLabel,
  });
  final DateTime time;
  final double cloudCover;
  final double temperatureC;
  final int humidity;
  final double windSpeedKph;
  final int seeingScore;
  final String seeingLabel;

  @override
  List<Object?> get props => <Object?>[time, cloudCover, temperatureC, humidity, windSpeedKph, seeingScore, seeingLabel];
}
