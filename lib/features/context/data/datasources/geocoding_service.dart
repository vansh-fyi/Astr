import 'package:dio/dio.dart';
import '../../../../core/config/api_config.dart';
import '../../domain/entities/geo_location.dart';

class GeocodingService {

  GeocodingService(this._dio);
  final Dio _dio;

  Future<List<GeoLocation>> searchLocations(String query) async {
    try {
      final Response response = await _dio.get(
        '${ApiConfig.geocodingBaseUrl}/search',
        queryParameters: <String, dynamic>{
          'name': query,
          'count': 10,
          'format': 'json',
          'language': 'en',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['results'] != null) {
          return (data['results'] as List).map((item) {
            return GeoLocation(
              latitude: (item['latitude'] as num).toDouble(),
              longitude: (item['longitude'] as num).toDouble(),
              name: '${item['name']}, ${item['country'] ?? ''}',
            );
          }).toList();
        }
        return <GeoLocation>[];
      } else {
        throw Exception('Failed to search locations');
      }
    } catch (e) {
      throw Exception('Geocoding error: $e');
    }
  }
  Future<String> getPlaceName(double lat, double lon) async {
    try {
      final Response response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: <String, dynamic>{
          'lat': lat,
          'lon': lon,
          'format': 'json',
        },
        options: Options(
          headers: <String, dynamic>{
            'User-Agent': 'Astr/1.0', // Mandatory for Nominatim
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final address = data['address'];
        if (address != null) {
          final city = address['city'] ??
              address['town'] ??
              address['village'] ??
              address['county'] ??
              address['state'];
          final country = address['country'];
          
          if (city != null && country != null) {
             return '$city, $country';
          } else if (city != null) {
            return city;
          } else if (country != null) {
            return country;
          }
           return 'Unknown Location';
        }
        return 'Unknown Location';
      } else {
        throw Exception('Nominatim Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Reverse geocoding error: $e');
    }
  }
}
