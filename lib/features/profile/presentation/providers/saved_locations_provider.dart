import 'package:fpdart/src/either.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../context/domain/entities/geo_location.dart';
import '../../../context/presentation/providers/astr_context_provider.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/entities/saved_location.dart';

part 'saved_locations_provider.g.dart';

@riverpod
class SavedLocationsNotifier extends _$SavedLocationsNotifier {
  @override
  Future<List<SavedLocation>> build() async {
    return _loadLocations();
  }

  Future<List<SavedLocation>> _loadLocations() async {
    final ProfileRepository repository = ref.read(profileRepositoryProvider);
    final Either<Failure, List<SavedLocation>> result = await repository.getSavedLocations();
    return result.fold(
      (Failure failure) => <SavedLocation>[], // Handle error: return empty list for now
      (List<SavedLocation> locations) => locations,
    );
  }

  /// AC#4: Adds a new location and auto-selects it as the current location
  Future<void> addLocation(SavedLocation location) async {
    final ProfileRepository repository = ref.read(profileRepositoryProvider);
    final Either<Failure, void> result = await repository.saveLocation(location);
    result.fold(
      (Failure failure) => null, // Handle error
      (_) {
        ref.invalidateSelf(); // Reload list
        
        // AC#4: Auto-select the newly added location
        // Import needed: astr_context_provider.dart
        ref.read(astrContextProvider.notifier).updateLocation(
          GeoLocation(
            latitude: location.latitude,
            longitude: location.longitude,
            name: location.name,
          ),
        );
      },
    );
  }

  Future<void> deleteLocation(String id) async {
    final ProfileRepository repository = ref.read(profileRepositoryProvider);
    final Either<Failure, void> result = await repository.deleteLocation(id);
    result.fold(
      (Failure failure) => null, // Handle error
      (_) => ref.invalidateSelf(), // Reload list
    );
  }
}
