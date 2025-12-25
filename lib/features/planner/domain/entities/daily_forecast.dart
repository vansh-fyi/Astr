import 'package:equatable/equatable.dart';

class DailyForecast extends Equatable { // 1-5 scale

  const DailyForecast({
    required this.date,
    required this.cloudCoverAvg,
    required this.moonIllumination,
    required this.weatherCode,
    required this.starRating,
  });
  final DateTime date;
  final double cloudCoverAvg;
  final double moonIllumination; // 0.0 to 1.0
  final int weatherCode; // Open-Meteo WMO code
  final int starRating;

  bool get isGoodNight => starRating >= 4;

  @override
  List<Object?> get props => <Object?>[
        date,
        cloudCoverAvg,
        moonIllumination,
        weatherCode,
        starRating,
      ];
}
