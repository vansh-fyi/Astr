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

import 'astr_context_test.mocks.dart';

@GenerateMocks(<Type>[ILocationService])
void main() {
  late MockILocationService mockLocationService;
  late ProviderContainer container;

  setUp(() {
    provideDummy<Either<Failure, GeoLocation>>(
      const Right(GeoLocation(latitude: 0, longitude: 0)),
    );
    mockLocationService = MockILocationService();
    container = ProviderContainer(overrides: <Override>[
      locationServiceProvider.overrideWithValue(mockLocationService),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('AstrContextNotifier', () {
    test('initial state loads current location', () async {
      // Arrange
      const GeoLocation location = GeoLocation(latitude: 10, longitude: 20);
      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => const Right(location));

      // Act
      final AstrContextNotifier notifier = container.read(astrContextProvider.notifier);
      // Wait for the build to complete
      final AstrContext initialState = await container.read(astrContextProvider.future);

      // Assert
      expect(initialState.location, location);
      expect(initialState.isCurrentLocation, true);
    });

    test('updateDate updates the date', () async {
      // Arrange
      const GeoLocation location = GeoLocation(latitude: 10, longitude: 20);
      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => const Right(location));
      
      // Ensure initial load completes
      await container.read(astrContextProvider.future);

      // Act
      final DateTime newDate = DateTime(2025);
      container.read(astrContextProvider.notifier).updateDate(newDate);

      // Assert
      final AsyncValue<AstrContext> state = container.read(astrContextProvider);
      expect(state.value!.selectedDate, newDate);
    });
  });
}
