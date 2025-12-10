import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import '../../../../core/services/location_service_provider.dart';
import '../../domain/entities/astr_context.dart';
import '../../domain/entities/geo_location.dart';
import 'geocoding_provider.dart';

/// AC#5: Storage keys for persistent state
const String _kLastLatitude = 'last_latitude';
const String _kLastLongitude = 'last_longitude';
const String _kLastLocationName = 'last_location_name';
const String _kLastDate = 'last_date';
const String _kUsePersistedLocation = 'use_persisted_location';

class AstrContextNotifier extends AsyncNotifier<AstrContext> {
  final _storage = GetStorage();

  @override
  Future<AstrContext> build() async {
    return _loadInitialContext();
  }

  Future<AstrContext> _loadInitialContext() async {
    final now = DateTime.now();
    
    // AC#5: Try to restore persisted state first
    final usePersistedLocation = _storage.read<bool>(_kUsePersistedLocation) ?? false;
    
    if (usePersistedLocation) {
      final lat = _storage.read<double>(_kLastLatitude);
      final lng = _storage.read<double>(_kLastLongitude);
      final name = _storage.read<String>(_kLastLocationName);
      final dateStr = _storage.read<String>(_kLastDate);
      
      if (lat != null && lng != null) {
        final restoredDate = dateStr != null 
            ? DateTime.tryParse(dateStr) ?? now 
            : now;
        
        return AstrContext(
          selectedDate: restoredDate,
          location: GeoLocation(
            latitude: lat, 
            longitude: lng, 
            name: name ?? 'Saved Location',
          ),
          isCurrentLocation: false,
        );
      }
    }
    
    // Fall back to device location
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
    // AC#5: Clear persisted location when explicitly refreshing
    await _storage.write(_kUsePersistedLocation, false);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadInitialContext());
  }

  void updateDate(DateTime date) {
    final currentValue = state.value;
    if (currentValue != null) {
      state = AsyncValue.data(currentValue.copyWith(selectedDate: date));
      // AC#5: Persist selected date
      _storage.write(_kLastDate, date.toIso8601String());
      _storage.write(_kUsePersistedLocation, true);
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
      
      // AC#5: Persist selected location
      _storage.write(_kLastLatitude, location.latitude);
      _storage.write(_kLastLongitude, location.longitude);
      _storage.write(_kLastLocationName, location.placeName ?? location.name ?? 'Saved Location');
      _storage.write(_kUsePersistedLocation, true);

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
             // AC#5: Update persisted name
             _storage.write(_kLastLocationName, name);
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
