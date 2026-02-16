import 'package:astr/core/error/failure.dart';
import 'package:astr/core/services/i_location_service.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/data_layer/models/zone_data.dart';
import 'package:astr/features/data_layer/services/h3_service.dart';
import 'package:astr/features/data_layer/repositories/cached_zone_repository.dart';
import 'package:astr/features/splash/domain/entities/launch_result.dart';
import 'package:astr/features/splash/domain/services/smart_launch_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'smart_launch_controller_test.mocks.dart';

@GenerateMocks([ILocationService, H3Service, CachedZoneRepository])
void main() {
  // Provide dummy values for types Mockito can't auto-generate
  provideDummy<Either<Failure, GeoLocation>>(
    const Left(LocationFailure('Dummy failure')),
  );
  provideDummy<BigInt>(BigInt.from(0));
  group('SmartLaunchController', () {
    late SmartLaunchController controller;
    late MockILocationService mockLocationService;
    late MockH3Service mockH3Service;
    late MockCachedZoneRepository mockZoneRepository;

    setUp(() {
      mockLocationService = MockILocationService();
      mockH3Service = MockH3Service();
      mockZoneRepository = MockCachedZoneRepository();

      controller = SmartLaunchController(
        locationService: mockLocationService,
        h3Service: mockH3Service,
        zoneRepository: mockZoneRepository,
      );
    });

    group('Success Path', () {
      test('should return LaunchSuccess with all data when everything succeeds', () async {
        // Arrange: Mock successful location
        final mockLocation = GeoLocation(latitude: 37.7749, longitude: -122.4194);
        when(mockLocationService.getCurrentLocation())
            .thenAnswer((_) async => Right(mockLocation));

        // Mock H3 index calculation
        final mockH3Index = BigInt.from(617700169958293503);
        when(mockH3Service.latLonToH3(37.7749, -122.4194, 8))
            .thenReturn(mockH3Index);

        // Mock zone data fetch
        final mockZoneData = ZoneData(
          bortleClass: 4,
          sqm: 20.5,
          ratio: 0.12,
        );
        when(mockZoneRepository.getZoneData(mockH3Index))
            .thenAnswer((_) async => mockZoneData);

        // Act
        final result = await controller.executeLaunch();

        // Assert
        expect(result, isA<LaunchSuccess>());
        final success = result as LaunchSuccess;
        expect(success.location, equals(mockLocation));
        expect(success.h3Index, equals(mockH3Index.toString()));
        expect(success.zoneData, equals(mockZoneData));

        // Verify service calls in order
        verify(mockLocationService.getCurrentLocation()).called(1);
        verify(mockH3Service.latLonToH3(37.7749, -122.4194, 8)).called(1);
        verify(mockZoneRepository.getZoneData(mockH3Index)).called(1);
      });

      test('should use resolution 8 for H3 index (PRD requirement)', () async {
        // Arrange
        final mockLocation = GeoLocation(latitude: 0.0, longitude: 0.0);
        when(mockLocationService.getCurrentLocation())
            .thenAnswer((_) async => Right(mockLocation));

        final mockH3Index = BigInt.from(617700169958293503);
        when(mockH3Service.latLonToH3(0.0, 0.0, 8)).thenReturn(mockH3Index);

        final mockZoneData = ZoneData(
          bortleClass: 1,
          sqm: 22.0,
          ratio: 0.0,
        );
        when(mockZoneRepository.getZoneData(mockH3Index))
            .thenAnswer((_) async => mockZoneData);

        // Act
        await controller.executeLaunch();

        // Assert: Verify resolution 8 was used (PRD spec)
        verify(mockH3Service.latLonToH3(0.0, 0.0, 8)).called(1);
      });
    });

    group('GPS Timeout Path', () {
      test('should return LaunchTimeout when GPS timeout occurs', () async {
        // Arrange: Mock GPS timeout (NFR-10)
        when(mockLocationService.getCurrentLocation()).thenAnswer(
          (_) async => const Left(
            TimeoutFailure('GPS Unavailable. Restart or hit Refresh.'),
          ),
        );

        // Act
        final result = await controller.executeLaunch();

        // Assert
        expect(result, isA<LaunchTimeout>());
        verify(mockLocationService.getCurrentLocation()).called(1);

        // Verify H3 and zone data services NOT called
        verifyNever(mockH3Service.latLonToH3(any, any, any));
        verifyNever(mockZoneRepository.getZoneData(any));
      });

      test('should detect TimeoutFailure specifically (not generic Failure)', () async {
        // Arrange
        when(mockLocationService.getCurrentLocation()).thenAnswer(
          (_) async => const Left(TimeoutFailure('GPS Unavailable. Restart or hit Refresh.')),
        );

        // Act
        final result = await controller.executeLaunch();

        // Assert: TimeoutFailure → LaunchTimeout
        expect(result, isA<LaunchTimeout>());
        expect(result, isNot(isA<LaunchPermissionDenied>()));
        expect(result, isNot(isA<LaunchServiceDisabled>()));
      });
    });

    group('Permission Denied Path', () {
      test('should return LaunchPermissionDenied when permission denied', () async {
        // Arrange
        when(mockLocationService.getCurrentLocation()).thenAnswer(
          (_) async => const Left(PermissionFailure('Location permissions are denied')),
        );

        // Act
        final result = await controller.executeLaunch();

        // Assert
        expect(result, isA<LaunchPermissionDenied>());
        verify(mockLocationService.getCurrentLocation()).called(1);

        // Verify H3 and zone data services NOT called
        verifyNever(mockH3Service.latLonToH3(any, any, any));
        verifyNever(mockZoneRepository.getZoneData(any));
      });

      test('should handle permanently denied permission', () async {
        // Arrange
        when(mockLocationService.getCurrentLocation()).thenAnswer(
          (_) async => const Left(
            PermissionFailure('Location permissions are permanently denied'),
          ),
        );

        // Act
        final result = await controller.executeLaunch();

        // Assert: All PermissionFailure types → LaunchPermissionDenied
        expect(result, isA<LaunchPermissionDenied>());
      });
    });

    group('Service Disabled Path', () {
      test('should return LaunchServiceDisabled when location service disabled', () async {
        // Arrange
        when(mockLocationService.getCurrentLocation()).thenAnswer(
          (_) async => const Left(LocationFailure('Location services are disabled.')),
        );

        // Act
        final result = await controller.executeLaunch();

        // Assert
        expect(result, isA<LaunchServiceDisabled>());
        verify(mockLocationService.getCurrentLocation()).called(1);

        // Verify H3 and zone data services NOT called
        verifyNever(mockH3Service.latLonToH3(any, any, any));
        verifyNever(mockZoneRepository.getZoneData(any));
      });
    });

    group('Zone Data Failure Path', () {
      test('should return LaunchTimeout when zone data fetch fails (silent fail)', () async {
        // Arrange: Location succeeds, H3 succeeds, zone data fails
        final mockLocation = GeoLocation(latitude: 37.7749, longitude: -122.4194);
        when(mockLocationService.getCurrentLocation())
            .thenAnswer((_) async => Right(mockLocation));

        final mockH3Index = BigInt.from(617700169958293503);
        when(mockH3Service.latLonToH3(37.7749, -122.4194, 8))
            .thenReturn(mockH3Index);

        // Mock zone data failure (e.g., database read error)
        when(mockZoneRepository.getZoneData(mockH3Index)).thenThrow(
          RangeError('H3 index not found in zones.db'),
        );

        // Act
        final result = await controller.executeLaunch();

        // Assert: Silent fail on zone data (Epic 3 pattern)
        expect(result, isA<LaunchTimeout>());

        // Verify all services were attempted
        verify(mockLocationService.getCurrentLocation()).called(1);
        verify(mockH3Service.latLonToH3(37.7749, -122.4194, 8)).called(1);
        verify(mockZoneRepository.getZoneData(mockH3Index)).called(1);
      });

      test('should handle zone data cache miss gracefully', () async {
        // Arrange
        final mockLocation = GeoLocation(latitude: 0.0, longitude: 0.0);
        when(mockLocationService.getCurrentLocation())
            .thenAnswer((_) async => Right(mockLocation));

        final mockH3Index = BigInt.from(617700169958293503);
        when(mockH3Service.latLonToH3(0.0, 0.0, 8)).thenReturn(mockH3Index);

        when(mockZoneRepository.getZoneData(mockH3Index)).thenThrow(
          FormatException('Zone data not found'),
        );

        // Act
        final result = await controller.executeLaunch();

        // Assert: Treat cache miss as partial failure
        expect(result, isA<LaunchTimeout>());
      });
    });

    group('H3 Calculation Edge Cases', () {
      test('should handle H3 calculation error and return LaunchTimeout', () async {
        // Arrange: Location succeeds, but H3 throws error
        final mockLocation = GeoLocation(latitude: 90.0, longitude: 0.0); // North Pole
        when(mockLocationService.getCurrentLocation())
            .thenAnswer((_) async => Right(mockLocation));

        // Mock H3 throwing error on edge coordinate
        when(mockH3Service.latLonToH3(90.0, 0.0, 8))
            .thenThrow(ArgumentError('Invalid coordinate'));

        // Act
        final result = await controller.executeLaunch();

        // Assert: H3 error → LaunchTimeout
        expect(result, isA<LaunchTimeout>());
        verify(mockLocationService.getCurrentLocation()).called(1);
        verify(mockH3Service.latLonToH3(90.0, 0.0, 8)).called(1);

        // Zone data NOT called (H3 failed first)
        verifyNever(mockZoneRepository.getZoneData(any));
      });

      test('should handle dateline coordinate gracefully', () async {
        // Arrange: Coordinate at International Date Line
        final mockLocation = GeoLocation(latitude: 0.0, longitude: 180.0);
        when(mockLocationService.getCurrentLocation())
            .thenAnswer((_) async => Right(mockLocation));

        final mockH3Index = BigInt.from(617700169958293503);
        when(mockH3Service.latLonToH3(0.0, 180.0, 8)).thenReturn(mockH3Index);

        final mockZoneData = ZoneData(
          bortleClass: 1,
          sqm: 22.0,
          ratio: 0.0,
        );
        when(mockZoneRepository.getZoneData(mockH3Index))
            .thenAnswer((_) async => mockZoneData);

        // Act
        final result = await controller.executeLaunch();

        // Assert: Should handle dateline correctly
        expect(result, isA<LaunchSuccess>());
      });
    });

    group('Service Call Order', () {
      test('should call services in correct sequence: Location → H3 → ZoneData', () async {
        // Arrange
        final callOrder = <String>[];

        final mockLocation = GeoLocation(latitude: 0.0, longitude: 0.0);
        when(mockLocationService.getCurrentLocation()).thenAnswer((_) async {
          callOrder.add('location');
          return Right(mockLocation);
        });

        final mockH3Index = BigInt.from(617700169958293503);
        when(mockH3Service.latLonToH3(0.0, 0.0, 8)).thenAnswer((_) {
          callOrder.add('h3');
          return mockH3Index;
        });

        final mockZoneData = ZoneData(
          bortleClass: 1,
          sqm: 22.0,
          ratio: 0.0,
        );
        when(mockZoneRepository.getZoneData(mockH3Index)).thenAnswer((_) async {
          callOrder.add('zoneData');
          return mockZoneData;
        });

        // Act
        await controller.executeLaunch();

        // Assert: Verify exact sequence
        expect(callOrder, equals(['location', 'h3', 'zoneData']));
      });

      test('should short-circuit on location failure (no H3/zone calls)', () async {
        // Arrange
        when(mockLocationService.getCurrentLocation()).thenAnswer(
          (_) async => const Left(PermissionFailure('Denied')),
        );

        // Act
        await controller.executeLaunch();

        // Assert: Only location service called
        verify(mockLocationService.getCurrentLocation()).called(1);
        verifyZeroInteractions(mockH3Service);
        verifyZeroInteractions(mockZoneRepository);
      });
    });
  });
}
