import 'package:astr/core/error/failure.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/dashboard/data/datasources/open_meteo_weather_service.dart';
import 'package:astr/features/dashboard/data/repositories/weather_repository_impl.dart';
import 'package:astr/features/dashboard/domain/entities/daily_weather_data.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:astr/features/dashboard/domain/entities/hourly_forecast.dart';

class FakeOpenMeteoWeatherService extends OpenMeteoWeatherService {
  final Map<String, dynamic>? hourlyResponse;
  final Exception? error;

  FakeOpenMeteoWeatherService({this.hourlyResponse, this.error}) : super(Dio());

  @override
  Future<Map<String, dynamic>> getHourlyForecast(GeoLocation location) async {
    if (error != null) throw error!;
    return hourlyResponse!;
  }
}

void main() {
  late WeatherRepositoryImpl repository;

  const tLocation = GeoLocation(latitude: 0, longitude: 0);

  group('getDailyForecast', () {
    test('should return list of DailyWeatherData when service call is successful', () async {
      // Arrange
      final count = 168;
      final mockHourlyData = {
        'time': List.generate(count, (i) => DateTime.now().add(Duration(hours: i)).toIso8601String()),
        'temperature': List.filled(count, 20.0),
        'humidity': List.filled(count, 50.0),
        'cloudCover': List.filled(count, 10.0),
        'windSpeed': List.filled(count, 5.0),
        'weatherCode': List.filled(count, 0.0),
      };

      final fakeService = FakeOpenMeteoWeatherService(hourlyResponse: mockHourlyData);
      repository = WeatherRepositoryImpl(fakeService);

      // Act
      final result = await repository.getDailyForecast(tLocation);

      // Assert
      expect(result, isA<Right<Failure, List<DailyWeatherData>>>());
      result.fold(
        (l) => fail('Should not return failure'),
        (r) {
          expect(r.length, 7);
          expect(r[0].temperatureC, 20.0);
          expect(r[0].weatherCode, 0);
        },
      );
    });

    test('should return ServerFailure when service throws exception', () async {
      // Arrange
      final fakeService = FakeOpenMeteoWeatherService(error: Exception('API Error'));
      repository = WeatherRepositoryImpl(fakeService);

      // Act
      final result = await repository.getDailyForecast(tLocation);

      // Assert
      expect(result, isA<Left<Failure, List<DailyWeatherData>>>());
    });
  });

  group('getHourlyForecast', () {
    test('should return list of HourlyForecast when service call is successful', () async {
      // Arrange
      final count = 24;
      final now = DateTime.now();
      final mockHourlyData = {
        'time': List.generate(count, (i) => now.add(Duration(hours: i)).toIso8601String()),
        'temperature': List.filled(count, 15.0),
        'humidity': List.filled(count, 60.0),
        'cloudCover': List.filled(count, 25.0),
        'windSpeed': List.filled(count, 10.0),
        'weatherCode': List.filled(count, 1.0),
      };

      final fakeService = FakeOpenMeteoWeatherService(hourlyResponse: mockHourlyData);
      repository = WeatherRepositoryImpl(fakeService);

      // Act
      final result = await repository.getHourlyForecast(tLocation);

      // Assert
      expect(result, isA<Right<Failure, List<HourlyForecast>>>());
      result.fold(
        (l) => fail('Should not return failure'),
        (r) {
          expect(r.length, 24);
          expect(r[0].cloudCover, 25.0);
          expect(r[0].temperatureC, 15.0);
          // Verify time parsing (ignoring microsecond differences)
          expect(r[0].time.year, now.year);
          expect(r[0].time.month, now.month);
          expect(r[0].time.day, now.day);
          expect(r[0].time.hour, now.hour);
        },
      );
    });

    test('should return ServerFailure when service throws exception', () async {
      // Arrange
      final fakeService = FakeOpenMeteoWeatherService(error: Exception('API Error'));
      repository = WeatherRepositoryImpl(fakeService);

      // Act
      final result = await repository.getHourlyForecast(tLocation);

      // Assert
      expect(result, isA<Left<Failure, List<HourlyForecast>>>());
    });
  });
}
