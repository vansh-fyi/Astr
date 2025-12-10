import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:astr/core/engine/models/location.dart';
import 'package:astr/core/engine/models/result.dart';
import 'package:astr/core/services/weather/weather_service.dart';
import 'package:astr/core/services/weather/i_weather_service.dart';
import 'package:astr/core/services/weather/data/open_meteo_data_source.dart';

import 'weather_service_test.mocks.dart';

@GenerateMocks([OpenMeteoDataSource])
void main() {
  late WeatherService service;
  late MockOpenMeteoDataSource mockDataSource;
  late Location testLocation;

  setUp(() {
    mockDataSource = MockOpenMeteoDataSource();
    service = WeatherService(dataSource: mockDataSource);
    testLocation = const Location(latitude: 40.7128, longitude: -74.0060);
  });

  group('WeatherService', () {
    test('Returns success when data source provides weather', () async {
      // Arrange
      final mockWeather = Weather(
        temperatureCelsius: 15.5,
        cloudCoverPercent: 25.0,
      );
      when(mockDataSource.getWeather(testLocation))
          .thenAnswer((_) async => mockWeather);

      // Act
      final result = await service.getWeather(testLocation);

      // Assert
      expect(result.isSuccess, true);
      expect(result.value, mockWeather);
      verify(mockDataSource.getWeather(testLocation)).called(1);
    });

    test('Returns failure when data source returns null', () async {
      // Arrange
      when(mockDataSource.getWeather(testLocation))
          .thenAnswer((_) async => null);

      // Act
      final result = await service.getWeather(testLocation);

      // Assert
      expect(result.isFailure, true);
      expect(result.failure.message, contains('no data returned'));
    });

    test('Returns failure when data source throws exception', () async {
      // Arrange
      when(mockDataSource.getWeather(testLocation))
          .thenThrow(Exception('Network error'));

      // Act
      final result = await service.getWeather(testLocation);

      // Assert
      expect(result.isFailure, true);
      expect(result.failure.message, contains('Network error'));
    });

    test('Handles multiple locations correctly', () async {
      // Arrange
      final nyc = const Location(latitude: 40.7128, longitude: -74.0060);
      final london = const Location(latitude: 51.5074, longitude: -0.1278);

      final nycWeather = Weather(
        temperatureCelsius: 20.0,
        cloudCoverPercent: 30.0,
      );
      final londonWeather = Weather(
        temperatureCelsius: 12.0,
        cloudCoverPercent: 60.0,
      );

      when(mockDataSource.getWeather(nyc))
          .thenAnswer((_) async => nycWeather);
      when(mockDataSource.getWeather(london))
          .thenAnswer((_) async => londonWeather);

      // Act
      final nycResult = await service.getWeather(nyc);
      final londonResult = await service.getWeather(london);

      // Assert
      expect(nycResult.value.temperatureCelsius, 20.0);
      expect(londonResult.value.temperatureCelsius, 12.0);
    });
  });
}
