import 'dart:math' as math;

/// Astr Zone scale v2.0.
///
/// Spec: `docs/astr_zone_scale.md`. Test vectors: `test/fixtures/astr_zone_scale.vectors.json`.
/// The Python reference (`scripts/astr_zone.py`) must give the same results.
///
/// `r` is the ratio of artificial to natural zenith sky brightness. Zone 1 is
/// `r < 0.32`. Zone n (2 to 8) is `[0.32 * 2^(n-2), 0.32 * 2^(n-1))`. Zone 9 is
/// `r >= 40.96`. Boundaries are lower-inclusive.
abstract final class AstrZoneScale {
  /// Natural zenith brightness in microcandela per square metre (Falchi et al. 2016).
  static const double naturalMicroCdPerM2 = 174;

  /// Sky brightness in mag/arcsec² that corresponds to the natural brightness.
  static const double referenceSqm = 22;

  /// The ratio at which zone 2 begins.
  static const double firstEdge = 0.32;

  /// Each zone edge is this multiple of the previous one.
  static const double step = 2;

  static const int zoneCount = 9;

  /// The ratio at which zones 2 to 9 begin.
  static const List<double> edges = <double>[
    0.32, 0.64, 1.28, 2.56, 5.12, 10.24, 20.48, 40.96, //
  ];

  /// Legacy radiance thresholds (nW/cm²/sr) of the production pipeline, highest first.
  static const List<(double, int)> legacyThresholds = <(double, int)>[
    (125, 9), (50, 8), (20, 7), (9, 6), (3, 5), (1, 4), (0.5, 3), (0.25, 2), //
  ];

  /// Zone 1-9 for a ratio. A negative [r] counts as 0. Throws if [r] is NaN.
  static int zoneFromRatio(double r) {
    _checkNumber(r, 'r');
    int zone = 1;
    for (final double edge in edges) {
      if (r >= edge) {
        zone++;
      } else {
        break;
      }
    }
    return zone;
  }

  /// Zenith sky brightness in mag/arcsec² for a ratio (a negative [r] counts as 0).
  static double sqmFromRatio(double r) {
    _checkNumber(r, 'r');
    return referenceSqm - 2.5 * _log10(1 + math.max(r, 0));
  }

  /// Inverse of [sqmFromRatio]. An SQM above the reference gives 0.
  static double ratioFromSqm(double sqm) {
    _checkNumber(sqm, 'sqm');
    return math.max(math.pow(10, 0.4 * (referenceSqm - sqm)).toDouble() - 1, 0);
  }

  /// Artificial zenith luminance in microcandela per square metre.
  static double artificialMicroCdFromRatio(double r) {
    _checkNumber(r, 'r');
    return math.max(r, 0) * naturalMicroCdPerM2;
  }

  /// Naked-eye limiting magnitude from an SQM value (empirical, Unihedron/AAVSO relation).
  static double nelmFromSqm(double sqm) {
    return 7.93 - 5 * _log10(math.pow(10, 4.316 - sqm / 5).toDouble() + 1);
  }

  /// Zone assigned by the production pipeline's radiance thresholds.
  static int legacyZoneFromRadiance(double radiance) {
    if (radiance <= 0) return 1;
    for (final (double, int) entry in legacyThresholds) {
      if (radiance >= entry.$1) return entry.$2;
    }
    return 1;
  }

  /// The ratio implied by the legacy SQM fit `22 - 1.7 log10(1 + 2R)`: `(1 + 2R)^0.68 - 1`.
  static double legacyRatioFromRadiance(double radiance) {
    if (radiance <= 0) return 0;
    return math.pow(1 + 2 * radiance, 0.4 * 1.7).toDouble() - 1;
  }

  static double _log10(double x) => math.log(x) / math.ln10;

  static void _checkNumber(double value, String name) {
    if (value.isNaN) {
      throw ArgumentError.value(value, name, 'must be a number');
    }
  }
}
