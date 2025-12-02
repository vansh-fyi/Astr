import 'package:equatable/equatable.dart';

class Weather extends Equatable {
  final double cloudCover; // Percentage 0-100
  final double? temperatureC; // Temperature in Celsius (AC#3)
  final double? humidity; // Relative humidity percentage 0-100 (AC#3)
  final double? windSpeedKph; // Wind speed in km/h (AC#3)
  final int? seeingScore; // Pickering Seeing score 1-10 (AC#1)
  final String? seeingLabel; // Seeing quality label (AC#1)

  const Weather({
    required this.cloudCover,
    this.temperatureC,
    this.humidity,
    this.windSpeedKph,
    this.seeingScore,
    this.seeingLabel,
  });

  @override
  List<Object?> get props => [cloudCover, temperatureC, humidity, windSpeedKph, seeingScore, seeingLabel];
}
