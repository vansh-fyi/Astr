import 'dart:math' as math;

/// Astr layout and size constraints: Fibonacci numbers and the golden section.
///
/// Mirrors `scale.css`. Every constant here is a base value (at a 16 dp unit).
/// Multiply it by [AstrFluid.factor] for the width of the box it sits in, so the
/// interface scales with the screen on the same proportions. Widths and
/// breakpoints are Fibonacci numbers, and the three documentation panes are
/// consecutive terms (233, 377 and 610), so each neighbouring pair is one
/// golden ratio apart.
abstract final class AstrFluid {
  /// Container width where the liquid unit is pinned to the base (16 dp).
  static const double minWidth = 377;

  /// Container width where the unit has grown by the square root of phi.
  static const double maxWidth = 1597;

  /// sqrt(phi): how much the unit has grown at [maxWidth].
  static const double growth = 1.272019649514069;

  /// Scale factor for a container [width] (use `constraints.maxWidth` from a
  /// `LayoutBuilder` at the root of a screen). It is 1 up to [minWidth], rises
  /// linearly to [growth] at [maxWidth] and keeps rising at the same rate.
  /// The same expression as `--u` in `scale.css`, divided by 16.
  static double factor(double width) => math.max(
        1,
        1 + (width - minWidth) / (maxWidth - minWidth) * (growth - 1),
      );
}

abstract final class AstrLayout {
  // --- Golden section --------------------------------------------------------

  static const double phi = 1.618033988749895;

  /// 1 / phi, the larger part when a length is split in the golden ratio.
  static const double major = 0.618;

  /// 1 / phi^2, the smaller part.
  static const double minor = 0.382;

  /// Width over height of a landscape golden rectangle (use 1 / this for portrait).
  static const double goldenAspect = 1.618;

  // --- Widths and breakpoints (logical pixels) -------------------------------

  static const double w233 = 233;
  static const double w377 = 377;
  static const double w610 = 610;
  static const double w987 = 987;

  /// Reading measure in characters. It follows the type size, so it never
  /// needs a pixel value: `ConstrainedBox` with `maxWidth: measureChars * size / 2`
  /// is a close fit for Inter.
  static const int measureChars = 76;

  /// Pane proportions of the documentation layout (sidebar : article : outline).
  static const List<double> panes = <double>[233, 610, 144];

  static const double bp377 = 377;
  static const double bp610 = 610;
  static const double bp987 = 987;
  static const double bp1597 = 1597;
}

/// Element size constraints, all Fibonacci numbers (logical pixels).
abstract final class AstrSize {
  /// Hairline borders and focus rings.
  static const double hairline = 1;
  static const double focusRing = 2;

  /// Icons.
  static const double iconSmall = 13;
  static const double icon = 21;
  static const double iconLarge = 34;

  /// Control heights. A compact control must still reach [touchTarget] with an
  /// invisible hit area, never by growing its drawn size.
  static const double controlCompact = 34;
  static const double control = 55;

  /// Minimum touch target. Platform guidance is 44 pt on iOS and 48 dp on
  /// Android; 55 is the next Fibonacci number above both.
  static const double touchTarget = 55;

  /// Marks and avatars.
  static const double markSmall = 34;
  static const double mark = 55;
  static const double markLarge = 89;
}
