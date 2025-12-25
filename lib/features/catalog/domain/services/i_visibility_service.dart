import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../context/domain/entities/geo_location.dart';
import '../entities/celestial_object.dart';
import '../entities/visibility_graph_data.dart';

/// Service interface for calculating visibility graph data for celestial objects
abstract class IVisibilityService {
  /// Calculates visibility graph data for a specific object at a location
  ///
  /// Returns graph data showing object altitude and moon interference over time,
  /// along with optimal viewing windows.
  ///
  /// [object] - The celestial object to calculate visibility for
  /// [location] - Observer's geographic location
  /// [startTime] - Start time for calculations (typically Now)
  ///
  /// [endTime] - Optional end time for calculations. If not provided, defaults to 12 hours from startTime.
  ///
  /// The calculation covers the duration from startTime to endTime with 15-minute intervals.
  /// Performance requirement: Must complete in < 200ms.
  Future<Either<Failure, VisibilityGraphData>> calculateVisibility({
    required CelestialObject object,
    required GeoLocation location,
    required DateTime startTime,
    DateTime? endTime,
  });
}
