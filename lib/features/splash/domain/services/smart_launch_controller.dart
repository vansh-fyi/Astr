import 'package:astr/core/error/failure.dart';
import 'package:astr/core/services/i_location_service.dart';
import 'package:astr/features/data_layer/repositories/cached_zone_repository.dart';
import 'package:astr/features/data_layer/services/h3_service.dart';
import 'package:flutter/foundation.dart';

import '../entities/launch_result.dart';

/// Orchestrates the "Zero-Click" launch flow: Auto-detect → Resolve H3 → Pre-fetch data
///
/// This controller implements the smart launch sequence from Epic 4 Story 4.1:
/// 1. Get current GPS location (with 10s timeout - NFR-10)
/// 2. Resolve H3 index at resolution 8
/// 3. Pre-fetch zone data via remote API (Bortle, SQM, Ratio)
/// 4. Return appropriate launch result for navigation
///
/// **Failure Modes:**
/// - GPS timeout → LaunchTimeout (show toast, offer manual entry)
/// - Permission denied → LaunchPermissionDenied (navigate to manual entry)
/// - Service disabled → LaunchServiceDisabled (navigate to manual entry)
/// - Zone data failure → LaunchTimeout (silent fail, partial data acceptable)
class SmartLaunchController {
  SmartLaunchController({
    required ILocationService locationService,
    required H3Service h3Service,
    required CachedZoneRepository zoneRepository,
  })  : _locationService = locationService,
        _h3Service = h3Service,
        _zoneRepository = zoneRepository;

  final ILocationService _locationService;
  final H3Service _h3Service;
  final CachedZoneRepository _zoneRepository;

  /// Execute smart launch: Auto-detect → Resolve H3 → Pre-fetch data
  ///
  /// Returns [LaunchResult] indicating navigation target.
  ///
  /// **Success Path:**
  /// - Location obtained within 10s
  /// - H3 index calculated
  /// - Zone data retrieved
  /// - Returns [LaunchSuccess] with pre-loaded data
  ///
  /// **Failure Paths:**
  /// - GPS timeout → [LaunchTimeout]
  /// - Permission denied → [LaunchPermissionDenied]
  /// - Service disabled → [LaunchServiceDisabled]
  /// - Zone data error → [LaunchTimeout] (silent fail)
  Future<LaunchResult> executeLaunch() async {
    // Step 1: Get current location (with 10s timeout - NFR-10)
    debugPrint('[SmartLaunchController] Starting launch sequence...');
    final locationResult = await _locationService.getCurrentLocation();

    return locationResult.fold(
      (failure) {
        // Handle specific failure types
        if (failure is TimeoutFailure) {
          // NFR-10: GPS timeout → Dashboard with toast
          debugPrint('[SmartLaunchController] GPS timeout');
          return const LaunchTimeout();
        }

        if (failure is PermissionFailure) {
          // Permission denied → Manual entry screen
          debugPrint('[SmartLaunchController] Permission denied');
          return const LaunchPermissionDenied();
        }

        // Location service disabled → Manual entry screen
        debugPrint('[SmartLaunchController] Location service disabled: ${failure.message}');
        return const LaunchServiceDisabled();
      },
      (location) async {
        debugPrint('[SmartLaunchController] Location obtained: ${location.latitude}, ${location.longitude}');

        // Step 2: Resolve H3 index (Epic 1 Story 1.3)
        try {
          final h3Index = _h3Service.latLonToH3(
            location.latitude,
            location.longitude,
            8, // PRD: Resolution 8
          );
          debugPrint('[SmartLaunchController] H3 index resolved: $h3Index');

          // Step 3: Pre-fetch zone data via remote API (Bortle, SQM, Ratio)
          try {
            final zoneData = await _zoneRepository.getZoneData(h3Index);

            // SUCCESS: All data resolved
            debugPrint('[SmartLaunchController] Launch success - Bortle ${zoneData.bortleClass}');
            return LaunchSuccess(
              location: location,
              h3Index: h3Index.toString(),
              zoneData: zoneData,
            );
          } catch (e) {
            // zones.db error - silent fail, go to dashboard anyway
            // User can retry or use manual entry
            debugPrint('[SmartLaunchController] Zone data fetch failed: $e');
            return const LaunchTimeout(); // Treat as partial failure
          }
        } catch (e) {
          // H3 calculation error (edge cases: poles, invalid coords)
          debugPrint('[SmartLaunchController] H3 calculation error: $e');
          return const LaunchTimeout();
        }
      },
    );
  }
}
