// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_launch_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$smartLaunchControllerHash() =>
    r'dd94a67d6654fafd05e92ec3ef7fcfd8ba8f5e65';

/// Provider for [SmartLaunchController].
///
/// Creates the controller with dependencies injected from other providers.
/// All dependencies are synchronous — no async waiting required.
///
/// Copied from [smartLaunchController].
@ProviderFor(smartLaunchController)
final smartLaunchControllerProvider =
    AutoDisposeProvider<SmartLaunchController>.internal(
  smartLaunchController,
  name: r'smartLaunchControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$smartLaunchControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SmartLaunchControllerRef
    = AutoDisposeProviderRef<SmartLaunchController>;
String _$launchResultHash() => r'eb01b5b882545482c90a5554fa8fb6951f62a8ca';

/// Provider that executes the smart launch sequence.
///
/// This provider runs the launch controller and returns the result.
/// It's a FutureProvider so it can be watched and will update when complete.
///
/// **Usage in InitializationProvider:**
/// ```dart
/// // Trigger launch in background (don't await)
/// ref.read(launchResultProvider.future);
/// ```
///
/// **Usage in Router:**
/// ```dart
/// final launchAsync = ref.watch(launchResultProvider);
/// launchAsync.whenData((result) {
///   // Handle navigation based on result
/// });
/// ```
///
/// Copied from [launchResult].
@ProviderFor(launchResult)
final launchResultProvider = AutoDisposeFutureProvider<LaunchResult>.internal(
  launchResult,
  name: r'launchResultProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$launchResultHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LaunchResultRef = AutoDisposeFutureProviderRef<LaunchResult>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
