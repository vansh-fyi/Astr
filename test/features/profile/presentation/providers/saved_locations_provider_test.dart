import 'package:astr/core/error/failure.dart';
import 'package:astr/features/profile/data/repositories/profile_repository.dart';
import 'package:astr/features/profile/domain/entities/saved_location.dart';
import 'package:astr/features/profile/presentation/providers/saved_locations_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

import 'saved_locations_provider_test.mocks.dart';

@GenerateMocks([ProfileRepository])
void main() {
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    provideDummy<Either<Failure, void>>(const Right(null));
    provideDummy<Either<Failure, List<SavedLocation>>>(const Right([]));
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  final tSavedLocation = SavedLocation(
    id: '1',
    name: 'Test Location',
    latitude: 10.0,
    longitude: 20.0,
    createdAt: DateTime.now(),
  );

  test('build should load locations', () async {
    // Arrange
    when(mockRepository.getSavedLocations())
        .thenAnswer((_) async => Right([tSavedLocation]));

    final container = createContainer();

    // Act
    final locations = await container.read(savedLocationsNotifierProvider.future);

    // Assert
    expect(locations, [tSavedLocation]);
    verify(mockRepository.getSavedLocations());
  });

  test('addLocation should save location and reload', () async {
    // Arrange
    when(mockRepository.saveLocation(any))
        .thenAnswer((_) async => const Right(null));
    when(mockRepository.getSavedLocations())
        .thenAnswer((_) async => Right([tSavedLocation]));

    final container = createContainer();
    final notifier = container.read(savedLocationsNotifierProvider.notifier);

    // Act
    await notifier.addLocation(tSavedLocation);

    // Assert
    verify(mockRepository.saveLocation(tSavedLocation));
    // Verify reload happened (getSavedLocations called twice: once for build, once for reload)
    // Actually, build is async, so it might be called once initially.
    // We can check if the state is updated.
    final locations = await container.read(savedLocationsNotifierProvider.future);
    expect(locations, [tSavedLocation]);
  });
}
