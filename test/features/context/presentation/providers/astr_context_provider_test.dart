import 'package:astr/core/error/failure.dart';
import 'package:astr/core/services/i_location_service.dart';
import 'package:astr/core/services/location_service_provider.dart';
import 'package:astr/features/context/domain/entities/astr_context.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'astr_context_provider_test.mocks.dart';

@GenerateMocks([ILocationService])
void main() {
  late MockILocationService mockLocationService;

  setUp(() {
    provideDummy<Either<Failure, GeoLocation>>(
      const Right(GeoLocation(latitude: 0, longitude: 0, name: 'Dummy')),
    );
    mockLocationService = MockILocationService();
  });

  ProviderContainer makeProviderContainer(MockILocationService locationService) {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(locationService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AstrContextNotifier', () {
    test('initial state loads current location', () async {
      // Arrange
      const tLocation = GeoLocation(
        latitude: 10.0,
        longitude: 20.0,
        name: 'Test City',
      );
      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => const Right(tLocation));

      final container = makeProviderContainer(mockLocationService);
      final listener = container.listen(astrContextProvider, (previous, next) {});

      // Act
      // Wait for the async build to complete
      await container.read(astrContextProvider.future);

      // Assert
      final state = container.read(astrContextProvider);
      expect(state.value?.location, tLocation);
      expect(state.value?.isCurrentLocation, true);
    });

    test('updateDate updates the selectedDate in state', () async {
      // Arrange
      const tLocation = GeoLocation(
        latitude: 10.0,
        longitude: 20.0,
        name: 'Test City',
      );
      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => const Right(tLocation));

      final container = makeProviderContainer(mockLocationService);
      
      // Wait for initialization
      await container.read(astrContextProvider.future);

      // Act
      final newDate = DateTime(2025, 12, 25);
      container.read(astrContextProvider.notifier).updateDate(newDate);

      // Assert
      final state = container.read(astrContextProvider);
      expect(state.value?.selectedDate, newDate);
    });
  });
}
