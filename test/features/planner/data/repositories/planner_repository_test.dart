import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:astr/features/planner/data/repositories/planner_repository.dart';
import 'package:astr/features/planner/domain/logic/planner_logic.dart';
import 'package:astr/features/dashboard/data/datasources/open_meteo_weather_service.dart';
import 'package:astr/features/astronomy/domain/repositories/i_astro_engine.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/astronomy/domain/entities/moon_phase_info.dart';
import 'package:astr/core/error/failure.dart';
import 'package:mockito/mockito.dart';

import 'package:dio/dio.dart';

class MockDio extends Mock implements Dio {}

// Stub classes instead of Mockito Mocks to avoid null-safety issues with manual mocks
class StubWeatherService extends OpenMeteoWeatherService {
  StubWeatherService() : super(MockDio()); 

  Map<String, dynamic>? response;
  Exception? error;

  @override
  Future<Map<String, dynamic>> getHourlyForecast(GeoLocation location) async {
    if (error != null) throw error!;
    return response!;
  }
}

class StubAstroEngine implements IAstroEngine {
  double moonIllumination = 0.0;

  @override
  Future<Either<Failure, MoonPhaseInfo>> getMoonPhaseInfo({required DateTime time}) async {
    return Right(MoonPhaseInfo(
      illumination: moonIllumination,
      phaseAngle: 0.0,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late PlannerRepository repository;
  late StubWeatherService stubWeatherService;
  late StubAstroEngine stubAstroEngine;
  late PlannerLogic plannerLogic;

  setUp(() {
    stubWeatherService = StubWeatherService();
    stubAstroEngine = StubAstroEngine();
    plannerLogic = PlannerLogic();
    repository = PlannerRepository(stubWeatherService, stubAstroEngine, plannerLogic);
  });

  final tLocation = GeoLocation(latitude: 0, longitude: 0, name: 'Test');

  group('PlannerRepository', () {
    test('should return list of 7 DailyForecasts when API calls succeed', () async {
      // Arrange
      final times = List.generate(168, (i) => DateTime.now().add(Duration(hours: i)).toIso8601String());
      final cloudCovers = List.generate(168, (i) => 10.0);
      final weatherCodes = List.generate(168, (i) => 0.0);

      stubWeatherService.response = {
        'time': times,
        'cloudCover': cloudCovers,
        'weatherCode': weatherCodes,
        'temperature': List.filled(168, 20.0),
        'humidity': List.filled(168, 50.0),
        'windSpeed': List.filled(168, 5.0),
      };

      stubAstroEngine.moonIllumination = 0.5;

      // Act
      final result = await repository.get7DayForecast(tLocation, 1); // Bortle 1

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return failure'),
        (r) {
          expect(r.length, 7);
          expect(r[0].cloudCoverAvg, 10.0);
          expect(r[0].moonIllumination, 0.5);
          // Score = 100 - 10 - (0.5 * 30) - 0 = 75 -> 4 stars
          expect(r[0].starRating, 4);
        },
      );
    });

    test('should return Failure when WeatherService fails', () async {
      // Arrange
      stubWeatherService.error = Exception('API Error');

      // Act
      final result = await repository.get7DayForecast(tLocation, 1);

      // Assert
      expect(result.isLeft(), true);
    });
  });
}
