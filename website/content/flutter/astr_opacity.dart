import 'dart:math' as math;

/// Astr opacity ladder: the Pogson magnitude scale.
///
/// alpha(n) = 10^(-0.4 * n / 2), so each step is half a magnitude and ten
/// steps (five magnitudes) is exactly 100x dimmer. Any colour stop may use
/// any step. The constants mirror the `--mag-*` values in `globals.css`
/// (same rounding), so web and Flutter render identically.
///
/// Usage: `AstrColors.auroraGreen[400]!.withValues(alpha: Mag.m3)`
abstract final class Mag {
  static const double m0 = 1.0;
  static const double m1 = 0.631;
  static const double m2 = 0.3981;
  static const double m3 = 0.2512;
  static const double m4 = 0.1585;
  static const double m5 = 0.1;
  static const double m6 = 0.0631;
  static const double m7 = 0.0398;
  static const double m8 = 0.0251;
  static const double m9 = 0.0158;
  static const double m10 = 0.01;

  /// Index with the step number: `Mag.steps[3] == Mag.m3`.
  static const List<double> steps = <double>[
    m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, //
  ];

  /// The exact formula, for checking the constants or generating new steps.
  static double alpha(int n) => math.pow(10, -0.4 * n / 2).toDouble();

  /// Nearest ladder step for [alpha] (clamped to 1). Returns null when the
  /// value is at least 10.5 half-steps down, meaning fully transparent.
  static int? snap(double alpha) {
    final double a = math.min(1.0, alpha);
    final double nRaw = -5 * (math.log(a) / math.ln10);
    if (nRaw >= 10.5) return null;
    return nRaw.round().clamp(0, 10);
  }
}
