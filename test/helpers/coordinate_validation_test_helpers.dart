/// Test helpers for coordinate validation testing.
///
/// Provides reusable test data generators and matchers for coordinate validation.
library coordinate_validation_test_helpers;

import 'package:astr/features/data_layer/models/coordinate_validation_exception.dart';
import 'package:flutter_test/flutter_test.dart';

/// Valid latitude test cases with descriptions.
final validLatitudes = <({double value, String description})>[
  (value: -90.0, description: 'South Pole'),
  (value: -45.0, description: 'Mid-range negative'),
  (value: 0.0, description: 'Equator'),
  (value: 45.0, description: 'Mid-range positive'),
  (value: 90.0, description: 'North Pole'),
  (value: 40.7128, description: 'NYC'),
];

/// Invalid latitude test cases with descriptions.
final invalidLatitudes = <({double value, String description})>[
  (value: -100.0, description: 'Far below min'),
  (value: -91.0, description: 'Just below min'),
  (value: 91.0, description: 'Just above max'),
  (value: 95.0, description: 'AC-1 example'),
  (value: 100.0, description: 'Far above max'),
  (value: double.nan, description: 'NaN'),
  (value: double.infinity, description: 'Infinity'),
  (value: double.negativeInfinity, description: 'Negative infinity'),
];

/// Valid longitude test cases with descriptions.
final validLongitudes = <({double value, String description})>[
  (value: -180.0, description: 'International Date Line West'),
  (value: -74.0060, description: 'NYC'),
  (value: 0.0, description: 'Prime Meridian'),
  (value: 90.0, description: 'Mid-range'),
  (value: 180.0, description: 'International Date Line East'),
];

/// Invalid longitude test cases with descriptions.
final invalidLongitudes = <({double value, String description})>[
  (value: -200.0, description: 'Far below min'),
  (value: -181.0, description: 'Just below min'),
  (value: 181.0, description: 'Just above max'),
  (value: 200.0, description: 'AC-2 example'),
  (value: double.nan, description: 'NaN'),
  (value: double.infinity, description: 'Infinity'),
  (value: double.negativeInfinity, description: 'Negative infinity'),
];

/// Matcher for CoordinateValidationException with specific field.
Matcher throwsCoordinateValidationExceptionWithField(String expectedField) {
  return throwsA(
    isA<CoordinateValidationException>().having(
      (e) => e.field,
      'field',
      equals(expectedField),
    ),
  );
}

/// Matcher for CoordinateValidationException with specific message.
Matcher throwsCoordinateValidationExceptionWithMessage(String expectedMessage) {
  return throwsA(
    isA<CoordinateValidationException>().having(
      (e) => e.message,
      'message',
      equals(expectedMessage),
    ),
  );
}
