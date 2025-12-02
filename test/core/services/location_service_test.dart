import 'package:astr/core/error/failure.dart';
import 'package:astr/core/services/device_location_service.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';



class MockGeolocatorPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() {
    return super.noSuchMethod(
      Invocation.method(#isLocationServiceEnabled, []),
      returnValue: Future.value(false),
    );
  }

  @override
  Future<LocationPermission> checkPermission() {
    return super.noSuchMethod(
      Invocation.method(#checkPermission, []),
      returnValue: Future.value(LocationPermission.denied),
    );
  }

  @override
  Future<LocationPermission> requestPermission() {
    return super.noSuchMethod(
      Invocation.method(#requestPermission, []),
      returnValue: Future.value(LocationPermission.denied),
    );
  }

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    return super.noSuchMethod(
      Invocation.method(#getCurrentPosition, [],
          {#locationSettings: locationSettings}),
      returnValue: Future.value(Position(
          longitude: 0,
          latitude: 0,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0)),
    );
  }
}

void main() {
  late DeviceLocationService service;
  late MockGeolocatorPlatform mockGeolocatorPlatform;

  setUp(() {
    mockGeolocatorPlatform = MockGeolocatorPlatform();
    reset(mockGeolocatorPlatform);
    GeolocatorPlatform.instance = mockGeolocatorPlatform;
    service = DeviceLocationService();
  });

  group('DeviceLocationService', () {
    test('returns GeoLocation when permission granted and service enabled', () async {
      // Arrange
      when(mockGeolocatorPlatform.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(mockGeolocatorPlatform.checkPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      when(mockGeolocatorPlatform.getCurrentPosition(
        locationSettings: anyNamed('locationSettings'),
      )).thenAnswer((_) async => Position(
            longitude: 10.0,
            latitude: 20.0,
            timestamp: DateTime.now(),
            accuracy: 0.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          ));

      // Act
      final result = await service.getCurrentLocation();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (r) => expect(r, const GeoLocation(latitude: 20.0, longitude: 10.0)),
      );
    });

    test('returns LocationFailure when service disabled', () async {
      // Arrange
      when(mockGeolocatorPlatform.isLocationServiceEnabled())
          .thenAnswer((_) async => false);

      // Act
      final result = await service.getCurrentLocation();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<LocationFailure>()),
        (r) => fail('Should be Left'),
      );
    });

    test('returns PermissionFailure when permission denied', () async {
      // Arrange
      when(mockGeolocatorPlatform.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(mockGeolocatorPlatform.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      when(mockGeolocatorPlatform.requestPermission())
          .thenAnswer((_) async => LocationPermission.denied);

      // Act
      final result = await service.getCurrentLocation();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<PermissionFailure>()),
        (r) => fail('Should be Left'),
      );
    });
  });
}
