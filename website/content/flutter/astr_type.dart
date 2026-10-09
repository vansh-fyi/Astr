import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Astr type scale: golden-ratio half-steps from a 16 sp body.
///
/// For step n (-2 to 6):
///
///     size(n)     = round(16 * phi^(n/2))
///     leading(n)  = 1 + phi^-(1 + n/2)        (a multiple of the size)
///     tracking(n) = -(phi^(n/2) - 1) / 89     (em)
///
/// Two steps are one golden ratio. The constants mirror the `--text-s*`
/// values in `scale.css`
/// (`--text-s-2` is [sNeg2], `--text-s-1` is [sNeg1]). Flutter measures letter spacing in logical pixels,
/// so [style] multiplies the tracking by the size.
///
/// Satoshi is for headings and the wordmark (steps 2 to 6), Inter for body
/// text (steps -2 to 1).
abstract final class AstrType {
  static const double phi = 1.618033988749895;

  static const double sNeg2 = 10;
  static const double sNeg1 = 13;
  static const double s0 = 16;
  static const double s1 = 20;
  static const double s2 = 26;
  static const double s3 = 33;
  static const double s4 = 42;
  static const double s5 = 53;
  static const double s6 = 68;

  /// Line height as a multiple of the size, indexed by `n + 2`.
  static const List<double> leading = <double>[
    2, 1.786, 1.618, 1.486, 1.382, 1.3, 1.236, 1.186, 1.146, //
  ];

  /// Tracking in em, indexed by `n + 2`.
  static const List<double> tracking = <double>[
    0.0043, 0.0024, 0, -0.0031, -0.0069, -0.0119, -0.0182, -0.0262, -0.0364, //
  ];

  /// Sizes in ascending order, indexed by `n + 2`.
  static const List<double> sizes = <double>[
    sNeg2, sNeg1, s0, s1, s2, s3, s4, s5, s6, //
  ];

  /// The exact formulas, for checking the constants.
  static double sizeOf(int n) => (16 * math.pow(phi, n / 2)).roundToDouble();
  static double leadingOf(int n) =>
      (1 + math.pow(phi, -(1 + n / 2))).toDouble();
  static double trackingOf(int n) =>
      (-(math.pow(phi, n / 2) - 1) / 89).toDouble();

  /// Text style for step [n]. Steps 2 and up default to Satoshi.
  static TextStyle style(int n, {String? fontFamily}) {
    final int i = n + 2;
    return TextStyle(
      fontFamily: fontFamily ?? (n >= 2 ? 'Satoshi' : 'Inter'),
      fontSize: sizes[i],
      height: leading[i],
      letterSpacing: sizes[i] * tracking[i],
    );
  }
}
