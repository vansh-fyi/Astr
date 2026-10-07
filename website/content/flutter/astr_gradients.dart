import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'astr_opacity.dart';

/// Astr gradients: natural-law alpha profiles snapped to the [Mag] ladder.
///
/// Both gradients take any colour stop as [base]. Fading to the same colour at
/// alpha 0 (not `Colors.transparent`, which is transparent black) keeps the
/// tail from greying, because Flutter interpolates gradient stops without
/// premultiplying alpha.
abstract final class AstrGradients {
  // --- Atmospheric extinction (zenith to horizon) ---------------------------

  /// Extinction coefficient, magnitudes per airmass.
  static const double extinctionK = 0.2;

  /// Zenith angles in degrees; stop position is `z / 90`.
  static const List<double> extinctionZs = <double>[0, 60, 70, 78, 84, 88, 90];

  /// Kasten-Young relative airmass, `z` in degrees.
  static double airmass(double zDeg) {
    final double rad = zDeg * math.pi / 180;
    return 1 /
        (math.cos(rad) + 0.50572 * math.pow(96.07995 - zDeg, -1.6364));
  }

  /// alpha = 10^(-0.4 * k * (X - 1))
  static double extinctionAlpha(double zDeg) => math
      .min(1.0, math.pow(10, -0.4 * extinctionK * (airmass(zDeg) - 1)))
      .toDouble();

  // Positions and ladder steps precomputed from the model above and verified
  // against `gradient-extinction` in globals.css. A null step is transparent.
  static const List<double> _extinctionStops = <double>[
    0, 0.667, 0.778, 0.867, 0.933, 0.978, 1,
  ];
  static const List<int?> _extinctionSteps = <int?>[0, 0, 1, 1, 3, 7, null];

  /// Zenith-to-horizon fade. Defaults to top (zenith) down to bottom (horizon).
  static LinearGradient extinction(
    Color base, {
    AlignmentGeometry begin = Alignment.topCenter,
    AlignmentGeometry end = Alignment.bottomCenter,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: _colors(base, _extinctionSteps),
      stops: _extinctionStops,
    );
  }

  // --- Moffat profile (radial glow) -----------------------------------------

  static const double moffatBeta = 3;

  /// Gradient radius in units of the profile's scale length `a`.
  static const double moffatRadiusInA = 4;

  /// I(r) = (1 + (r / a)^2)^-beta
  static double moffatIntensity(double rOverA) =>
      math.pow(1 + rOverA * rOverA, -moffatBeta).toDouble();

  static const List<double> _moffatStops = <double>[
    0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 1,
  ];
  static const List<int?> _moffatSteps = <int?>[0, 1, 3, 6, 8, 10, null, null];

  /// Bright core with a long soft tail. `radius: 0.5` is the closest side,
  /// matching CSS `radial-gradient(circle closest-side, ...)`.
  static RadialGradient moffat(
    Color base, {
    AlignmentGeometry center = Alignment.center,
  }) {
    return RadialGradient(
      center: center,
      radius: 0.5,
      colors: _colors(base, _moffatSteps),
      stops: _moffatStops,
    );
  }

  static List<Color> _colors(Color base, List<int?> steps) => <Color>[
        for (final int? s in steps)
          base.withValues(alpha: s == null ? 0 : Mag.steps[s]),
      ];
}
