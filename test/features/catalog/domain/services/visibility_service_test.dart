import 'package:astr/core/error/failure.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_body.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_position.dart';
import 'package:astr/features/astronomy/domain/repositories/i_astro_engine.dart';
import 'package:astr/features/catalog/data/services/visibility_service_impl.dart';
import 'package:astr/features/catalog/domain/entities/celestial_object.dart';
import 'package:astr/features/catalog/domain/entities/celestial_type.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'visibility_service_test.mocks.dart';

@GenerateMocks([IAstroEngine])
void main() {
  late VisibilityServiceImpl visibilityService;
  late MockIAstroEngine mockAstroEngine;

  setUp(() {
    mockAstroEngine = MockIAstroEngine();
    visibilityService = VisibilityServiceImpl(mockAstroEngine);

    // Default setup for Either types in mockito
    provideDummy<Either<Failure, CelestialPosition>>(
      Right(CelestialPosition(
        body: CelestialBody.sun, 
        time: DateTime.now(), 
        azimuth: 0, 
        altitude: 0, 
        distance: 0, 
        magnitude: 0
      )),
    );
    provideDummy<Either<Failure, double>>(const Right(0.0));
  });

  const tCelestialObject = CelestialObject(
    id: 'mars',
    name: 'Mars',
    type: CelestialType.planet,
    iconPath: 'assets/icons/planets/mars.png',
    magnitude: -2.9,
    ephemerisId: 4, // Mars
  );

  const tLocation = GeoLocation(
    latitude: 40.7128,
    longitude: -74.0060,
    name: 'New York',
  );

  final tStartTime = DateTime(2025, 11, 29, 18, 0); // 6:00 PM

  group('calculateVisibility', () {
    test('should return VisibilityGraphData with 48 points (12h / 15min)',
        () async {
      // Arrange
      // Mock object position (always rising)
      when(mockAstroEngine.getPosition(
        body: CelestialBody.mars,
        time: anyNamed('time'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => Right(
            CelestialPosition(
              body: CelestialBody.mars,
              time: DateTime.now(),
              azimuth: 100, 
              altitude: 45, 
              distance: 1,
              magnitude: 0
            ),
          ));

      // Mock moon position (below horizon)
      when(mockAstroEngine.getPosition(
        body: CelestialBody.moon,
        time: anyNamed('time'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => Right(
            CelestialPosition(
              body: CelestialBody.moon,
              time: DateTime.now(),
              azimuth: 200, 
              altitude: -10, 
              distance: 1,
              magnitude: 0
            ),
          ));

      // Mock moon illumination
      when(mockAstroEngine.getMoonIllumination(time: anyNamed('time')))
          .thenAnswer((_) async => const Right(50.0));

      // Act
      final result = await visibilityService.calculateVisibility(
        object: tCelestialObject,
        location: tLocation,
        startTime: tStartTime,
      );

      // Assert
      expect(result.isRight(), true);
      final graphData = result.getRight().toNullable()!;
      expect(graphData.objectCurve.length, 48);
      expect(graphData.moonCurve.length, 48);
      
      // Verify intervals
      final firstPoint = graphData.objectCurve.first;
      final secondPoint = graphData.objectCurve[1];
      expect(secondPoint.time.difference(firstPoint.time).inMinutes, 15);
    });

    test('should calculate moon interference correctly', () async {
      // Arrange
      // Object at 45 deg
      when(mockAstroEngine.getPosition(
        body: CelestialBody.mars,
        time: anyNamed('time'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => Right(
            CelestialPosition(
              body: CelestialBody.mars,
              time: DateTime.now(),
              azimuth: 100, 
              altitude: 45, 
              distance: 1,
              magnitude: 0
            ),
          ));

      // Moon at 60 deg altitude
      when(mockAstroEngine.getPosition(
        body: CelestialBody.moon,
        time: anyNamed('time'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => Right(
            CelestialPosition(
              body: CelestialBody.moon,
              time: DateTime.now(),
              azimuth: 200, 
              altitude: 60, 
              distance: 1,
              magnitude: 0
            ),
          ));

      // Moon 50% illuminated
      when(mockAstroEngine.getMoonIllumination(time: anyNamed('time')))
          .thenAnswer((_) async => const Right(50.0));

      // Act
      final result = await visibilityService.calculateVisibility(
        object: tCelestialObject,
        location: tLocation,
        startTime: tStartTime,
      );

      // Assert
      final graphData = result.getRight().toNullable()!;
      // Expected interference: 60 * 50 / 100 = 30.0
      expect(graphData.moonCurve.first.value, 30.0);
    });

    test('should identify Prime Window (Object > 30 AND Interference < 30)',
        () async {
      // Arrange
      // Object at 45 deg (> 30)
      when(mockAstroEngine.getPosition(
        body: CelestialBody.mars,
        time: anyNamed('time'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => Right(
            CelestialPosition(
              body: CelestialBody.mars,
              time: DateTime.now(),
              azimuth: 100, 
              altitude: 45, 
              distance: 1,
              magnitude: 0
            ),
          ));

      // Moon below horizon (interference 0 < 30)
      when(mockAstroEngine.getPosition(
        body: CelestialBody.moon,
        time: anyNamed('time'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => Right(
            CelestialPosition(
              body: CelestialBody.moon,
              time: DateTime.now(),
              azimuth: 200, 
              altitude: -10, 
              distance: 1,
              magnitude: 0
            ),
          ));

      when(mockAstroEngine.getMoonIllumination(time: anyNamed('time')))
          .thenAnswer((_) async => const Right(50.0));

      // Act
      final result = await visibilityService.calculateVisibility(
        object: tCelestialObject,
        location: tLocation,
        startTime: tStartTime,
      );

      // Assert
      final graphData = result.getRight().toNullable()!;
      expect(graphData.optimalWindows.isNotEmpty, true);
      // Should cover the whole range since conditions are constant
      expect(graphData.optimalWindows.first.duration.inHours, 12);
    });

    test('should NOT identify Prime Window if Object < 30', () async {
      // Arrange
      // Object at 20 deg (< 30)
      when(mockAstroEngine.getPosition(
        body: CelestialBody.mars,
        time: anyNamed('time'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => Right(
            CelestialPosition(
              body: CelestialBody.mars,
              time: DateTime.now(),
              azimuth: 100, 
              altitude: 20, 
              distance: 1,
              magnitude: 0
            ),
          ));

      // Moon below horizon (interference 0)
      when(mockAstroEngine.getPosition(
        body: CelestialBody.moon,
        time: anyNamed('time'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => Right(
            CelestialPosition(
              body: CelestialBody.moon,
              time: DateTime.now(),
              azimuth: 200, 
              altitude: -10, 
              distance: 1,
              magnitude: 0
            ),
          ));

      when(mockAstroEngine.getMoonIllumination(time: anyNamed('time')))
          .thenAnswer((_) async => const Right(50.0));

      // Act
      final result = await visibilityService.calculateVisibility(
        object: tCelestialObject,
        location: tLocation,
        startTime: tStartTime,
      );

      // Assert
      final graphData = result.getRight().toNullable()!;
      expect(graphData.optimalWindows.isEmpty, true);
    });

    test('should NOT identify Prime Window if Interference > 30', () async {
      // Arrange
      // Object at 45 deg (> 30)
      when(mockAstroEngine.getPosition(
        body: CelestialBody.mars,
        time: anyNamed('time'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => Right(
            CelestialPosition(
              body: CelestialBody.mars,
              time: DateTime.now(),
              azimuth: 100, 
              altitude: 45, 
              distance: 1,
              magnitude: 0
            ),
          ));

      // Moon at 80 deg, 100% illuminated -> 80 * 1.0 = 80 interference (> 30)
      when(mockAstroEngine.getPosition(
        body: CelestialBody.moon,
        time: anyNamed('time'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => Right(
            CelestialPosition(
              body: CelestialBody.moon,
              time: DateTime.now(),
              azimuth: 200, 
              altitude: 80, 
              distance: 1,
              magnitude: 0
            ),
          ));

      when(mockAstroEngine.getMoonIllumination(time: anyNamed('time')))
          .thenAnswer((_) async => const Right(100.0));

      // Act
      final result = await visibilityService.calculateVisibility(
        object: tCelestialObject,
        location: tLocation,
        startTime: tStartTime,
      );

      // Assert
      final graphData = result.getRight().toNullable()!;
      expect(graphData.optimalWindows.isEmpty, true);
    });
  });
}