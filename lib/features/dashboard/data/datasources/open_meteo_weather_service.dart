import 'package:dio/dio.dart';
import '../../../../core/config/api_config.dart';
import '../../../../features/context/domain/entities/geo_location.dart';

class OpenMeteoWeatherService {
  final Dio _dio;

  OpenMeteoWeatherService(this._dio);

  /// Fetches current weather data (cloud cover only for backward compatibility)
  /// AC#3: This method is now deprecated in favor of getHourlyForecast
  Future<double> getCloudCover(GeoLocation location) async {
    final response = await _dio.get(
      '${ApiConfig.weatherBaseUrl}/forecast',
      queryParameters: {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'current': 'cloud_cover',
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final current = data['current'];
      if (current != null && current['cloud_cover'] != null) {
        return (current['cloud_cover'] as num).toDouble();
      }
    }
    
    throw Exception('Failed to fetch weather data');
  }

  /// Fetches hourly weather forecast for the next 7 days
  /// Returns map with hourly arrays for: temperature_2m, relativehumidity_2m, cloudcover, windspeed_10m
  /// AC#3: Required data sources for Seeing calculations
  Future<Map<String, dynamic>> getHourlyForecast(GeoLocation location) async {
    final response = await _dio.get(
      '${ApiConfig.weatherBaseUrl}/forecast',
      queryParameters: {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'hourly': 'temperature_2m,relativehumidity_2m,cloudcover,windspeed_10m,weathercode',
        'forecast_days': 7,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final hourly = data['hourly'];
      
      if (hourly != null) {
        return {
          'time': (hourly['time'] as List).cast<String>(),
          'temperature': (hourly['temperature_2m'] as List).map((e) => (e as num).toDouble()).toList(),
          'humidity': (hourly['relativehumidity_2m'] as List).map((e) => (e as num).toDouble()).toList(),
          'cloudCover': (hourly['cloudcover'] as List).map((e) => (e as num).toDouble()).toList(),
          'windSpeed': (hourly['windspeed_10m'] as List).map((e) => (e as num).toDouble()).toList(),
          'weatherCode': (hourly['weathercode'] as List).map((e) => (e as num).toDouble()).toList(),
        };
      }
    }
    
    throw Exception('Failed to fetch hourly forecast data');
  }
}
