import 'dart:async';
import 'dart:convert';
import 'package:astr/core/engine/models/location.dart';
import 'package:http/http.dart' as http;

/// Online data source for light pollution data
/// Fetches Bortle class from remote API
class OnlineLPDataSource {
  final http.Client _client;
  final String _baseUrl;

  OnlineLPDataSource({
    http.Client? client,
    String baseUrl = 'https://astr-api.vercel.app',
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  /// Fetch Bortle class from API
  /// Returns null if request fails, times out, or response is invalid
  Future<int?> getBortleClass(Location location) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/api/light-pollution?lat=${location.latitude}&lon=${location.longitude}',
      );

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final bortleClass = data['bortleClass'] as int?;
        
        if (bortleClass != null && bortleClass >= 1 && bortleClass <= 9) {
          return bortleClass;
        }
      }
      
      return null;
    } on TimeoutException {
      return null;
    } catch (e) {
      // Network errors, parse errors, etc.
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
