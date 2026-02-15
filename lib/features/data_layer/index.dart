/// Data Layer - H3 Zone Data Access
///
/// Provides sovereign binary access to zones.db and light pollution data.
///
/// **Core Services:**
/// - [BinaryReaderService]: Low-level file I/O with RandomAccessFile
/// - [ZoneDataService]: H3 index to zone data lookup
/// - [CoordinateValidationService]: User-facing coordinate validation
///
/// **Models:**
/// - [ZoneData]: Immutable light pollution data (Bortle, Ratio, SQM)
/// - [CoordinateValidationException]: Validation error details
///
/// **Providers:**
/// - [binaryReaderServiceProvider]: Initialized BinaryReaderService
/// - [zoneDataServiceProvider]: Initialized ZoneDataService
/// - [coordinateValidationServiceProvider]: Coordinate validator
///
/// **Usage Example:**
/// ```dart
/// import 'package:astr/features/data_layer/index.dart';
///
/// // Validate coordinates before H3 lookup
/// final validator = ref.read(coordinateValidationServiceProvider);
/// try {
///   validator.validateCoordinates(lat, lon);
///   final h3Service = ref.read(h3ServiceProvider);
///   final index = h3Service.latLonToH3(lat, lon, 8);
///   final zoneService = await ref.read(zoneDataServiceProvider.future);
///   final data = await zoneService.getZoneData(index);
/// } on CoordinateValidationException catch (e) {
///   showToast(e.message);
/// }
/// ```
library data_layer;

// Models
export 'models/zone_data.dart';
export 'models/coordinate_validation_exception.dart';

// Services
export 'services/binary_reader_service.dart';
export 'services/zone_data_service.dart';
export 'services/coordinate_validation_service.dart';

// Providers
export 'providers/binary_reader_service_provider.dart';
export 'providers/zone_data_service_provider.dart';
export 'providers/coordinate_validation_service_provider.dart';
