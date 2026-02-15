import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // Colors
  static const Color deepCosmos = Color(0xFF020204); // Near-black (legacy)
  static const Color oledBlack = Color(0xFF000000); // Pure black for OLED (NFR-09)
  static const Color starlight = Color(0xFFFFFFFF);
  static const Color accentPurple = Color(0xFFB5179E);
  static const Color accentCyan = Color(0xFF4CC9F0);

  // Glassmorphism Constants
  static const double glassBlur = 16;
  static const double glassOpacity = 0.12;
  static const Color glassColor = Colors.white;
  static const BorderRadius glassRadius = BorderRadius.all(Radius.circular(16));

  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      scheme: FlexScheme.materialBaseline,
      surface: oledBlack, // Pure black for OLED battery savings (NFR-09)
      background: oledBlack, // Pure black for OLED battery savings (NFR-09)
      scaffoldBackground: oledBlack, // Pure black for OLED battery savings (NFR-09)
      primary: starlight,
      primaryLightRef: starlight, // Fix FlexColorScheme warning
      onPrimary: oledBlack, // Update to match new background
      secondary: accentPurple,
      secondaryLightRef: accentPurple, // Fix FlexColorScheme warning
      onSecondary: starlight,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      fontFamily: 'Satoshi',
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        blendTextTheme: true,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
        elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
        segmentedButtonSchemeColor: SchemeColor.primary,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorUnfocusedBorderIsColored: false,
        fabUseShape: true,
        fabAlwaysCircular: true,
        chipSchemeColor: SchemeColor.primary,
      ),
    );
  }
}
