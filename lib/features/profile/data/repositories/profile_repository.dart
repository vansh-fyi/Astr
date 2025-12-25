import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/saved_location.dart';

part 'profile_repository.g.dart';

@riverpod
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  return ProfileRepository(Hive.box<SavedLocation>('locations'));
}

class ProfileRepository {

  ProfileRepository(this._locationsBox);
  final Box<SavedLocation> _locationsBox;

  Future<Either<Failure, void>> saveLocation(SavedLocation location) async {
    try {
      await _locationsBox.put(location.id, location);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<Either<Failure, List<SavedLocation>>> getSavedLocations() async {
    try {
      final List<SavedLocation> locations = _locationsBox.values.toList();
      return Right(locations);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> deleteLocation(String id) async {
    try {
      await _locationsBox.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
