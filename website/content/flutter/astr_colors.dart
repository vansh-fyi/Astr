import 'package:flutter/painting.dart';

/// Astr colour stops, mirrored value-for-value from `globals.css`.
///
/// Each palette is a [ColorSwatch] keyed by stop number, so a stop reads as
/// `AstrColors.auroraGreen[400]`. The swatch primary is stop 500.
/// Stops are fixed: apply opacity with the magnitude ladder in
/// `astr_opacity.dart`, never by editing a stop.
abstract final class AstrColors {
  /// Space Grey
  static const ColorSwatch<int> spaceGrey = ColorSwatch<int>(0xFF848484, <int, Color>{
    50: Color(0xFFF3F3F3),
    100: Color(0xFFE5E4E4),
    200: Color(0xFFCCCCCC),
    300: Color(0xFFB3B3B3),
    400: Color(0xFF9B9B9B),
    500: Color(0xFF848484),
    600: Color(0xFF686868),
    700: Color(0xFF555555),
    800: Color(0xFF3B3B3B),
    900: Color(0xFF282828),
    950: Color(0xFF030303),
  });

  /// Deep Space
  static const ColorSwatch<int> deepSpace = ColorSwatch<int>(0xFF021F45, <int, Color>{
    50: Color(0xFFD2D7FB),
    100: Color(0xFFB9C1FE),
    200: Color(0xFF6C95FC),
    300: Color(0xFF1458D6),
    400: Color(0xFF093B8C),
    500: Color(0xFF021F45),
    600: Color(0xFF021B3D),
    700: Color(0xFF011532),
    800: Color(0xFF010E2A),
    900: Color(0xFF020C1E),
    950: Color(0xFF000B17),
  });

  /// Aurora Pink
  static const ColorSwatch<int> auroraPink = ColorSwatch<int>(0xFFD64289, <int, Color>{
    50: Color(0xFFFBEDF2),
    100: Color(0xFFF8DBE4),
    200: Color(0xFFF2BACD),
    300: Color(0xFFED93C3),
    400: Color(0xFFE867B0),
    500: Color(0xFFD64289),
    600: Color(0xFFAA3282),
    700: Color(0xFF822566),
    800: Color(0xFF5D1847),
    900: Color(0xFF370A1F),
    950: Color(0xFF250513),
  });

  /// Aurora Green
  static const ColorSwatch<int> auroraGreen = ColorSwatch<int>(0xFF88E491, <int, Color>{
    50: Color(0xFFFEFFF8),
    100: Color(0xFFF2FBE8),
    200: Color(0xFFDDF7C4),
    300: Color(0xFFBEF4A3),
    400: Color(0xFFA6EE8E),
    500: Color(0xFF88E491),
    600: Color(0xFF69B276),
    700: Color(0xFF4C834E),
    800: Color(0xFF305640),
    900: Color(0xFF182F28),
    950: Color(0xFF0B1A1B),
  });

  /// Sodium Airglow
  static const ColorSwatch<int> sodiumAirglow = ColorSwatch<int>(0xFFF6A833, <int, Color>{
    50: Color(0xFFFEFBF0),
    100: Color(0xFFFEF1E0),
    200: Color(0xFFFDE3C3),
    300: Color(0xFFFBD49D),
    400: Color(0xFFFBBD6C),
    500: Color(0xFFF6A833),
    600: Color(0xFFC17E26),
    700: Color(0xFF90591A),
    800: Color(0xFF633B0E),
    900: Color(0xFF361E04),
    950: Color(0xFF231202),
  });

  /// Oxygen Airglow
  static const ColorSwatch<int> oxygenAirglow = ColorSwatch<int>(0xFFC10C0C, <int, Color>{
    50: Color(0xFFFEE9F0),
    100: Color(0xFFFED2E5),
    200: Color(0xFFFDA3AE),
    300: Color(0xFFFC6D6F),
    400: Color(0xFFF93E41),
    500: Color(0xFFC10C0C),
    600: Color(0xFF9A0707),
    700: Color(0xFF780404),
    800: Color(0xFF570202),
    900: Color(0xFF390101),
    950: Color(0xFF270000),
  });
}
