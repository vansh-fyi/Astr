import 'package:astr/core/engine/models/location.dart';
import 'package:astr/core/engine/models/result.dart';

/// Interface for weather service
abstract class IWeatherService {
  /// Get weather data for a given location
  /// Returns Result.success with Weather data or Result.failure on error
  Future<Result<Weather>> getWeather(Location location);
}

/// Weather entity representing current weather conditions
class Weather {
  final double temperatureCelsius;
  final double cloudCoverPercent;
  final double? seeingArcseconds; // Optional, may be null if not available

  const Weather({
    required this.temperatureCelsius,
    required this.cloudCoverPercent,
    this.seeingArcseconds,
  });

  @override
  String toString() {
    return 'Weather(temp: ${temperatureCelsius}°C, clouds: ${cloudCoverPercent}%, seeing: ${seeingArcseconds ?? "N/A"}")';
  }
}
