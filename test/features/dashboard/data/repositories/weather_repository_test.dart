import 'package:astr/core/error/failure.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/dashboard/data/datasources/open_meteo_weather_service.dart';
import 'package:astr/features/dashboard/data/repositories/weather_repository_impl.dart';
import 'package:astr/features/dashboard/domain/entities/weather.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'weather_repository_test.mocks.dart';

@GenerateMocks(<Type>[OpenMeteoWeatherService])
void main() {
  late WeatherRepositoryImpl repository;
  late MockOpenMeteoWeatherService mockService;

  setUp(() {
    mockService = MockOpenMeteoWeatherService();
    repository = WeatherRepositoryImpl(mockService);
  });

  const GeoLocation tLocation = GeoLocation(latitude: 0, longitude: 0);

  group('getWeather', () {
    test('should return Weather with humidity and temperature when service call is successful', () async {
      // Arrange
      final Map<String, List<double>> tHourlyData = <String, List<double>>{
        'cloudCover': <double>[10],
        'temperature': <double>[20],
        'humidity': <double>[50],
        'windSpeed': <double>[5],
      };
      when(mockService.getHourlyForecast(tLocation))
          .thenAnswer((_) async => tHourlyData);

      // Act
      final Either<Failure, Weather> result = await repository.getWeather(tLocation);

      // Assert
      expect(result, isA<Right<Failure, Weather>>());
      result.fold(
        (Failure failure) => fail('Should not return failure'),
        (Weather weather) {
          expect(weather.temperatureC, 20.0);
          expect(weather.humidity, 50.0);
          expect(weather.cloudCover, 10.0);
          expect(weather.windSpeedKph, 5.0);
        },
      );
    });

    test('should return ServerFailure when service call throws exception', () async {
      // Arrange
      when(mockService.getHourlyForecast(tLocation))
          .thenThrow(Exception('API Error'));

      // Act
      final Either<Failure, Weather> result = await repository.getWeather(tLocation);

      // Assert
      expect(result, isA<Left<Failure, Weather>>());
    });
  });
}
