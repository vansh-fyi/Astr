import 'package:equatable/equatable.dart';
import 'weather.dart';

class DailyWeatherData extends Equatable { // Open-Meteo WMO code

  const DailyWeatherData({
    required this.date,
    required this.weather,
    required this.weatherCode,
  });
  final DateTime date;
  final Weather weather;
  final int weatherCode;

  @override
  List<Object?> get props => <Object?>[date, weather, weatherCode];
}
