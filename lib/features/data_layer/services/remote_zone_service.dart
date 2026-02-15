import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/zone_data.dart';

/// Service for fetching zone data from remote Cloudflare R2/Worker API.
///
/// This service makes HTTP requests to retrieve light pollution data
/// for specific H3 indices from the cloud-hosted zones.db.
///
/// **Architecture:**
/// - Cloudflare Worker handles binary search in zones.db
/// - Returns JSON with bortle, ratio, sqm values
/// - Fallback returns null on network/server errors
class RemoteZoneService {
  RemoteZoneService({
    String? baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl ?? _defaultBaseUrl,
        _client = client ?? http.Client();

  /// Default API endpoint - update with your Cloudflare Worker URL
  static const String _defaultBaseUrl = 'https://astr-zones.astr-vansh-fyi.workers.dev';

  final String _baseUrl;
  final http.Client _client;

  /// Timeout for API requests
  static const Duration _timeout = Duration(seconds: 10);

  /// Fetches zone data for the given H3 index from remote API.
  ///
  /// Returns:
  /// - [ZoneData] on success
  /// - `null` on network error, timeout, or 404 (not found)
  ///
  /// Throws: Nothing - all errors are caught and return null for graceful fallback.
  Future<ZoneData?> getZoneData(BigInt h3Index) async {
    final String h3Hex = h3Index.toRadixString(16);
    final Uri uri = Uri.parse('$_baseUrl/zone/$h3Hex');

    try {
      final http.Response response = await _client
          .get(uri)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = 
            jsonDecode(response.body) as Map<String, dynamic>;
        
        return ZoneData(
          bortleClass: json['bortle'] as int,
          ratio: (json['ratio'] as num).toDouble(),
          sqm: (json['sqm'] as num).toDouble(),
        );
      } else if (response.statusCode == 404) {
        // H3 index not found in database - expected for ocean/unpopulated areas
        debugPrint('Zone not found for H3 $h3Hex');
        return null;
      } else {
        debugPrint('Zone API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Zone API request failed: $e');
      return null;
    }
  }

  /// Batch fetch zone data for multiple H3 indices.
  /// 
  /// Useful for pre-caching nearby cells.
  /// Returns a map of h3Index -> ZoneData (excludes failed/not-found).
  Future<Map<BigInt, ZoneData>> getZoneDataBatch(List<BigInt> h3Indices) async {
    final Map<BigInt, ZoneData> results = <BigInt, ZoneData>{};
    
    // Process in parallel with max 5 concurrent requests
    const int batchSize = 5;
    for (int i = 0; i < h3Indices.length; i += batchSize) {
      final List<BigInt> batch = h3Indices.skip(i).take(batchSize).toList();
      final List<Future<MapEntry<BigInt, ZoneData?>?>> futures = batch.map((BigInt index) async {
        final ZoneData? data = await getZoneData(index);
        return data != null ? MapEntry<BigInt, ZoneData>(index, data) : null;
      }).toList();
      
      final List<MapEntry<BigInt, ZoneData?>?> batchResults = await Future.wait(futures);
      for (final MapEntry<BigInt, ZoneData?>? entry in batchResults) {
        if (entry != null && entry.value != null) {
          results[entry.key] = entry.value!;
        }
      }
    }
    
    return results;
  }

  /// Dispose the HTTP client when done.
  void dispose() {
    _client.close();
  }
}
