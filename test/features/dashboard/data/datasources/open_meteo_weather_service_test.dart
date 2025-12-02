import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:astr/features/dashboard/data/datasources/open_meteo_weather_service.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';

import 'open_meteo_weather_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late OpenMeteoWeatherService service;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    service = OpenMeteoWeatherService(mockDio);
  });

  const tLocation = GeoLocation(latitude: 52.52, longitude: 13.41);

  test('should return cloud cover when the response code is 200', () async {
    // arrange
    when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
        .thenAnswer((_) async => Response(
              data: {
                'current': {'cloud_cover': 45}
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

    // act
    final result = await service.getCloudCover(tLocation);

    // assert
    expect(result, 45.0);
  });

  test('should throw an exception when the response code is not 200', () async {
    // arrange
    when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
        .thenAnswer((_) async => Response(
              data: 'Something went wrong',
              statusCode: 404,
              requestOptions: RequestOptions(path: ''),
            ));

    // act
    final call = service.getCloudCover;

    // assert
    expect(() => call(tLocation), throwsException);
  });
}
