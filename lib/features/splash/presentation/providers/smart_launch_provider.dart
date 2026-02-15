import 'package:astr/core/services/location_service_provider.dart';
import 'package:astr/features/data_layer/providers/zone_data_service_provider.dart';
import 'package:astr/features/data_layer/services/h3_service.dart';
import 'package:astr/features/splash/domain/entities/launch_result.dart';
import 'package:astr/features/splash/domain/services/smart_launch_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'smart_launch_provider.g.dart';

/// Provider for [SmartLaunchController].
///
/// Creates the controller with dependencies injected from other providers.
@riverpod
SmartLaunchController smartLaunchController(SmartLaunchControllerRef ref) {
  final locationService = ref.watch(locationServiceProvider);
  final h3Service = ref.watch(h3ServiceProvider);

  // ZoneDataService is async, but SmartLaunchController will await it internally
  // We can't await here since this is a sync provider, so we create a wrapper
  // that throws if ZoneDataService isn't ready yet
  final zoneDataServiceAsync = ref.watch(zoneDataServiceProvider);

  return zoneDataServiceAsync.when(
    data: (zoneDataService) => SmartLaunchController(
      locationService: locationService,
      h3Service: h3Service,
      zoneDataService: zoneDataService,
    ),
    loading: () => throw StateError(
      'ZoneDataService not initialized yet. '
      'Ensure zones.db integrity check completes before calling launch.',
    ),
    error: (error, stackTrace) => throw StateError(
      'ZoneDataService failed to initialize: $error',
    ),
  );
}

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
@riverpod
Future<LaunchResult> launchResult(LaunchResultRef ref) async {
  // Wait for controller to be ready
  final controller = ref.watch(smartLaunchControllerProvider);

  // Execute launch sequence
  return await controller.executeLaunch();
}
