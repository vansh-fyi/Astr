// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$locationRepositoryHash() =>
    r'f5aecdb85bf3b8525101df46ae393657240e2d75';

/// Riverpod provider for LocationRepository.
///
/// Provides a singleton instance of [LocationRepositoryImpl] with proper
/// dependency injection of [LocationDatabaseService] and [H3Service].
///
/// Copied from [locationRepository].
@ProviderFor(locationRepository)
final locationRepositoryProvider =
    AutoDisposeProvider<LocationRepositoryImpl>.internal(
  locationRepository,
  name: r'locationRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$locationRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocationRepositoryRef = AutoDisposeProviderRef<LocationRepositoryImpl>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
