import 'package:astr/core/error/failure.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_body.dart';
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

import 'visibility_service_test.mocks.dart';

@GenerateMocks(<Type>[AstronomyService])
void main() {
  late VisibilityServiceImpl visibilityService;
  late MockAstronomyService mockAstronomyService;

  setUp(() {
    mockAstronomyService = MockAstronomyService();
    visibilityService = VisibilityServiceImpl(mockAstronomyService);
  });

  const CelestialObject tCelestialObject = CelestialObject(
    id: 'mars',
    name: 'Mars',
    type: CelestialType.planet,
    iconPath: 'assets/icons/planets/mars.png',
    magnitude: -2.9,
    ephemerisId: 4, // Mars
  );

  const GeoLocation tLocation = GeoLocation(
    latitude: 40.7128,
    longitude: -74.0060,
    name: 'New York',
  );

  final DateTime tStartTime = DateTime(2025, 11, 29, 18); // 6:00 PM

  List<GraphPoint> createTrajectory(double value, int count) {
    return List.generate(count, (i) => GraphPoint(
        time: tStartTime.add(Duration(minutes: 15 * i)),
        value: value,
    ));
  }

  group('calculateVisibility', () {
    test('should return VisibilityGraphData with 48 points (12h / 15min)',
        () async {
      // Arrange
      // Mock object trajectory (always rising)
      final objectPoints = createTrajectory(45, 48);
      when(mockAstronomyService.calculateAltitudeTrajectory(
        body: anyNamed('body'),

        startTime: anyNamed('startTime'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
        duration: anyNamed('duration'),
      )).thenAnswer((_) async => objectPoints);

      // Mock moon trajectory (below horizon)
      final moonPoints = createTrajectory(-10, 48);
      when(mockAstronomyService.calculateMoonTrajectory(
        startTime: anyNamed('startTime'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
        duration: anyNamed('duration'),
      )).thenAnswer((_) async => moonPoints);

      // Mock Rise/Set
      when(mockAstronomyService.calculateRiseSetTransit(
        body: anyNamed('body'),
        date: anyNamed('date'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
      )).thenAnswer((_) async => {'rise': tStartTime, 'set': tStartTime.add(const Duration(hours: 12))});

      // Act
      final Either<Failure, VisibilityGraphData> result = await visibilityService.calculateVisibility(
        object: tCelestialObject,
        location: tLocation,
        startTime: tStartTime,
      );

      // Assert
      expect(result.isRight(), true);
      final VisibilityGraphData graphData = result.getRight().toNullable()!;
      expect(graphData.objectCurve.length, 48);
      expect(graphData.moonCurve.length, 48);
      
      // Verify intervals
      final GraphPoint firstPoint = graphData.objectCurve.first;
      final GraphPoint secondPoint = graphData.objectCurve[1];
      expect(secondPoint.time.difference(firstPoint.time).inMinutes, 15);
    });

    test('should calculate moon interference correctly', () async {
      // Arrange
      // Object at 45 deg
      final objectPoints = createTrajectory(45, 48);
      when(mockAstronomyService.calculateAltitudeTrajectory(
        body: anyNamed('body'),

        startTime: anyNamed('startTime'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
        duration: anyNamed('duration'),
      )).thenAnswer((_) async => objectPoints);

      // Moon interference (simulate 30.0 interference by returning 30.0 value directly 
      // since service logic expects moonCurve to be calculated and returned by AstroService)
      // Note: VisibilityServiceImpl expects calculateMoonTrajectory to return Moon INTERFERENCE curve?
      // No, it returns Moon ALTITUDE usually?
      // Let's check Implementation logic.
      // Line 65: `moonCurve = await _astronomyService.calculateMoonTrajectory(...)`.
      // Line 86: `final double moonInterference = moonPoint.value;`.
      // So yes, the service expects `calculateMoonTrajectory` to return the INTERFERENCE value (or it treats the return value as interference).
      // If `calculateMoonTrajectory` returns altitude, then logic is simplified/wrong in service or tests.
      // But assuming `calculateMoonTrajectory` returns what logic consumes:
      final moonPoints = createTrajectory(30.0, 48);
      when(mockAstronomyService.calculateMoonTrajectory(
        startTime: anyNamed('startTime'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
        duration: anyNamed('duration'),
      )).thenAnswer((_) async => moonPoints);

      when(mockAstronomyService.calculateRiseSetTransit(
        body: anyNamed('body'),
        date: anyNamed('date'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
      )).thenAnswer((_) async => {'rise': null, 'set': null});

      // Act
      final result = await visibilityService.calculateVisibility(
        object: tCelestialObject,
        location: tLocation,
        startTime: tStartTime,
      );

      // Assert
      final VisibilityGraphData graphData = result.getRight().toNullable()!;
      expect(graphData.moonCurve.first.value, 30.0);
    });

    test('should identify Prime Window (Object > 30 AND Interference < 30)',
        () async {
      // Object > 30
      final objectPoints = createTrajectory(45, 48);
      when(mockAstronomyService.calculateAltitudeTrajectory(
        body: anyNamed('body'),

        startTime: anyNamed('startTime'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
        duration: anyNamed('duration'),
      )).thenAnswer((_) async => objectPoints);

      // Interference < 30
      final moonPoints = createTrajectory(10, 48);
      when(mockAstronomyService.calculateMoonTrajectory(
        startTime: anyNamed('startTime'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
        duration: anyNamed('duration'),
      )).thenAnswer((_) async => moonPoints);

      when(mockAstronomyService.calculateRiseSetTransit(
        body: anyNamed('body'),
        date: anyNamed('date'),
        lat: anyNamed('lat'),
        long: anyNamed('long'),
      )).thenAnswer((_) async => {'rise': null, 'set': null});

      // Act
      final result = await visibilityService.calculateVisibility(
        object: tCelestialObject,
        location: tLocation,
        startTime: tStartTime,
      );

      // Assert
      final VisibilityGraphData graphData = result.getRight().toNullable()!;
      expect(graphData.optimalWindows.isNotEmpty, true);
      // 48 points at 15-min intervals: last point at 47*15=705 min = 11h45m
      // Duration.inHours truncates to 11
      expect(graphData.optimalWindows.first.duration.inHours, 11);
    });
  });
}