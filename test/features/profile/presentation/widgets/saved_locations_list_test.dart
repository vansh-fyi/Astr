import 'package:astr/core/error/failure.dart';
import 'package:astr/features/profile/data/repositories/profile_repository.dart';
import 'package:astr/features/profile/domain/entities/saved_location.dart';
import 'package:astr/features/profile/presentation/widgets/saved_locations_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:go_router/go_router.dart';
import 'package:astr/core/services/i_location_service.dart';
import 'package:astr/core/services/location_service_provider.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';

import 'saved_locations_list_test.mocks.dart';

@GenerateMocks([ProfileRepository, ILocationService])
void main() {
  late MockProfileRepository mockRepository;
  late MockILocationService mockLocationService;

  setUp(() {
    mockRepository = MockProfileRepository();
    mockLocationService = MockILocationService();
    
    provideDummy<Either<Failure, void>>(Right<Failure, void>(null));
    provideDummy<Either<Failure, List<SavedLocation>>>(Right<Failure, List<SavedLocation>>(<SavedLocation>[]));
    provideDummy<SavedLocation>(
      SavedLocation(
        id: 'dummy',
        name: 'Dummy',
        latitude: 0,
        longitude: 0,
        createdAt: DateTime.now(),
      ),
    );
    provideDummy<Either<Failure, GeoLocation>>(
      const Right(GeoLocation(latitude: 0, longitude: 0, name: 'Dummy')),
    );
  });

  final tSavedLocation = SavedLocation(
    id: '1',
    name: 'Test Location',
    latitude: 10.0,
    longitude: 20.0,
    createdAt: DateTime.now(),
  );

  testWidgets('SavedLocationsList displays locations', (tester) async {
    when(mockRepository.getSavedLocations())
        .thenAnswer((_) async => Right([tSavedLocation]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SavedLocationsList()),
        ),
      ),
    );

    // Initial load
    await tester.pump(); // Start future
    await tester.pump(); // Finish future

    expect(find.text('Saved Locations'), findsOneWidget);
    expect(find.text('Test Location'), findsOneWidget);
  });

  testWidgets('SavedLocationsList displays empty state', (tester) async {
    when(mockRepository.getSavedLocations())
        .thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SavedLocationsList()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No saved locations'), findsOneWidget);
  });

  testWidgets('Tapping a location updates context and navigates', (tester) async {
    // Arrange
    when(mockRepository.getSavedLocations())
        .thenAnswer((_) async => Right([tSavedLocation]));
    
    // Stub the location service to return a dummy location (or whatever is needed for initialization)
    when(mockLocationService.getCurrentLocation())
        .thenAnswer((_) async => const Right(GeoLocation(latitude: 0, longitude: 0, name: 'Default')));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(mockRepository),
          locationServiceProvider.overrideWithValue(mockLocationService),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('Home'))),
              GoRoute(path: '/profile', builder: (_, __) => const Scaffold(body: SavedLocationsList())),
            ],
            initialLocation: '/profile',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('Test Location'));
    await tester.pumpAndSettle();

    // Assert
    // Verify we navigated to Home
    expect(find.text('Home'), findsOneWidget);
  });
}
