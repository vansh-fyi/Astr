import 'package:astr/core/engine/models/location.dart';
import 'package:astr/core/engine/models/result.dart';
import 'package:astr/core/error/weather_failure.dart';
import 'package:astr/core/services/weather/i_weather_service.dart';
import 'package:astr/core/services/weather/data/open_meteo_data_source.dart';

/// Weather Service implementing Open-Meteo API integration
/// AC#1: Successfully fetch weather data from Open-Meteo API
/// AC#3: Handle network errors, timeouts gracefully using Result<T>
class WeatherService implements IWeatherService {
  final OpenMeteoDataSource _dataSource;

  WeatherService({
    OpenMeteoDataSource? dataSource,
  }) : _dataSource = dataSource ?? OpenMeteoDataSource();

  @override
  Future<Result<Weather>> getWeather(Location location) async {
    try {
      final weather = await _dataSource.getWeather(location);
      
      if (weather != null) {
        return Result.success(weather);
      }
      
      return Result.failure(
        const WeatherFailure('Weather fetch failed: no data returned'),
      );
    } catch (e) {
      return Result.failure(
        WeatherFailure('Weather fetch failed: $e'),
      );
    }
  }

  void dispose() {
    _dataSource.dispose();
  }
}
