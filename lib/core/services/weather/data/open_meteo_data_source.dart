import 'dart:async';
import 'dart:convert';
import 'package:astr/core/engine/models/location.dart';
import 'package:astr/core/services/weather/i_weather_service.dart';
import 'package:http/http.dart' as http;

/// Data source for Open-Meteo weather API
/// AC#1: Successfully fetch weather data from Open-Meteo API
/// AC#2: Parse JSON response to extract cloud cover, seeing, temperature
/// AC#5: Weather fetch completes in < 2s (timeout enforced)
class OpenMeteoDataSource {
  final http.Client _client;
  final String _baseUrl;

  OpenMeteoDataSource({
    http.Client? client,
    String baseUrl = 'https://api.open-meteo.com',
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  /// Fetch weather data from Open-Meteo API
  /// Returns null if request fails, times out, or response is invalid
  /// AC#5: 2-second timeout constraint
  Future<Weather?> getWeather(Location location) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/v1/forecast?latitude=${location.latitude}&longitude=${location.longitude}&current=temperature_2m,cloud_cover',
      );

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
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
      final current = data['current'] as Map<String, dynamic>?;
      if (current == null) return null;

      final temperature = current['temperature_2m'] as num?;
      final cloudCover = current['cloud_cover'] as num?;

      if (temperature == null || cloudCover == null) return null;

      return Weather(
        temperatureCelsius: temperature.toDouble(),
        cloudCoverPercent: cloudCover.toDouble(),
        seeingArcseconds: null, // Not available from Open-Meteo
      );
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
