import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../engine/models/location.dart';
import '../i_weather_service.dart';

/// Data source for Open-Meteo weather API
/// AC#1: Successfully fetch weather data from Open-Meteo API
/// AC#2: Parse JSON response to extract cloud cover, seeing, temperature
/// AC#5: Weather fetch completes in < 2s (timeout enforced)
class OpenMeteoDataSource {

  OpenMeteoDataSource({
    http.Client? client,
    String baseUrl = 'https://api.open-meteo.com',
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl;
  final http.Client _client;
  final String _baseUrl;

  /// Fetch weather data from Open-Meteo API
  /// Returns null if request fails, times out, or response is invalid
  /// AC#5: 2-second timeout constraint
  Future<Weather?> getWeather(Location location) async {
    try {
      final Uri uri = Uri.parse(
        '$_baseUrl/v1/forecast?latitude=${location.latitude}&longitude=${location.longitude}&current=temperature_2m,cloud_cover',
      );

      final http.Response response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        return _parseWeatherData(data);
      }
      
      return null;
    } on TimeoutException {
      return null;
    } catch (e) {
      // Network errors, parse errors, etc.
      return null;
    }
  }

  /// Parse Open-Meteo JSON response to Weather model
  /// AC#2: Extract cloud cover (%), temperature
  /// Note: Open-Meteo doesn't provide 'seeing' directly, so it's left null
  Weather? _parseWeatherData(Map<String, dynamic> data) {
    try {
      final Map<String, dynamic>? current = data['current'] as Map<String, dynamic>?;
      if (current == null) return null;

      final num? temperature = current['temperature_2m'] as num?;
      final num? cloudCover = current['cloud_cover'] as num?;

      if (temperature == null || cloudCover == null) return null;

      return Weather(
        temperatureCelsius: temperature.toDouble(),
        cloudCoverPercent: cloudCover.toDouble(),
      );
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
