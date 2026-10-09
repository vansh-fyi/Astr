/// Astr spacing: Fibonacci numbers on a 16 dp base.
///
/// Steps are 1, 2, 3, 5, 8, 13, 21, 34, 55, 89 and 144 logical pixels.
/// Consecutive steps tend to the golden ratio, so any two neighbours look
/// related. The constants mirror the `--spacing-f*` values in `scale.css`
/// (1 rem = 16 dp), so web and Flutter lay out identically.
///
/// Usage: `const EdgeInsets.all(AstrSpace.f21)`
abstract final class AstrSpace {
  static const double f1 = 1;
  static const double f2 = 2;
  static const double f3 = 3;
  static const double f5 = 5;
  static const double f8 = 8;
  static const double f13 = 13;
  static const double f21 = 21;
  static const double f34 = 34;
  static const double f55 = 55;
  static const double f89 = 89;
  static const double f144 = 144;

  /// Every step in ascending order.
  static const List<double> steps = <double>[
    f1, f2, f3, f5, f8, f13, f21, f34, f55, f89, f144, //
  ];
}

/// Astr corner radii: Fibonacci numbers, mirrored from `--radius-f*`.
/// Pills use a fully rounded shape (`StadiumBorder`), not a number.
abstract final class AstrRadius {
  static const double f3 = 3;
  static const double f5 = 5;
  static const double f8 = 8;
  static const double f13 = 13;
  static const double f21 = 21;
  static const double f34 = 34;
}
