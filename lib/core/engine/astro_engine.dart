import '../error/failure.dart';
import 'interfaces/i_astro_engine.dart';
import 'isolates/calculation_commands.dart';
import 'isolates/engine_isolate_manager.dart';
import 'models/celestial_object.dart';
import 'models/coordinates.dart';
import 'models/location.dart';
import 'models/result.dart';
import 'models/rise_set_times.dart';

/// Implementation of the astronomical calculation engine
///
/// This engine provides accurate celestial position calculations using
/// Meeus algorithms and automatically offloads heavy computations (>16ms)
/// to Isolates for optimal UI performance.
class AstroEngine implements IAstroEngine {

  AstroEngine({EngineIsolateManager? isolateManager})
      : _isolateManager = isolateManager ?? EngineIsolateManager();
  final EngineIsolateManager _isolateManager;
  bool _isDisposed = false;

  @override
  Future<Result<HorizontalCoordinates>> calculatePosition(
    CelestialObject object,
    Location location,
    DateTime time,
  ) async {
    if (_isDisposed) {
      return Result.failure(
        const CalculationFailure('Engine has been disposed'),
      );
    }

    try {
      // Create command with serializable data
      final CalculatePositionCommand command = CalculatePositionCommand(
        rightAscension: object.coordinates.rightAscension,
        declination: object.coordinates.declination,
        latitude: location.latitude,
        longitude: location.longitude,
        year: time.year,
        month: time.month,
        day: time.day,
        hour: time.hour,
        minute: time.minute,
        second: time.second,
      );

      // EngineIsolateManager automatically offloads to isolate if >16ms (AC #3)
      final HorizontalCoordinates coordinates = await _isolateManager.calculatePosition(command);

      return Result.success(coordinates);
    } catch (e, stackTrace) {
      return Result.failure(
        CalculationFailure('Failed to calculate position: $e\n$stackTrace'),
      );
    }
  }

  @override
  Future<Result<RiseSetTimes>> calculateRiseSet(
    CelestialObject object,
    Location location,
    DateTime date,
  ) async {
    if (_isDisposed) {
      return Result.failure(
        const CalculationFailure('Engine has been disposed'),
      );
    }

    try {
      // Create command with serializable data
      final CalculateRiseSetCommand command = CalculateRiseSetCommand(
        rightAscension: object.coordinates.rightAscension,
        declination: object.coordinates.declination,
        latitude: location.latitude,
        longitude: location.longitude,
        year: date.year,
        month: date.month,
        day: date.day,
      );

      // EngineIsolateManager automatically offloads to isolate if >16ms (AC #3)
      final RiseSetTimes times = await _isolateManager.calculateRiseSet(command);

      return Result.success(times);
    } catch (e, stackTrace) {
      return Result.failure(
        CalculationFailure('Failed to calculate rise/set times: $e\n$stackTrace'),
      );
    }
  }

  @override
  Future<void> dispose() async {
    if (!_isDisposed) {
      _isDisposed = true;
      await _isolateManager.dispose();
    }
  }
}
