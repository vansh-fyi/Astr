/// Data Layer - H3 Zone Data Access
///
/// Provides zone data access via remote Cloudflare D1 API with Hive caching.
///
/// **Core Services:**
/// - [RemoteZoneService]: HTTP client for Cloudflare Worker zone lookups
/// - [CoordinateValidationService]: User-facing coordinate validation
///
/// **Models:**
/// - [ZoneData]: Immutable light pollution data (Bortle, Ratio, SQM)
/// - [CoordinateValidationException]: Validation error details
///
/// **Providers:**
/// - [cachedZoneRepositoryProvider]: Remote API + Hive cache
/// - [coordinateValidationServiceProvider]: Coordinate validator
library data_layer;

// Models
export 'models/zone_data.dart';
export 'models/coordinate_validation_exception.dart';

// Services
export 'services/remote_zone_service.dart';
export 'services/coordinate_validation_service.dart';

// Providers
export 'providers/cached_zone_repository_provider.dart';
export 'providers/coordinate_validation_service_provider.dart';
