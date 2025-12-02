import 'package:astr/features/profile/data/repositories/profile_repository.dart';
import 'package:astr/features/profile/domain/entities/saved_location.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'profile_repository_test.mocks.dart';

@GenerateMocks([Box])
void main() {
  late ProfileRepository repository;
  late MockBox<SavedLocation> mockBox;

  setUp(() {
    mockBox = MockBox<SavedLocation>();
    repository = ProfileRepository(mockBox);
  });

  final tSavedLocation = SavedLocation(
    id: '1',
    name: 'Test Location',
    latitude: 10.0,
    longitude: 20.0,
    createdAt: DateTime.now(),
  );

  group('saveLocation', () {
    test('should save location to box', () async {
      // Arrange
      when(mockBox.put(any, any)).thenAnswer((_) async => {});

      // Act
      final result = await repository.saveLocation(tSavedLocation);

      // Assert
      verify(mockBox.put(tSavedLocation.id, tSavedLocation));
      expect(result.isRight(), true);
    });

    test('should save location with null bortleClass', () async {
      // Arrange
      final tLocationNullBortle = SavedLocation(
        id: '2',
        name: 'Null Bortle',
        latitude: 0,
        longitude: 0,
        createdAt: DateTime.now(),
        bortleClass: null,
      );
      when(mockBox.put(any, any)).thenAnswer((_) async => {});

      // Act
      final result = await repository.saveLocation(tLocationNullBortle);

      // Assert
      verify(mockBox.put(tLocationNullBortle.id, tLocationNullBortle));
      expect(result.isRight(), true);
    });
  });

  group('getSavedLocations', () {
    test('should return list of locations', () async {
      // Arrange
      when(mockBox.values).thenReturn([tSavedLocation]);

      // Act
      final result = await repository.getSavedLocations();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return failure'),
        (r) => expect(r, [tSavedLocation]),
      );
    });
  });

  group('deleteLocation', () {
    test('should delete location from box', () async {
      // Arrange
      when(mockBox.delete(any)).thenAnswer((_) async => {});

      // Act
      final result = await repository.deleteLocation('1');

      // Assert
      verify(mockBox.delete('1'));
      expect(result.isRight(), true);
    });
  });
}
