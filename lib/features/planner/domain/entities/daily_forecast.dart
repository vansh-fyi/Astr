import 'package:equatable/equatable.dart';

class DailyForecast extends Equatable {
  final DateTime date;
  final double cloudCoverAvg;
  final double moonIllumination; // 0.0 to 1.0
  final int weatherCode; // Open-Meteo WMO code
  final int starRating; // 1-5 scale

  const DailyForecast({
    required this.date,
    required this.cloudCoverAvg,
    required this.moonIllumination,
    required this.weatherCode,
    required this.starRating,
  });

  bool get isGoodNight => starRating >= 4;

  @override
  List<Object?> get props => [
        date,
        cloudCoverAvg,
        moonIllumination,
        weatherCode,
        starRating,
      ];
}
