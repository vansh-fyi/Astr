import 'package:astr/core/engine/interfaces/i_astro_engine.dart';
import 'package:astr/core/engine/models/celestial_object.dart';
import 'package:astr/core/engine/models/coordinates.dart';
import 'package:astr/core/engine/models/location.dart';
import 'package:astr/core/engine/models/result.dart';
import 'package:astr/core/engine/models/rise_set_times.dart';
import 'package:astr/core/error/failure.dart';
import 'package:astr/core/engine/isolates/engine_isolate_manager.dart';
import 'package:astr/core/engine/isolates/calculation_commands.dart';

/// Implementation of the astronomical calculation engine
///
/// This engine provides accurate celestial position calculations using
/// Meeus algorithms and automatically offloads heavy computations (>16ms)
/// to Isolates for optimal UI performance.
class AstroEngine implements IAstroEngine {
  final EngineIsolateManager _isolateManager;
  bool _isDisposed = false;

  AstroEngine({EngineIsolateManager? isolateManager})
      : _isolateManager = isolateManager ?? EngineIsolateManager();

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
      final command = CalculatePositionCommand(
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
      final coordinates = await _isolateManager.calculatePosition(command);

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
      final command = CalculateRiseSetCommand(
        rightAscension: object.coordinates.rightAscension,
        declination: object.coordinates.declination,
        latitude: location.latitude,
        longitude: location.longitude,
        year: date.year,
        month: date.month,
        day: date.day,
      );

      // EngineIsolateManager automatically offloads to isolate if >16ms (AC #3)
      final times = await _isolateManager.calculateRiseSet(command);

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
