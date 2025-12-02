import 'package:astr/features/astronomy/domain/services/astronomy_service.dart';
import 'package:astr/features/catalog/data/services/visibility_service_impl.dart';
import 'package:astr/features/catalog/domain/entities/celestial_object.dart';
import 'package:astr/features/catalog/domain/entities/celestial_type.dart';
import 'package:astr/features/catalog/domain/entities/graph_point.dart';
import 'package:astr/features/catalog/domain/entities/visibility_graph_data.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'visibility_service_impl_test.mocks.dart';

@GenerateMocks([AstronomyService])
void main() {
  late MockAstronomyService mockAstronomyService;
  late VisibilityServiceImpl service;

  const testObject = CelestialObject(
    id: 'mars',
    name: 'Mars',
    type: CelestialType.planet,
    iconPath: 'assets/icons/planets/mars.png',
    magnitude: -2.9,
    ephemerisId: 4, // Mars
  );

  const testDSO = CelestialObject(
    id: 'andromeda',
    name: 'Andromeda',
    type: CelestialType.galaxy,
    iconPath: 'assets/icons/constellations/andromeda.png',
    magnitude: 3.44,
    ra: 10.68,
    dec: 41.27,
  );

  const testLocation = GeoLocation(
    latitude: 37.7749,
    longitude: -122.4194,
    name: 'San Francisco',
  );

  final testStartTime = DateTime(2025, 11, 29, 18, 0); // 6 PM

  setUp(() {
    mockAstronomyService = MockAstronomyService();
    service = VisibilityServiceImpl(mockAstronomyService);
  });

  group('calculateVisibility', () {
    test('returns correct number of points (48 for 12h at 15min intervals)',
        () async {
      // Arrange
      when(mockAstronomyService.calculateAltitudeTrajectory(
        body: anyNamed('body'),
        startTime: anyNamed('startTime'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
        duration: anyNamed('duration'),
      )).thenAnswer((_) async => List.generate(48, (i) => GraphPoint(time: testStartTime, value: 45.0)));

      when(mockAstronomyService.calculateMoonTrajectory(
        startTime: anyNamed('startTime'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
        duration: anyNamed('duration'),
      )).thenAnswer((_) async => List.generate(48, (i) => GraphPoint(time: testStartTime, value: 0.0)));

      when(mockAstronomyService.calculateRiseSetTransit(
        body: anyNamed('body'),
        date: anyNamed('date'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
      )).thenAnswer((_) async => {'rise': null, 'set': null});

      // Act
      final result = await service.calculateVisibility(
        object: testObject,
        location: testLocation,
        startTime: testStartTime,
      );

      // Assert
      expect(result.isRight(), true);
      final graphData = result.getRight().getOrElse(() => throw Exception());
      expect(graphData.objectCurve.length, 48);
      expect(graphData.moonCurve.length, 48);
    });

    test('correctly identifies Prime Window when object > 30° and moon low',
        () async {
      // Arrange
      when(mockAstronomyService.calculateAltitudeTrajectory(
        body: anyNamed('body'),
        startTime: anyNamed('startTime'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
        duration: anyNamed('duration'),
      )).thenAnswer((_) async => List.generate(48, (i) {
            // First half: altitude > 30° (optimal)
            // Second half: altitude < 30° (not optimal)
            return GraphPoint(time: testStartTime.add(Duration(minutes: i * 15)), value: i < 24 ? 45.0 : 25.0);
          }));

      when(mockAstronomyService.calculateMoonTrajectory(
        startTime: anyNamed('startTime'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
        duration: anyNamed('duration'),
      )).thenAnswer((_) async => List.generate(48, (i) => GraphPoint(time: testStartTime, value: 0.0)));

      when(mockAstronomyService.calculateRiseSetTransit(
        body: anyNamed('body'),
        date: anyNamed('date'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
      )).thenAnswer((_) async => {'rise': null, 'set': null});

      // Act
      final result = await service.calculateVisibility(
        object: testObject,
        location: testLocation,
        startTime: testStartTime,
      );

      // Assert
      expect(result.isRight(), true);
      final graphData = result.getRight().getOrElse(() => throw Exception());
      expect(graphData.optimalWindows.isNotEmpty, true);
    });

    test('supports Deep Sky Objects (DSOs) using RA/Dec', () async {
      // Arrange
      when(mockAstronomyService.calculateFixedObjectTrajectory(
        ra: anyNamed('ra'),
        dec: anyNamed('dec'),
        startTime: anyNamed('startTime'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
        duration: anyNamed('duration'),
      )).thenAnswer((_) async => List.generate(48, (i) => GraphPoint(time: testStartTime, value: 50.0)));

      when(mockAstronomyService.calculateMoonTrajectory(
        startTime: anyNamed('startTime'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
        duration: anyNamed('duration'),
      )).thenAnswer((_) async => List.generate(48, (i) => GraphPoint(time: testStartTime, value: 0.0)));

      when(mockAstronomyService.calculateRiseSetTransit(
        body: anyNamed('body'),
        date: anyNamed('date'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
      )).thenAnswer((_) async => {'rise': null, 'set': null});

      // Act
      final result = await service.calculateVisibility(
        object: testDSO,
        location: testLocation,
        startTime: testStartTime,
      );

      // Assert
      expect(result.isRight(), true);
      final graphData = result.getRight().getOrElse(() => throw Exception());
      expect(graphData.objectCurve.length, 48);
      // Verify calculateFixedObjectTrajectory was called
      verify(mockAstronomyService.calculateFixedObjectTrajectory(
        ra: testDSO.ra!,
        dec: testDSO.dec!,
        startTime: anyNamed('startTime'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
        duration: anyNamed('duration'),
      )).called(1);
    });

    test('returns failure when astro engine fails', () async {
      // Arrange
      when(mockAstronomyService.calculateAltitudeTrajectory(
        body: anyNamed('body'),
        startTime: anyNamed('startTime'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
        duration: anyNamed('duration'),
      )).thenThrow(Exception('Engine error'));

      // Act
      final result = await service.calculateVisibility(
        object: testObject,
        location: testLocation,
        startTime: testStartTime,
      );

      // Assert
      expect(result.isLeft(), true);
    });
  });

  group('Performance', () {
    test('calculateVisibility completes in < 200ms (AC #9)', () async {
      // Arrange
      when(mockAstronomyService.calculateAltitudeTrajectory(
        body: anyNamed('body'),
        startTime: anyNamed('startTime'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
        duration: anyNamed('duration'),
      )).thenAnswer((_) async => List.generate(48, (i) => GraphPoint(time: testStartTime, value: 45.0)));

      when(mockAstronomyService.calculateMoonTrajectory(
        startTime: anyNamed('startTime'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
        duration: anyNamed('duration'),
      )).thenAnswer((_) async => List.generate(48, (i) => GraphPoint(time: testStartTime, value: 0.0)));

      when(mockAstronomyService.calculateRiseSetTransit(
        body: anyNamed('body'),
        date: anyNamed('date'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
      )).thenAnswer((_) async => {'rise': null, 'set': null});

      // Act
      final stopwatch = Stopwatch()..start();
      final result = await service.calculateVisibility(
        object: testObject,
        location: testLocation,
        startTime: testStartTime,
      );
      stopwatch.stop();

      // Assert
      expect(result.isRight(), true);
      print('Performance: calculateVisibility completed in ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });
  });
}
