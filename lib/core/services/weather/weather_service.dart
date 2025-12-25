import '../../engine/models/location.dart';
import '../../engine/models/result.dart';
import '../../error/weather_failure.dart';
import 'data/open_meteo_data_source.dart';
import 'i_weather_service.dart';

/// Weather Service implementing Open-Meteo API integration
/// AC#1: Successfully fetch weather data from Open-Meteo API
/// AC#3: Handle network errors, timeouts gracefully using Result<T>
class WeatherService implements IWeatherService {

  WeatherService({
    OpenMeteoDataSource? dataSource,
  }) : _dataSource = dataSource ?? OpenMeteoDataSource();
  final OpenMeteoDataSource _dataSource;

  @override
  Future<Result<Weather>> getWeather(Location location) async {
    try {
      final Weather? weather = await _dataSource.getWeather(location);
      
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
