import 'package:astr/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:astr/features/catalog/domain/entities/celestial_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CatalogRepositoryImpl repository;

  setUp(() {
    repository = CatalogRepositoryImpl();
  });

  group('CatalogRepositoryImpl', () {
    test('getObjectsByType returns correct planets', () async {
      // Act
      final result = await repository.getObjectsByType(CelestialType.planet);

      // Assert
      result.fold(
        (failure) => fail('Expected Right but got Left: ${failure.message}'),
        (objects) {
          expect(objects.length, 8); // Mercury to Neptune + Moon
          expect(objects.every((obj) => obj.type == CelestialType.planet), true);
          expect(objects.any((obj) => obj.name == 'Mars'), true);
          expect(objects.any((obj) => obj.name == 'Jupiter'), true);
        },
      );
    });

    test('getObjectsByType returns correct stars', () async {
      // Act
      final result = await repository.getObjectsByType(CelestialType.star);

      // Assert
      result.fold(
        (failure) => fail('Expected Right but got Left: ${failure.message}'),
        (objects) {
          expect(objects.length, 11); // Top 10 stars + Sun
          expect(objects.every((obj) => obj.type == CelestialType.star), true);
          expect(objects.any((obj) => obj.name == 'Sirius'), true);
          expect(objects.any((obj) => obj.name == 'Vega'), true);
        },
      );
    });

    test('getObjectsByType returns correct constellations', () async {
      // Act
      final result = await repository.getObjectsByType(CelestialType.constellation);

      // Assert
      result.fold(
        (failure) => fail('Expected Right but got Left: ${failure.message}'),
        (objects) {
          expect(objects.length, 10); // Top 10 constellations
          expect(objects.every((obj) => obj.type == CelestialType.constellation), true);
          expect(objects.any((obj) => obj.name == 'Orion'), true);
          expect(objects.any((obj) => obj.name == 'Ursa Major'), true);
        },
      );
    });

    test('getObjectsByType returns correct galaxies', () async {
      // Act
      final result = await repository.getObjectsByType(CelestialType.galaxy);

      // Assert
      result.fold(
        (failure) => fail('Expected Right but got Left: ${failure.message}'),
        (objects) {
          expect(objects.length, 1);
          expect(objects.first.name, contains('Andromeda'));
        },
      );
    });

    test('getObjectsByType returns correct nebulae', () async {
      // Act
      final result = await repository.getObjectsByType(CelestialType.nebula);

      // Assert
      result.fold(
        (failure) => fail('Expected Right but got Left: ${failure.message}'),
        (objects) {
          expect(objects.length, 1);
          expect(objects.first.name, contains('Orion Nebula'));
        },
      );
    });

    test('getObjectsByType returns correct clusters', () async {
      // Act
      final result = await repository.getObjectsByType(CelestialType.cluster);

      // Assert
      result.fold(
        (failure) => fail('Expected Right but got Left: ${failure.message}'),
        (objects) {
          expect(objects.length, 1);
          expect(objects.first.name, contains('Pleiades'));
        },
      );
    });

    test('getObjectById returns correct object', () async {
      // Act
      final result = await repository.getObjectById('mars');

      // Assert
      result.fold(
        (failure) => fail('Expected Right but got Left: ${failure.message}'),
        (object) {
          expect(object.id, 'mars');
          expect(object.name, 'Mars');
          expect(object.type, CelestialType.planet);
        },
      );
    });

    test('getObjectById returns failure for non-existent object', () async {
      // Act
      final result = await repository.getObjectById('nonexistent');

      // Assert
      result.fold(
        (failure) {
          expect(failure.message, contains('not found'));
        },
        (object) => fail('Expected Left but got Right'),
      );
    });

    test('getAllObjects returns complete catalog', () async {
      // Act
      final result = await repository.getAllObjects();

      // Assert
      result.fold(
        (failure) => fail('Expected Right but got Left: ${failure.message}'),
        (objects) {
          // 2 (Sun/Moon) + 7 planets + 10 stars + 10 constellations + 1 galaxy + 1 nebula + 1 cluster = 32
          expect(objects.length, 32); 
        },
      );
    });

    test('Constellations should have RA/Dec coordinates', () async {
      final result = await repository.getObjectById('orion');
      result.fold(
        (failure) => fail('Expected Right'),
        (orion) {
          expect(orion.ra, isNotNull);
          expect(orion.dec, isNotNull);
        },
      );
    });
  });
}
