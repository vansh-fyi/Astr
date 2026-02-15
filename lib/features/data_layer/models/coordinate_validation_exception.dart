/// Exception thrown when coordinate validation fails.
///
/// Contains detailed information about the validation failure:
/// - [message]: Human-readable error message (matches AC specifications)
/// - [field]: Which coordinate failed ('latitude' or 'longitude')
/// - [value]: The invalid value that was provided
///
/// **Usage:**
/// ```dart
/// try {
///   validationService.validateCoordinates(lat, lon);
/// } on CoordinateValidationException catch (e) {
///   showToast(e.message);  // "Latitude must be between -90 and 90"
/// }
/// ```
class CoordinateValidationException implements Exception {
  /// Creates a CoordinateValidationException with the given details.
  ///
  /// Parameters:
  /// - [message]: Human-readable error message
  /// - [field]: 'latitude' or 'longitude'
  /// - [value]: The invalid coordinate value
  const CoordinateValidationException(
    this.message, {
    required this.field,
    required this.value,
  });

  /// Human-readable error message.
  ///
  /// AC-compliant messages:
  /// - "Latitude must be between -90 and 90"
  /// - "Longitude must be between -180 and 180"
  final String message;

  /// The field that failed validation.
  ///
  /// Values: 'latitude' or 'longitude'
  final String field;

  /// The invalid value that was provided.
  final double value;

  @override
  String toString() =>
      'CoordinateValidationException: $message (field: $field, value: $value)';
}
