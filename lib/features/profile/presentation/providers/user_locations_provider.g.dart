// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_locations_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pinnedLocationsHash() => r'3baf88046adaffa0d278e90eb28474c0875c667d';

/// Provider for pinned locations only.
///
/// Used by background sync (Story 3.4) to get priority locations.
///
/// Copied from [pinnedLocations].
@ProviderFor(pinnedLocations)
final pinnedLocationsProvider =
    AutoDisposeFutureProvider<List<UserLocation>>.internal(
  pinnedLocations,
  name: r'pinnedLocationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pinnedLocationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PinnedLocationsRef = AutoDisposeFutureProviderRef<List<UserLocation>>;
String _$staleLocationsHash() => r'79b8d88d7561acf2452a44c33b81e2b4d798c5c6';

/// Provider for stale locations only.
///
/// Returns locations that are NOT pinned AND last viewed > 10 days ago.
/// Used by background sync (Story 3.4) to exclude these from updates.
///
/// Copied from [staleLocations].
@ProviderFor(staleLocations)
final staleLocationsProvider =
    AutoDisposeFutureProvider<List<UserLocation>>.internal(
  staleLocations,
  name: r'staleLocationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$staleLocationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StaleLocationsRef = AutoDisposeFutureProviderRef<List<UserLocation>>;
String _$userLocationsNotifierHash() =>
    r'a2fb0cd8aa0e92437aa21ab0d0056c721d1541b3';

/// Riverpod AsyncNotifier for managing user locations.
///
/// This provider:
/// - Loads and caches the list of UserLocation entities
/// - Provides CRUD methods: addLocation, updateLocation, deleteLocation
/// - Auto-resolves H3 index when saving new locations
/// - Auto-selects newly added locations in AstrContext
///
/// Replaces the old `SavedLocationsNotifier` (Hive-based) with
/// Sqflite-backed storage.
///
/// Copied from [UserLocationsNotifier].
@ProviderFor(UserLocationsNotifier)
final userLocationsNotifierProvider = AutoDisposeAsyncNotifierProvider<
    UserLocationsNotifier, List<UserLocation>>.internal(
  UserLocationsNotifier.new,
  name: r'userLocationsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userLocationsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserLocationsNotifier = AutoDisposeAsyncNotifier<List<UserLocation>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
