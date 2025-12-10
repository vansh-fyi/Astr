import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:astr/core/engine/models/location.dart';
import 'package:astr/core/engine/models/result.dart';
import 'package:astr/core/services/light_pollution/light_pollution_service.dart';
import 'package:astr/core/services/light_pollution/data/online_lp_data_source.dart';
import 'package:astr/core/services/light_pollution/data/offline_lp_data_source.dart';

import 'light_pollution_service_test.mocks.dart';

@GenerateMocks([OnlineLPDataSource, OfflineLPDataSource])
void main() {
  late LightPollutionService service;
  late MockOnlineLPDataSource mockOnlineSource;
  late MockOfflineLPDataSource mockOfflineSource;
  late Location testLocation;

  setUp(() {
    mockOnlineSource = MockOnlineLPDataSource();
    mockOfflineSource = MockOfflineLPDataSource();
    service = LightPollutionService(
      onlineSource: mockOnlineSource,
      offlineSource: mockOfflineSource,
    );
    testLocation = const Location(latitude: 40.7128, longitude: -74.0060);
  });

  group('Hybrid Logic (AC#1)', () {
    test('Online success → Returns online result, offline NOT called', () async {
      // Arrange
      when(mockOnlineSource.getBortleClass(testLocation))
          .thenAnswer((_) async => 5);

      // Act
      final result = await service.getBortleClass(testLocation);

      // Assert
      expect(result.isSuccess, true);
      expect(result.value, 5);
      verify(mockOnlineSource.getBortleClass(testLocation)).called(1);
      verifyNever(mockOfflineSource.getBortleClass(any));
    });

    test('Online failure → Fallback to offline, returns offline result', () async {
      // Arrange
      when(mockOnlineSource.getBortleClass(testLocation))
          .thenAnswer((_) async => null);
      when(mockOfflineSource.getBortleClass(testLocation))
          .thenAnswer((_) async => 7);

      // Act
      final result = await service.getBortleClass(testLocation);

      // Assert
      expect(result.isSuccess, true);
      expect(result.value, 7);
      verify(mockOnlineSource.getBortleClass(testLocation)).called(1);
      verify(mockOfflineSource.getBortleClass(testLocation)).called(1);
    });
  });

  group('Error Handling (AC#6)', () {
    test('Both sources fail → Returns Result.failure', () async {
      // Arrange
      when(mockOnlineSource.getBortleClass(testLocation))
          .thenAnswer((_) async => null);
      when(mockOfflineSource.getBortleClass(testLocation))
          .thenAnswer((_) async => null);

      // Act
      final result = await service.getBortleClass(testLocation);

      // Assert
      expect(result.isFailure, true);
      expect(result.failure.message, contains('both online and offline sources failed'));
      verify(mockOnlineSource.getBortleClass(testLocation)).called(1);
      verify(mockOfflineSource.getBortleClass(testLocation)).called(1);
    });

    test('Online timeout → Fallback to offline succeeds', () async {
      // Arrange
      when(mockOnlineSource.getBortleClass(testLocation))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 4));
        return null;
      });
      when(mockOfflineSource.getBortleClass(testLocation))
          .thenAnswer((_) async => 3);

      // Act
      final result = await service.getBortleClass(testLocation);

      // Assert
      expect(result.isSuccess, true);
      expect(result.value, 3);
    });
  });

  group('Multiple Locations', () {
    test('Correctly handles different locations', () async {
      // Arrange
      final nyc = const Location(latitude: 40.7128, longitude: -74.0060);
      final desert = const Location(latitude: 35.0, longitude: -110.0);

      when(mockOnlineSource.getBortleClass(nyc))
          .thenAnswer((_) async => 9);
      when(mockOnlineSource.getBortleClass(desert))
          .thenAnswer((_) async => 1);

      // Act
      final nycResult = await service.getBortleClass(nyc);
      final desertResult = await service.getBortleClass(desert);

      // Assert
      expect(nycResult.value, 9);
      expect(desertResult.value, 1);
    });
  });
}
