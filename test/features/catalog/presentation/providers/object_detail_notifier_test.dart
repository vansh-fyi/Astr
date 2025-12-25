import 'package:astr/core/error/failure.dart';
import 'package:astr/features/catalog/domain/entities/celestial_object.dart';
import 'package:astr/features/catalog/domain/entities/celestial_type.dart';
import 'package:astr/features/catalog/domain/repositories/i_catalog_repository.dart';
import 'package:astr/features/catalog/presentation/providers/object_detail_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'object_detail_notifier_test.mocks.dart';

class MockRef extends Mock implements Ref {}

@GenerateMocks(<Type>[ICatalogRepository])
void main() {
  late MockICatalogRepository mockRepository;
  late ObjectDetailNotifier notifier;

  const CelestialObject testObject = CelestialObject(
    id: 'mars',
    name: 'Mars',
    type: CelestialType.planet,
    iconPath: 'assets/icons/planets/mars.png',
    magnitude: -2.9,
    ephemerisId: 4,
  );

  setUpAll(() {
    // Provide dummy value for Either type
    provideDummy<Either<Failure, CelestialObject>>(
      right(testObject),
    );
  });

  setUp(() {
    mockRepository = MockICatalogRepository();
  });

  group('ObjectDetailNotifier', () {
    test('loads object successfully', () async {
      // Arrange
      when(mockRepository.getObjectById('mars'))
          .thenAnswer((_) async => right(testObject));

      // Act
      notifier = ObjectDetailNotifier(mockRepository, MockRef(), 'mars');
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(notifier.state.object, testObject);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, null);
      verify(mockRepository.getObjectById('mars')).called(1);
    });

    test('handles non-existent object ID', () async {
      // Arrange
      when(mockRepository.getObjectById('nonexistent'))
          .thenAnswer((_) async => left(const CacheFailure('Object not found')));

      // Act
      notifier = ObjectDetailNotifier(mockRepository, MockRef(), 'nonexistent');
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(notifier.state.object, null);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, 'Object not found');
      verify(mockRepository.getObjectById('nonexistent')).called(1);
    });

    test('sets isLoading to true initially', () {
      // Arrange
      when(mockRepository.getObjectById('mars'))
          .thenAnswer((_) async => right(testObject));

      // Act
      notifier = ObjectDetailNotifier(mockRepository, MockRef(), 'mars');

      // Assert (before async completes)
      expect(notifier.state.isLoading, true);
    });
  });
}
