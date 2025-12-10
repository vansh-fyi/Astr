import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // Colors
  static const Color deepCosmos = Color(0xFF020204);
  static const Color starlight = Color(0xFFFFFFFF);
  static const Color accentPurple = Color(0xFFB5179E);
  static const Color accentCyan = Color(0xFF4CC9F0);

  // Glassmorphism Constants
  static const double glassBlur = 16.0;
  static const double glassOpacity = 0.12;
  static const Color glassColor = Colors.white;
  static const BorderRadius glassRadius = BorderRadius.all(Radius.circular(16));

  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      scheme: FlexScheme.materialBaseline,
      surface: deepCosmos,
      background: deepCosmos,
      scaffoldBackground: deepCosmos,
      primary: starlight,
      onPrimary: deepCosmos,
      secondary: accentPurple,
      onSecondary: starlight,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
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
