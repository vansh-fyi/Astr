import 'package:astr/core/error/failure.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/dashboard/data/datasources/png_map_service.dart';
import 'package:astr/features/dashboard/data/repositories/light_pollution_repository.dart';
import 'package:astr/features/dashboard/domain/entities/light_pollution.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'light_pollution_repository_test.mocks.dart';

@GenerateMocks([Dio, PngMapService])
void main() {
  late LightPollutionRepository repository;
  late MockDio mockDio;
  late MockPngMapService mockPngService;

  setUp(() {
    mockDio = MockDio();
    mockPngService = MockPngMapService();
    repository = LightPollutionRepository(mockDio, mockPngService);
  });

  const tLocation = GeoLocation(latitude: 0, longitude: 0);
  const tLightPollution = LightPollution(
    visibilityIndex: 4,
    brightnessRatio: 0.0,
    mpsas: 20.8,
    source: LightPollutionSource.precise,
    zone: "4",
  );

  group('getLightPollution', () {
    test('should return API data when call is successful', () async {
      // Arrange
      when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: ''),
                statusCode: 200,
                data: {'bortle': 4, 'mpsas': 20.8},
              ));

      // Act
      final result = await repository.getLightPollution(tLocation);

      // Assert
      verify(mockDio.get(
        'https://astr-backend.vercel.app/api/light-pollution',
        queryParameters: {'lat': 0.0, 'lon': 0.0},
      ));
      expect(result, equals(const Right(tLightPollution)));
      verifyZeroInteractions(mockPngService);
    });

    test('should return PNG fallback when API call fails', () async {
      // Arrange
      when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
          .thenThrow(DioException(requestOptions: RequestOptions(path: '')));
      when(mockPngService.getLightPollution(any))
          .thenAnswer((_) async => tLightPollution);

      // Act
      final result = await repository.getLightPollution(tLocation);

      // Assert
      verify(mockDio.get(any, queryParameters: anyNamed('queryParameters')));
      verify(mockPngService.getLightPollution(tLocation));
      expect(result, equals(const Right(tLightPollution)));
    });

    test('should return Failure when both API and Fallback fail', () async {
      // Arrange
      when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
          .thenThrow(DioException(requestOptions: RequestOptions(path: '')));
      when(mockPngService.getLightPollution(any)).thenThrow(Exception());

      // Act
      final result = await repository.getLightPollution(tLocation);

      // Assert
      expect(result.isLeft(), true);
    });
  });
}
