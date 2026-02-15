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
import 'package:flutter/services.dart';

@GenerateMocks(<Type>[ILocationService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockILocationService mockLocationService;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return '.';
    });
    
    // Mock get_storage channel if needed, typically 'get_storage'
    // But mostly it's path_provider causing issues for GetStorage init
    
    provideDummy<Either<Failure, GeoLocation>>(
      const Right(GeoLocation(latitude: 0, longitude: 0, name: 'Dummy')),
    );
    mockLocationService = MockILocationService();
  });

  ProviderContainer makeProviderContainer(MockILocationService locationService) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        locationServiceProvider.overrideWithValue(locationService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AstrContextNotifier', () {
    test('initial state loads current location', () async {
      // Arrange
      const GeoLocation tLocation = GeoLocation(
        latitude: 10,
        longitude: 20,
        name: 'Test City',
      );
      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => const Right(tLocation));

      final ProviderContainer container = makeProviderContainer(mockLocationService);
      final ProviderSubscription<AsyncValue<AstrContext>> listener = container.listen(astrContextProvider, (AsyncValue<AstrContext>? previous, AsyncValue<AstrContext> next) {});

      // Act
      // Wait for the async build to complete
      await container.read(astrContextProvider.future);

      // Assert
      final AsyncValue<AstrContext> state = container.read(astrContextProvider);
      expect(state.value?.location, tLocation);
      expect(state.value?.isCurrentLocation, true);
    });

    test('updateDate updates the selectedDate in state', () async {
      // Arrange
      const GeoLocation tLocation = GeoLocation(
        latitude: 10,
        longitude: 20,
        name: 'Test City',
      );
      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => const Right(tLocation));

      final ProviderContainer container = makeProviderContainer(mockLocationService);
      
      // Wait for initialization
      await container.read(astrContextProvider.future);

      // Act
      final DateTime newDate = DateTime(2025, 12, 25);
      container.read(astrContextProvider.notifier).updateDate(newDate);

      // Assert
      final AsyncValue<AstrContext> state = container.read(astrContextProvider);
      expect(state.value?.selectedDate, newDate);
    });
  });
}
