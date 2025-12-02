import 'dart:math';
import 'package:fpdart/fpdart.dart';

/// Service for calculating the Darkness Quality metric (MPSAS).
///
/// Uses the David Lorenz Light Pollution Atlas formula for base darkness
/// and a heuristic model for Moon interference.
///
/// See `docs/calculations.md` for algorithm details.
class DarknessCalculator {
  /// Calculates the effective darkness in MPSAS (Magnitude Per Square Arcsecond).
  ///
  /// [baseMPSAS] The base sky brightness without moon interference (e.g., from Light Pollution Map).
  ///             Typical range: 17.0 (Bright City) to 22.0 (Dark Sky).
  /// [moonPhase] The current moon phase (0.0 = New, 1.0 = Full).
  /// [moonAltitude] The moon's altitude in degrees (-90.0 to +90.0).
  ///
  /// Returns a [double] representing the effective MPSAS.
  /// Lower values indicate brighter (worse) skies.
  double calculateDarkness({
    required double baseMPSAS,
    required double moonPhase,
    required double moonAltitude,
  }) {
    double moonPenalty = 0.0;

    if (moonAltitude > 0) {
      // Only penalize if moon is above horizon
      // Penalty scales with Phase (linear approx) and Altitude (sin approx)
      // A Full Moon (1.0) at Zenith (90°) gives max penalty (4.0)
      
      // Convert altitude to radians for sin calculation
      final double altitudeRadians = moonAltitude * (pi / 180.0);
      final double altitudeFactor = sin(altitudeRadians); // 0.0 to 1.0
      
      // Ensure altitude factor is not negative (though check > 0 handles this)
      final double effectiveAltitudeFactor = altitudeFactor < 0 ? 0 : altitudeFactor;

      moonPenalty = 4.0 * moonPhase * effectiveAltitudeFactor;
    }

    return baseMPSAS - moonPenalty;
  }

  /// Returns a qualitative label and color for a given MPSAS value.
  ///
  /// Returns a tuple of (Label, ColorHex).
  /// Example: (Excellent, 0xFF00FF00)
  (String, int) getDarknessLabel(double mpsas) {
    if (mpsas >= 21.5) {
      return ('Excellent', 0xFF4CAF50); // Green
    } else if (mpsas >= 21.0) {
      return ('Good', 0xFF8BC34A); // Light Green
    } else if (mpsas >= 20.0) {
      return ('Fair', 0xFFFFEB3B); // Yellow
    } else if (mpsas >= 19.0) {
      return ('Poor', 0xFFFF9800); // Orange
    } else {
      return ('Very Poor', 0xFFF44336); // Red
    }
  }
}
