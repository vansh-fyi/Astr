import 'package:equatable/equatable.dart';
import 'weather.dart';

class DailyWeatherData extends Equatable {
  final DateTime date;
  final Weather weather;
  final int weatherCode; // Open-Meteo WMO code

  const DailyWeatherData({
    required this.date,
    required this.weather,
    required this.weatherCode,
  });

  @override
  List<Object?> get props => [date, weather, weatherCode];
}
