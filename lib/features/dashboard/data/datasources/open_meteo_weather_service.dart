import 'package:dio/dio.dart';
import '../../../../core/config/api_config.dart';
import '../../../../features/context/domain/entities/geo_location.dart';

class OpenMeteoWeatherService {

  OpenMeteoWeatherService(this._dio);
  final Dio _dio;

  /// Fetches current weather data (cloud cover only for backward compatibility)
  /// AC#3: This method is now deprecated in favor of getHourlyForecast
  Future<double> getCloudCover(GeoLocation location) async {
    final Response response = await _dio.get(
      '${ApiConfig.weatherBaseUrl}/forecast',
      queryParameters: <String, dynamic>{
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

  /// Fetches hourly weather forecast for the next 16 days (Open-Meteo max)
  /// Returns map with hourly arrays for: temperature_2m, relativehumidity_2m, cloudcover, windspeed_10m
  /// AC#3: Extended from 7 to 16 days to support +/- 10 day cloud cover window
  Future<Map<String, dynamic>> getHourlyForecast(GeoLocation location) async {
    final Response response = await _dio.get(
      '${ApiConfig.weatherBaseUrl}/forecast',
      queryParameters: <String, dynamic>{
        'latitude': location.latitude,
        'longitude': location.longitude,
        'hourly': 'temperature_2m,relativehumidity_2m,cloudcover,windspeed_10m,weathercode',
        'forecast_days': 16, // AC#3: Extended from 7 to 16 (Open-Meteo max)
        'past_days': 10, // AC#3: Include 10 days of historical data
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final hourly = data['hourly'];
      
      if (hourly != null) {
        return <String, dynamic>{
          'time': (hourly['time'] as List).cast<String>(),
          'temperature': (hourly['temperature_2m'] as List).map((e) => (e as num?)?.toDouble() ?? 0.0).toList(),
          'humidity': (hourly['relativehumidity_2m'] as List).map((e) => (e as num?)?.toDouble() ?? 0.0).toList(),
          'cloudCover': (hourly['cloudcover'] as List).map((e) => (e as num?)?.toDouble() ?? 0.0).toList(),
          'windSpeed': (hourly['windspeed_10m'] as List).map((e) => (e as num?)?.toDouble() ?? 0.0).toList(),
          'weatherCode': (hourly['weathercode'] as List).map((e) => (e as num?)?.toDouble() ?? 0.0).toList(),
        };
      }
    }
    
    throw Exception('Failed to fetch hourly forecast data');
  }
}
