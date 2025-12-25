import 'package:astr/core/engine/models/location.dart';
import 'package:astr/core/services/weather/data/open_meteo_data_source.dart';
import 'package:astr/core/services/weather/i_weather_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'open_meteo_data_source_test.mocks.dart';

@GenerateMocks(<Type>[http.Client])
void main() {
  late OpenMeteoDataSource dataSource;
  late MockClient mockClient;
  late Location testLocation;

  setUp(() {
    mockClient = MockClient();
    dataSource = OpenMeteoDataSource(client: mockClient);
    testLocation = const Location(latitude: 40.7128, longitude: -74.0060);
  });

  group('OpenMeteoDataSource', () {
    test('Parses valid JSON response correctly (AC#2)', () async {
      // Arrange
      const String validResponse = '''
      {
        "current": {
          "temperature_2m": 15.5,
          "cloud_cover": 25.0
        }
      }
      ''';

      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response(validResponse, 200));

      // Act
      final Weather? weather = await dataSource.getWeather(testLocation);

      // Assert
      expect(weather, isNotNull);
      expect(weather!.temperatureCelsius, 15.5);
      expect(weather.cloudCoverPercent, 25.0);
      expect(weather.seeingArcseconds, isNull); // Not provided by Open-Meteo
    });

    test('Returns null on network error (AC#3)', () async {
      // Arrange
      when(mockClient.get(any)).thenThrow(Exception('Network error'));

      // Act
      final Weather? weather = await dataSource.getWeather(testLocation);

      // Assert
      expect(weather, isNull);
    });

    test('Returns null on timeout after 2s (AC#5)', () async {
      // Arrange
      when(mockClient.get(any)).thenAnswer(
        (_) async => Future.delayed(
          const Duration(seconds: 3),
          () => http.Response('{}', 200),
        ),
      );

      // Act
      final Weather? weather = await dataSource.getWeather(testLocation);

      // Assert
      expect(weather, isNull);
    });

    test('Returns null on non-200 status code', () async {
      // Arrange
      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response('Error', 500));

      // Act
      final Weather? weather = await dataSource.getWeather(testLocation);

      // Assert
      expect(weather, isNull);
    });

    test('Returns null on malformed JSON', () async {
      // Arrange
      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response('not json', 200));

      // Act
      final Weather? weather = await dataSource.getWeather(testLocation);

      // Assert
      expect(weather, isNull);
    });

    test('Returns null when missing required fields', () async {
      // Arrange
      const String incompleteResponse = '''
      {
        "current": {
          "temperature_2m": 15.5
        }
      }
      ''';

      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response(incompleteResponse, 200));

      // Act
      final Weather? weather = await dataSource.getWeather(testLocation);

      // Assert
      expect(weather, isNull);
    });

    test('Constructs correct API URL with location', () async {
      // Arrange
      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response('{"current": {"temperature_2m": 15.5, "cloud_cover": 25.0}}', 200));

      // Act
      await dataSource.getWeather(testLocation);

      // Assert
      final Uri captured = verify(mockClient.get(captureAny)).captured.single as Uri;
      expect(captured.toString(), contains('latitude=40.7128'));
      expect(captured.toString(), contains('longitude=-74.006'));
      expect(captured.toString(), contains('current=temperature_2m,cloud_cover'));
    });
  });
}
