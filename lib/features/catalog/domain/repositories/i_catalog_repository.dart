import 'package:astr/core/error/failure.dart';
import 'package:astr/features/catalog/domain/entities/celestial_object.dart';
import 'package:astr/features/catalog/domain/entities/celestial_type.dart';
import 'package:fpdart/fpdart.dart';

/// Repository interface for accessing celestial object catalog
abstract class ICatalogRepository {
  /// Returns all celestial objects of a specific type
  Future<Either<Failure, List<CelestialObject>>> getObjectsByType(
    CelestialType type,
  );

  /// Returns a celestial object by its ID
  Future<Either<Failure, CelestialObject>> getObjectById(String id);

  /// Returns all celestial objects in the catalog
  Future<Either<Failure, List<CelestialObject>>> getAllObjects();
}
