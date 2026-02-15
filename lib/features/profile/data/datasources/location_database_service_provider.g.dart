// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_database_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$locationDatabaseServiceHash() =>
    r'3169fd7df2e82bebbb9eadb24b7e86b99812828a';

/// Riverpod provider for [LocationDatabaseService].
///
/// Provides a singleton instance of the database service for dependency
/// injection throughout the app. The service is lazily initialized on
/// first access.
///
/// Copied from [locationDatabaseService].
@ProviderFor(locationDatabaseService)
final locationDatabaseServiceProvider =
    AutoDisposeProvider<LocationDatabaseService>.internal(
  locationDatabaseService,
  name: r'locationDatabaseServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$locationDatabaseServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocationDatabaseServiceRef
    = AutoDisposeProviderRef<LocationDatabaseService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
