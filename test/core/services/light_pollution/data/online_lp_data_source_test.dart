import 'package:astr/core/engine/models/location.dart';
import 'package:astr/core/services/light_pollution/data/online_lp_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'online_lp_data_source_test.mocks.dart';

@GenerateMocks(<Type>[http.Client])
void main() {
  late OnlineLPDataSource dataSource;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    dataSource = OnlineLPDataSource(
      client: mockClient,
      baseUrl: 'https://test-api.com',
    );
  });

  tearDown(() {
    dataSource.dispose();
  });

  group('OnlineLPDataSource (AC#2)', () {
    test('Successful API response → Returns Bortle class', () async {
      // Arrange
      const Location location = Location(latitude: 40.7, longitude: -74);
      final Uri uri = Uri.parse(
        'https://test-api.com/api/light-pollution?lat=40.7&lon=-74.0',
      );
      
      when(mockClient.get(uri)).thenAnswer(
        (_) async => http.Response('{"bortleClass": 5}', 200),
      );

      // Act
      final int? result = await dataSource.getBortleClass(location);

      // Assert
      expect(result, 5);
      verify(mockClient.get(uri)).called(1);
    });

    test('Invalid response (non-200) → Returns null', () async {
      // Arrange
      const Location location = Location(latitude: 40.7, longitude: -74);
      final Uri uri = Uri.parse(
        'https://test-api.com/api/light-pollution?lat=40.7&lon=-74.0',
      );
      
      when(mockClient.get(uri)).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );

      // Act
      final int? result = await dataSource.getBortleClass(location);

      // Assert
      expect(result, null);
    });

    test('Malformed JSON → Returns null', () async {
      // Arrange
      const Location location = Location(latitude: 40.7, longitude: -74);
      final Uri uri = Uri.parse(
        'https://test-api.com/api/light-pollution?lat=40.7&lon=-74.0',
      );
      
      when(mockClient.get(uri)).thenAnswer(
        (_) async => http.Response('invalid json', 200),
      );

      // Act
      final int? result = await dataSource.getBortleClass(location);

      // Assert
      expect(result, null);
    });

    test('Timeout (> 3s) → Returns null', () async {
      // Arrange
      const Location location = Location(latitude: 40.7, longitude: -74);
      final Uri uri = Uri.parse(
        'https://test-api.com/api/light-pollution?lat=40.7&lon=-74.0',
      );
      
      when(mockClient.get(uri)).thenAnswer(
        (_) async {
          await Future.delayed(const Duration(seconds: 4));
          return http.Response('{"bortleClass": 5}', 200);
        },
      );

      // Act
      final int? result = await dataSource.getBortleClass(location);

      // Assert
      expect(result, null);
    });

    test('Invalid Bortle class (out of range) → Returns null', () async {
      // Arrange
      const Location location = Location(latitude: 40.7, longitude: -74);
      final Uri uri = Uri.parse(
        'https://test-api.com/api/light-pollution?lat=40.7&lon=-74.0',
      );
      
      when(mockClient.get(uri)).thenAnswer(
        (_) async => http.Response('{"bortleClass": 15}', 200),
      );

      // Act
      final int? result = await dataSource.getBortleClass(location);

      // Assert
      expect(result, null);
    });

    test('Missing bortleClass field → Returns null', () async {
      // Arrange
      const Location location = Location(latitude: 40.7, longitude: -74);
      final Uri uri = Uri.parse(
        'https://test-api.com/api/light-pollution?lat=40.7&lon=-74.0',
      );
      
      when(mockClient.get(uri)).thenAnswer(
        (_) async => http.Response('{"data": "no bortle"}', 200),
      );

      // Act
      final int? result = await dataSource.getBortleClass(location);

      // Assert
      expect(result, null);
    });
  });
}
