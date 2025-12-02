import 'package:astr/features/profile/data/repositories/profile_repository.dart';
import 'package:astr/features/profile/domain/entities/saved_location.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saved_locations_provider.g.dart';

@riverpod
class SavedLocationsNotifier extends _$SavedLocationsNotifier {
  @override
  Future<List<SavedLocation>> build() async {
    return _loadLocations();
  }

  Future<List<SavedLocation>> _loadLocations() async {
    final repository = ref.read(profileRepositoryProvider);
    final result = await repository.getSavedLocations();
    return result.fold(
      (failure) => [], // Handle error: return empty list for now
      (locations) => locations,
    );
  }

  Future<void> addLocation(SavedLocation location) async {
    final repository = ref.read(profileRepositoryProvider);
    final result = await repository.saveLocation(location);
    result.fold(
      (failure) => null, // Handle error
      (_) => ref.invalidateSelf(), // Reload list
    );
  }

  Future<void> deleteLocation(String id) async {
    final repository = ref.read(profileRepositoryProvider);
    final result = await repository.deleteLocation(id);
    result.fold(
      (failure) => null, // Handle error
      (_) => ref.invalidateSelf(), // Reload list
    );
  }
}
