import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/src/either.dart';
import 'package:get_storage/get_storage.dart';
import 'package:riverpod/src/async_notifier.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/i_location_service.dart';
import '../../../../core/services/location_service_provider.dart';
import '../../../profile/presentation/providers/user_locations_provider.dart';
import '../../domain/entities/astr_context.dart';
import '../../domain/entities/geo_location.dart';
import '../../domain/repositories/i_geocoding_repository.dart';
import 'geocoding_provider.dart';

/// AC#5: Storage keys for persistent state
const String _kLastLatitude = 'last_latitude';
const String _kLastLongitude = 'last_longitude';
const String _kLastLocationName = 'last_location_name';
const String _kLastDate = 'last_date';
const String _kUsePersistedLocation = 'use_persisted_location';

class AstrContextNotifier extends AsyncNotifier<AstrContext> {
  final GetStorage _storage = GetStorage();

  @override
  Future<AstrContext> build() async {
    return _loadInitialContext();
  }

  Future<AstrContext> _loadInitialContext() async {
    final DateTime now = DateTime.now();
    
    // AC#5: Try to restore persisted state first
    final bool usePersistedLocation = _storage.read<bool>(_kUsePersistedLocation) ?? false;
    
    if (usePersistedLocation) {
      final double? lat = _storage.read<double>(_kLastLatitude);
      final double? lng = _storage.read<double>(_kLastLongitude);
      final String? name = _storage.read<String>(_kLastLocationName);
      final String? dateStr = _storage.read<String>(_kLastDate);
      
      if (lat != null && lng != null) {
        final DateTime restoredDate = dateStr != null 
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
    final ILocationService locationService = ref.read(locationServiceProvider);
    final Either<Failure, GeoLocation> result = await locationService.getCurrentLocation();

    return result.fold(
      (Failure failure) => AstrContext(
        selectedDate: now,
        location: const GeoLocation(latitude: 0, longitude: 0, name: 'Default'),
        isCurrentLocation: false,
      ),
      (GeoLocation location) async {
        // Fetch place name if missing
        String? placeName = location.placeName;
        if (placeName == null) {
          final IGeocodingRepository geocodingRepo = ref.read(geocodingRepositoryProvider);
          final Either<Failure, String> nameResult = await geocodingRepo.getPlaceName(
            location.latitude,
            location.longitude,
          );
          placeName = nameResult.fold((Failure l) => null, (String r) => r);
        }

        return AstrContext(
          selectedDate: now,
          location: location.copyWith(placeName: placeName),
        );
      },
    );
  }

  Future<void> refreshLocation() async {
    // AC#5: Clear persisted location when explicitly refreshing
    await _storage.write(_kUsePersistedLocation, false);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadInitialContext);
  }

  void updateDate(DateTime date) {
    final AstrContext? currentValue = state.value;
    if (currentValue != null) {
      state = AsyncValue.data(currentValue.copyWith(selectedDate: date));
      // AC#5: Persist selected date
      _storage.write(_kLastDate, date.toIso8601String());
      _storage.write(_kUsePersistedLocation, true);
    }
  }

  Future<void> updateLocation(GeoLocation location) async {
    final AstrContext? currentValue = state.value;
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

      // Story 2.3: Update lastViewedTimestamp if this is a saved location
      // This marks the location as "active" for staleness tracking
      _updateLastViewedIfSavedLocation(location);

      // Fetch place name if missing
      if (location.placeName == null) {
        final IGeocodingRepository geocodingRepo = ref.read(geocodingRepositoryProvider);
        final Either<Failure, String> result = await geocodingRepo.getPlaceName(
          location.latitude,
          location.longitude,
        );
        
        result.fold(
          (Failure l) => null, // Ignore error
          (String name) {
             final GeoLocation updatedLocation = location.copyWith(placeName: name);
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

  /// Story 2.3: Updates lastViewedTimestamp if the location is a saved location.
  ///
  /// This is a non-blocking fire-and-forget operation. Errors are logged
  /// in debug mode but don't block the UI since staleness tracking is non-critical.
  Future<void> _updateLastViewedIfSavedLocation(GeoLocation location) async {
    try {
      final notifier = ref.read(userLocationsNotifierProvider.notifier);
      final matchingLocation = await notifier.findByCoordinates(
        location.latitude,
        location.longitude,
      );

      if (matchingLocation != null) {
        await notifier.updateLastViewed(matchingLocation.id);
        debugPrint('Staleness: Updated lastViewed for location ${matchingLocation.name} (${matchingLocation.id})');
      } else {
        debugPrint('Staleness: Location at (${location.latitude}, ${location.longitude}) not found in saved locations');
      }
    } catch (e, stackTrace) {
      // Log errors in debug mode for troubleshooting
      debugPrint('Staleness tracking failed: $e');
      if (kDebugMode) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }
}

final AsyncNotifierProviderImpl<AstrContextNotifier, AstrContext> astrContextProvider =
    AsyncNotifierProvider<AstrContextNotifier, AstrContext>(() {
  return AstrContextNotifier();
});
