import 'package:astr/features/profile/data/repositories/profile_repository.dart';
import 'package:astr/features/profile/domain/entities/saved_location.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
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

  /// AC#4: Adds a new location and auto-selects it as the current location
  Future<void> addLocation(SavedLocation location) async {
    final repository = ref.read(profileRepositoryProvider);
    final result = await repository.saveLocation(location);
    result.fold(
      (failure) => null, // Handle error
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
    final repository = ref.read(profileRepositoryProvider);
    final result = await repository.deleteLocation(id);
    result.fold(
      (failure) => null, // Handle error
      (_) => ref.invalidateSelf(), // Reload list
    );
  }
}
