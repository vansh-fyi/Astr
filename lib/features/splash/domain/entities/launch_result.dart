import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/data_layer/models/zone_data.dart';

/// Result of smart launch attempt
sealed class LaunchResult {
  const LaunchResult();
}

/// Successful location resolution - navigate to dashboard
class LaunchSuccess extends LaunchResult {
  const LaunchSuccess({
    required this.location,
    required this.h3Index,
    required this.zoneData,
  });

  final GeoLocation location;
  final String h3Index;
  final ZoneData zoneData;
}

/// GPS timeout - navigate to dashboard with toast and manual entry
class LaunchTimeout extends LaunchResult {
  const LaunchTimeout();
}

/// Permission denied - navigate to manual entry or saved locations
class LaunchPermissionDenied extends LaunchResult {
  const LaunchPermissionDenied();
}

/// Location service disabled - navigate to manual entry
class LaunchServiceDisabled extends LaunchResult {
  const LaunchServiceDisabled();
}
