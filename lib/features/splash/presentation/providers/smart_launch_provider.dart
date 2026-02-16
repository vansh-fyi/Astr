import 'package:astr/core/services/location_service_provider.dart';
import 'package:astr/features/data_layer/providers/cached_zone_repository_provider.dart';
import 'package:astr/features/data_layer/services/h3_service.dart';
import 'package:astr/features/splash/domain/entities/launch_result.dart';
import 'package:astr/features/splash/domain/services/smart_launch_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'smart_launch_provider.g.dart';

/// Provider for [SmartLaunchController].
///
/// Creates the controller with dependencies injected from other providers.
/// All dependencies are synchronous — no async waiting required.
@riverpod
SmartLaunchController smartLaunchController(SmartLaunchControllerRef ref) {
  final locationService = ref.watch(locationServiceProvider);
  final h3Service = ref.watch(h3ServiceProvider);
  final zoneRepository = ref.watch(cachedZoneRepositoryProvider);

  return SmartLaunchController(
    locationService: locationService,
    h3Service: h3Service,
    zoneRepository: zoneRepository,
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
  // Controller is ready immediately (all sync dependencies)
  final controller = ref.watch(smartLaunchControllerProvider);

  // Execute launch sequence
  return await controller.executeLaunch();
}
