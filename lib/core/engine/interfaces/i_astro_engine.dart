import 'package:astr/core/engine/models/celestial_object.dart';
import 'package:astr/core/engine/models/coordinates.dart';
import 'package:astr/core/engine/models/location.dart';
import 'package:astr/core/engine/models/result.dart';
import 'package:astr/core/engine/models/rise_set_times.dart';

/// Interface for astronomical calculation engine
///
/// Implementations must provide accurate celestial position calculations
/// using Meeus algorithms and handle background computation via Isolates.
abstract class IAstroEngine {
  /// Calculates the current horizontal coordinates (Alt/Az) of a celestial object
  /// at the given location and time.
  ///
  /// [object] The celestial object to calculate position for
  /// [location] Observer's geographic location
  /// [time] The time for which to calculate the position
  ///
  /// Returns [Result<HorizontalCoordinates>] with Alt/Az coordinates on success,
  /// or a [CalculationFailure] on error.
  ///
  /// Accuracy requirement: Within 1 degree of Stellarium/verified sources (AC #1)
  Future<Result<HorizontalCoordinates>> calculatePosition(
    CelestialObject object,
    Location location,
    DateTime time,
  );

  /// Calculates the rise, transit, and set times for a celestial object
  /// on a given date at the specified location.
  ///
  /// [object] The celestial object to calculate rise/set times for
  /// [location] Observer's geographic location
  /// [date] The date for which to calculate rise/set times
  ///
  /// Returns [Result<RiseSetTimes>] with rise/transit/set times on success,
  /// or a [CalculationFailure] on error.
  ///
  /// Accuracy requirement: Within 2 minutes of verified sources (AC #2)
  Future<Result<RiseSetTimes>> calculateRiseSet(
    CelestialObject object,
    Location location,
    DateTime date,
  );

  /// Disposes of any resources held by the engine (e.g., Isolates)
  Future<void> dispose();
}
