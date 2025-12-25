import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../engine/models/location.dart';

/// Online data source for light pollution data
/// Fetches Bortle class from remote API
class OnlineLPDataSource {

  OnlineLPDataSource({
    http.Client? client,
    String baseUrl = 'https://astr-api.vercel.app',
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl;
  final http.Client _client;
  final String _baseUrl;

  /// Fetch Bortle class from API
  /// Returns null if request fails, times out, or response is invalid
  Future<int?> getBortleClass(Location location) async {
    try {
      final Uri uri = Uri.parse(
        '$_baseUrl/api/light-pollution?lat=${location.latitude}&lon=${location.longitude}',
      );

      final http.Response response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        final int? bortleClass = data['bortleClass'] as int?;
        
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
