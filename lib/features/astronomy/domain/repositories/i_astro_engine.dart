import 'package:astr/core/error/failure.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_body.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_position.dart';
import 'package:astr/features/astronomy/domain/entities/moon_phase_info.dart';
import 'package:fpdart/fpdart.dart';

abstract class IAstroEngine {
  /// Calculates the position of a celestial body for a given time and location.
  /// 
  /// [latitude] and [longitude] are in degrees.
  /// [time] is the observation time (will be converted to UTC).
  Future<Either<Failure, CelestialPosition>> getPosition({
    required CelestialBody body,
    required DateTime time,
    required double latitude,
    required double longitude,
  });

  /// Calculates the position of a deep sky object (Star, Galaxy, Nebula, etc.)
  /// defined by its J2000 RA/Dec coordinates.
  /// 
  /// [ra] is Right Ascension in degrees (0-360).
  /// [dec] is Declination in degrees (-90 to +90).
  /// [name] is the object name (e.g., "Sirius", "Andromeda").
  Future<Either<Failure, CelestialPosition>> getDeepSkyPosition({
    required double ra,
    required double dec,
    required String name,
    required DateTime time,
    required double latitude,
    required double longitude,
  });

  /// Calculates the moon illumination and phase.
  Future<Either<Failure, MoonPhaseInfo>> getMoonPhaseInfo({
    required DateTime time,
  });
}
