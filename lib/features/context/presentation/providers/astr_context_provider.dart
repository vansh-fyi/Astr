import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/location_service_provider.dart';
import '../../domain/entities/astr_context.dart';
import '../../domain/entities/geo_location.dart';
import 'geocoding_provider.dart';

class AstrContextNotifier extends AsyncNotifier<AstrContext> {
  @override
  Future<AstrContext> build() async {
    return _loadInitialContext();
  }

  Future<AstrContext> _loadInitialContext() async {
    final now = DateTime.now();
    final locationService = ref.read(locationServiceProvider);
    final result = await locationService.getCurrentLocation();

    return result.fold(
      (failure) => AstrContext(
        selectedDate: now,
        location: const GeoLocation(latitude: 0, longitude: 0, name: "Default"),
        isCurrentLocation: false,
      ),
      (location) async {
        // Fetch place name if missing
        String? placeName = location.placeName;
        if (placeName == null) {
          final geocodingRepo = ref.read(geocodingRepositoryProvider);
          final nameResult = await geocodingRepo.getPlaceName(
            location.latitude,
            location.longitude,
          );
          placeName = nameResult.fold((l) => null, (r) => r);
        }

        return AstrContext(
          selectedDate: now,
          location: location.copyWith(placeName: placeName),
          isCurrentLocation: true,
        );
      },
    );
  }

  Future<void> refreshLocation() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadInitialContext());
  }

  void updateDate(DateTime date) {
    final currentValue = state.value;
    if (currentValue != null) {
      state = AsyncValue.data(currentValue.copyWith(selectedDate: date));
    }
  }

  Future<void> updateLocation(GeoLocation location) async {
    final currentValue = state.value;
    if (currentValue != null) {
      // Optimistic update
      state = AsyncValue.data(currentValue.copyWith(
        location: location,
        isCurrentLocation: false,
      ));

      // Fetch place name if missing
      if (location.placeName == null) {
        final geocodingRepo = ref.read(geocodingRepositoryProvider);
        final result = await geocodingRepo.getPlaceName(
          location.latitude,
          location.longitude,
        );
        
        result.fold(
          (l) => null, // Ignore error
          (name) {
             final updatedLocation = location.copyWith(placeName: name);
             // Update state again with place name
             state = AsyncValue.data(currentValue.copyWith(
               location: updatedLocation,
               isCurrentLocation: false,
             ));
          },
        );
      }
    }
  }
}

final astrContextProvider =
    AsyncNotifierProvider<AstrContextNotifier, AstrContext>(() {
  return AstrContextNotifier();
});
