import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coordinate_validation_exception.dart';
import '../services/coordinate_validation_service.dart';

// Re-export for single-import convenience (Story 1.3 pattern)
export '../models/coordinate_validation_exception.dart';
export '../services/coordinate_validation_service.dart';

/// Riverpod provider for [CoordinateValidationService].
///
/// This is a simple synchronous `Provider` since the service is stateless
/// and requires no async initialization.
///
/// Usage:
/// ```dart
/// final validator = ref.read(coordinateValidationServiceProvider);
/// try {
///   validator.validateCoordinates(lat, lon);
/// } on CoordinateValidationException catch (e) {
///   showToast(e.message);
/// }
/// ```
final Provider<CoordinateValidationService> coordinateValidationServiceProvider =
    Provider<CoordinateValidationService>(
  (ProviderRef<CoordinateValidationService> ref) => CoordinateValidationService(),
);
