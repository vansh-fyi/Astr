import '../models/coordinate_validation_exception.dart';

/// Stateless service for validating geographic coordinates.
///
/// Validates latitude and longitude values against Earth coordinate boundaries
/// before they are used in H3 lookups or other geographic operations.
///
/// **Validation Rules:**
/// - Latitude: -90.0 to +90.0 (inclusive)
/// - Longitude: -180.0 to +180.0 (inclusive)
/// - Special values (NaN, infinity) are rejected
///
/// **Architecture:**
/// - "Data Service Layer" pattern - stateless validation
/// - No external dependencies
/// - Must validate BEFORE calling h3_flutter FFI
///
/// **Usage:**
/// ```dart
/// final validator = CoordinateValidationService();
/// try {
///   validator.validateCoordinates(95.0, 0.0);  // Invalid latitude
/// } on CoordinateValidationException catch (e) {
///   print(e.message);  // "Latitude must be between -90 and 90"
/// }
/// ```
class CoordinateValidationService {
  /// Minimum valid latitude (South Pole).
  static const double minLatitude = -90.0;

  /// Maximum valid latitude (North Pole).
  static const double maxLatitude = 90.0;

  /// Minimum valid longitude (International Date Line West).
  static const double minLongitude = -180.0;

  /// Maximum valid longitude (International Date Line East).
  static const double maxLongitude = 180.0;

  /// Validates that a latitude value is within valid Earth coordinates.
  ///
  /// **Valid Range:** -90.0 to +90.0 (inclusive)
  /// - Positive: Northern Hemisphere
  /// - Negative: Southern Hemisphere
  /// - Zero: Equator
  ///
  /// Throws [CoordinateValidationException] if:
  /// - [latitude] is less than -90.0
  /// - [latitude] is greater than 90.0
  /// - [latitude] is NaN or infinity
  ///
  /// The error message matches AC-1: "Latitude must be between -90 and 90"
  void validateLatitude(double latitude) {
    // Check for NaN first (NaN comparisons always return false)
    if (latitude.isNaN) {
      throw CoordinateValidationException(
        'Latitude must be between -90 and 90',
        field: 'latitude',
        value: latitude,
      );
    }

    // Check for infinity
    if (latitude.isInfinite) {
      throw CoordinateValidationException(
        'Latitude must be between -90 and 90',
        field: 'latitude',
        value: latitude,
      );
    }

    // Check range bounds
    if (latitude < minLatitude || latitude > maxLatitude) {
      throw CoordinateValidationException(
        'Latitude must be between -90 and 90',
        field: 'latitude',
        value: latitude,
      );
    }
  }

  /// Validates that a longitude value is within valid Earth coordinates.
  ///
  /// **Valid Range:** -180.0 to +180.0 (inclusive)
  /// - Positive: Eastern Hemisphere
  /// - Negative: Western Hemisphere
  /// - Zero: Prime Meridian
  ///
  /// Throws [CoordinateValidationException] if:
  /// - [longitude] is less than -180.0
  /// - [longitude] is greater than 180.0
  /// - [longitude] is NaN or infinity
  ///
  /// The error message matches AC-2: "Longitude must be between -180 and 180"
  void validateLongitude(double longitude) {
    // Check for NaN first (NaN comparisons always return false)
    if (longitude.isNaN) {
      throw CoordinateValidationException(
        'Longitude must be between -180 and 180',
        field: 'longitude',
        value: longitude,
      );
    }

    // Check for infinity
    if (longitude.isInfinite) {
      throw CoordinateValidationException(
        'Longitude must be between -180 and 180',
        field: 'longitude',
        value: longitude,
      );
    }

    // Check range bounds
    if (longitude < minLongitude || longitude > maxLongitude) {
      throw CoordinateValidationException(
        'Longitude must be between -180 and 180',
        field: 'longitude',
        value: longitude,
      );
    }
  }

  /// Validates both latitude and longitude coordinates.
  ///
  /// Convenience method that validates latitude first, then longitude.
  /// If both are invalid, the latitude error is thrown first.
  ///
  /// **AC-3 Compliance:** Valid coordinates proceed to H3 resolution.
  /// **AC-4 Compliance:** Boundary values are accepted as valid.
  ///
  /// Throws [CoordinateValidationException] if either coordinate is invalid.
  void validateCoordinates(double latitude, double longitude) {
    validateLatitude(latitude);
    validateLongitude(longitude);
  }
}
