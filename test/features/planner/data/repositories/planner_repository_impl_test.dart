import 'dart:convert';
import 'package:astr/core/error/failure.dart';
import 'package:astr/features/planner/data/repositories/planner_repository_impl.dart';
import 'package:astr/features/planner/domain/entities/daily_forecast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'planner_repository_impl_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late PlannerRepositoryImpl repository;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    repository = PlannerRepositoryImpl(client: mockClient);
  });

  group('get7DayForecast', () {
    const tLat = 52.52;
    const tLong = 13.41;
    final tDate = DateTime.parse('2023-10-10');
    
    final tDailyForecastList = [
      DailyForecast(
        date: tDate,
        cloudCoverAvg: 15.0,
        moonIllumination: 0.0,
        weatherCode: '3',
        starRating: 5, // < 20% clouds
      ),
    ];

    test('should return List<DailyForecast> when the call to API is successful', () async {
      // Arrange
      when(mockClient.get(any)).thenAnswer((_) async => http.Response(
            json.encode({
              'daily': {
                'time': ['2023-10-10'],
                'weathercode': [3],
                'cloudcover_mean': [15.0],
                'precipitation_probability_max': [0]
              }
            }),
            200,
          ));

      // Act
      final result = await repository.get7DayForecast(latitude: tLat, longitude: tLong);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (r) => expect(r, equals(tDailyForecastList)),
      );
      verify(mockClient.get(any));
    });

    test('should return ServerFailure when the call to API is unsuccessful', () async {
      // Arrange
      when(mockClient.get(any)).thenAnswer((_) async => http.Response('Something went wrong', 500));

      // Act
      final result = await repository.get7DayForecast(latitude: tLat, longitude: tLong);

      // Assert
      expect(result, isA<Left<Failure, List<DailyForecast>>>());
    });
  });
}
