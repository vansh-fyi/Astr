import 'package:astr/core/engine/models/location.dart';
import 'package:astr/core/engine/models/result.dart';
import 'package:astr/core/services/weather/data/open_meteo_data_source.dart';
import 'package:astr/core/services/weather/i_weather_service.dart';
import 'package:astr/core/services/weather/weather_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'weather_service_test.mocks.dart';

@GenerateMocks(<Type>[OpenMeteoDataSource])
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
      const Weather mockWeather = Weather(
        temperatureCelsius: 15.5,
        cloudCoverPercent: 25,
      );
      when(mockDataSource.getWeather(testLocation))
          .thenAnswer((_) async => mockWeather);

      // Act
      final Result<Weather> result = await service.getWeather(testLocation);

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
      final Result<Weather> result = await service.getWeather(testLocation);

      // Assert
      expect(result.isFailure, true);
      expect(result.failure.message, contains('no data returned'));
    });

    test('Returns failure when data source throws exception', () async {
      // Arrange
      when(mockDataSource.getWeather(testLocation))
          .thenThrow(Exception('Network error'));

      // Act
      final Result<Weather> result = await service.getWeather(testLocation);

      // Assert
      expect(result.isFailure, true);
      expect(result.failure.message, contains('Network error'));
    });

    test('Handles multiple locations correctly', () async {
      // Arrange
      const Location nyc = Location(latitude: 40.7128, longitude: -74.0060);
      const Location london = Location(latitude: 51.5074, longitude: -0.1278);

      const Weather nycWeather = Weather(
        temperatureCelsius: 20,
        cloudCoverPercent: 30,
      );
      const Weather londonWeather = Weather(
        temperatureCelsius: 12,
        cloudCoverPercent: 60,
      );

      when(mockDataSource.getWeather(nyc))
          .thenAnswer((_) async => nycWeather);
      when(mockDataSource.getWeather(london))
          .thenAnswer((_) async => londonWeather);

      // Act
      final Result<Weather> nycResult = await service.getWeather(nyc);
      final Result<Weather> londonResult = await service.getWeather(london);

      // Assert
      expect(nycResult.value.temperatureCelsius, 20.0);
      expect(londonResult.value.temperatureCelsius, 12.0);
    });
  });
}
