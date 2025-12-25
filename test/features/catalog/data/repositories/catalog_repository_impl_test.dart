import 'package:astr/core/error/failure.dart';
import 'package:astr/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:astr/features/catalog/domain/entities/celestial_object.dart';
import 'package:astr/features/catalog/domain/entities/celestial_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/src/either.dart';

void main() {
  late CatalogRepositoryImpl repository;

  setUp(() {
    repository = CatalogRepositoryImpl();
  });

  group('CatalogRepositoryImpl', () {
    test('getObjectsByType returns correct planets', () async {
      // Act
      final Either<Failure, List<CelestialObject>> result = await repository.getObjectsByType(CelestialType.planet);

      // Assert
      result.fold(
        (Failure failure) => fail('Expected Right but got Left: ${failure.message}'),
        (List<CelestialObject> objects) {
          expect(objects.length, 8); // Mercury to Neptune + Moon
          expect(objects.every((CelestialObject obj) => obj.type == CelestialType.planet), true);
          expect(objects.any((CelestialObject obj) => obj.name == 'Mars'), true);
          expect(objects.any((CelestialObject obj) => obj.name == 'Jupiter'), true);
        },
      );
    });

    test('getObjectsByType returns correct stars', () async {
      // Act
      final Either<Failure, List<CelestialObject>> result = await repository.getObjectsByType(CelestialType.star);

      // Assert
      result.fold(
        (Failure failure) => fail('Expected Right but got Left: ${failure.message}'),
        (List<CelestialObject> objects) {
          expect(objects.length, 11); // Top 10 stars + Sun
          expect(objects.every((CelestialObject obj) => obj.type == CelestialType.star), true);
          expect(objects.any((CelestialObject obj) => obj.name == 'Sirius'), true);
          expect(objects.any((CelestialObject obj) => obj.name == 'Vega'), true);
        },
      );
    });

    test('getObjectsByType returns correct constellations', () async {
      // Act
      final Either<Failure, List<CelestialObject>> result = await repository.getObjectsByType(CelestialType.constellation);

      // Assert
      result.fold(
        (Failure failure) => fail('Expected Right but got Left: ${failure.message}'),
        (List<CelestialObject> objects) {
          expect(objects.length, 10); // Top 10 constellations
          expect(objects.every((CelestialObject obj) => obj.type == CelestialType.constellation), true);
          expect(objects.any((CelestialObject obj) => obj.name == 'Orion'), true);
          expect(objects.any((CelestialObject obj) => obj.name == 'Ursa Major'), true);
        },
      );
    });

    test('getObjectsByType returns correct galaxies', () async {
      // Act
      final Either<Failure, List<CelestialObject>> result = await repository.getObjectsByType(CelestialType.galaxy);

      // Assert
      result.fold(
        (Failure failure) => fail('Expected Right but got Left: ${failure.message}'),
        (List<CelestialObject> objects) {
          expect(objects.length, 1);
          expect(objects.first.name, contains('Andromeda'));
        },
      );
    });

    test('getObjectsByType returns correct nebulae', () async {
      // Act
      final Either<Failure, List<CelestialObject>> result = await repository.getObjectsByType(CelestialType.nebula);

      // Assert
      result.fold(
        (Failure failure) => fail('Expected Right but got Left: ${failure.message}'),
        (List<CelestialObject> objects) {
          expect(objects.length, 1);
          expect(objects.first.name, contains('Orion Nebula'));
        },
      );
    });

    test('getObjectsByType returns correct clusters', () async {
      // Act
      final Either<Failure, List<CelestialObject>> result = await repository.getObjectsByType(CelestialType.cluster);

      // Assert
      result.fold(
        (Failure failure) => fail('Expected Right but got Left: ${failure.message}'),
        (List<CelestialObject> objects) {
          expect(objects.length, 1);
          expect(objects.first.name, contains('Pleiades'));
        },
      );
    });

    test('getObjectById returns correct object', () async {
      // Act
      final Either<Failure, CelestialObject> result = await repository.getObjectById('mars');

      // Assert
      result.fold(
        (Failure failure) => fail('Expected Right but got Left: ${failure.message}'),
        (CelestialObject object) {
          expect(object.id, 'mars');
          expect(object.name, 'Mars');
          expect(object.type, CelestialType.planet);
        },
      );
    });

    test('getObjectById returns failure for non-existent object', () async {
      // Act
      final Either<Failure, CelestialObject> result = await repository.getObjectById('nonexistent');

      // Assert
      result.fold(
        (Failure failure) {
          expect(failure.message, contains('not found'));
        },
        (CelestialObject object) => fail('Expected Left but got Right'),
      );
    });

    test('getAllObjects returns complete catalog', () async {
      // Act
      final Either<Failure, List<CelestialObject>> result = await repository.getAllObjects();

      // Assert
      result.fold(
        (Failure failure) => fail('Expected Right but got Left: ${failure.message}'),
        (List<CelestialObject> objects) {
          // 2 (Sun/Moon) + 7 planets + 10 stars + 10 constellations + 1 galaxy + 1 nebula + 1 cluster = 32
          expect(objects.length, 32); 
        },
      );
    });

    test('Constellations should have RA/Dec coordinates', () async {
      final Either<Failure, CelestialObject> result = await repository.getObjectById('orion');
      result.fold(
        (Failure failure) => fail('Expected Right'),
        (CelestialObject orion) {
          expect(orion.ra, isNotNull);
          expect(orion.dec, isNotNull);
        },
      );
    });
  });
}
