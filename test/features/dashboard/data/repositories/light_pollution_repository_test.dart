import 'package:astr/core/error/failure.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/dashboard/data/repositories/light_pollution_repository.dart';
import 'package:astr/features/dashboard/domain/entities/light_pollution.dart';
import 'package:astr/features/data_layer/models/zone_data.dart';
import 'package:astr/features/data_layer/repositories/cached_zone_repository.dart';
import 'package:astr/features/data_layer/services/h3_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCachedZoneRepository extends Mock implements CachedZoneRepository {}

class MockH3Service extends Mock implements H3Service {}

void main() {
  late LightPollutionRepository repository;
  late MockCachedZoneRepository mockZoneRepository;
  late MockH3Service mockH3Service;

  const GeoLocation testLocation =
      GeoLocation(latitude: 40.7128, longitude: -74.0060);
  final BigInt testH3Index = BigInt.from(0x882a100d63fffff);

  setUp(() {
    mockZoneRepository = MockCachedZoneRepository();
    mockH3Service = MockH3Service();

    repository = LightPollutionRepository(
      zoneRepository: mockZoneRepository,
      h3Service: mockH3Service,
    );

    // Default: H3 conversion succeeds
    when(() => mockH3Service.latLonToH3(
          testLocation.latitude,
          testLocation.longitude,
          8,
        )).thenReturn(testH3Index);
  });

  group('getLightPollution', () {
    test('returns LightPollution with zone data from repository', () async {
      // Arrange: Zone data for a lit area (Zone 7)
      final ZoneData zoneData =
          ZoneData(bortleClass: 7, ratio: 5.5, sqm: 18.2);
      when(() => mockZoneRepository.getZoneData(testH3Index))
          .thenAnswer((_) async => zoneData);

      // Act
      final Either<Failure, LightPollution> result =
          await repository.getLightPollution(testLocation);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (Failure failure) =>
            fail('Expected Right, got Left: ${failure.message}'),
        (LightPollution lp) {
          expect(lp.visibilityIndex, 7);
          expect(lp.brightnessRatio, 5.5);
          expect(lp.mpsas, 18.2);
          expect(lp.source, LightPollutionSource.precise);
        },
      );

      verify(() => mockH3Service.latLonToH3(
            testLocation.latitude,
            testLocation.longitude,
            8,
          )).called(1);
      verify(() => mockZoneRepository.getZoneData(testH3Index)).called(1);
    });

    test('returns Zone 1 (estimated) for pristine dark sky locations',
        () async {
      // Arrange: Not in database → pristineDarkSky default
      final ZoneData pristine =
          ZoneData(bortleClass: 1, ratio: 0.0, sqm: 22.0);
      when(() => mockZoneRepository.getZoneData(testH3Index))
          .thenAnswer((_) async => pristine);

      // Act
      final Either<Failure, LightPollution> result =
          await repository.getLightPollution(testLocation);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (Failure failure) =>
            fail('Expected Right, got Left: ${failure.message}'),
        (LightPollution lp) {
          expect(lp.visibilityIndex, 1);
          expect(lp.source, LightPollutionSource.estimated);
        },
      );
    });

    test('returns Failure when H3 conversion throws', () async {
      // Arrange
      when(() => mockH3Service.latLonToH3(
            testLocation.latitude,
            testLocation.longitude,
            8,
          )).thenThrow(RangeError('Invalid coordinates'));

      // Act
      final Either<Failure, LightPollution> result =
          await repository.getLightPollution(testLocation);

      // Assert
      expect(result.isLeft(), true);
    });

    test('returns Failure when zone repository throws', () async {
      // Arrange
      when(() => mockZoneRepository.getZoneData(testH3Index))
          .thenThrow(Exception('Database error'));

      // Act
      final Either<Failure, LightPollution> result =
          await repository.getLightPollution(testLocation);

      // Assert
      expect(result.isLeft(), true);
    });
  });
}
