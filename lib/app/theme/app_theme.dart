// ignore_for_file: deprecated_member_use

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      scheme: FlexScheme.materialBaseline,
      surface: AppColors.oledBlack, // Pure black for OLED battery savings (NFR-09)
      background: AppColors.oledBlack, // Pure black for OLED battery savings (NFR-09)
      scaffoldBackground: AppColors.oledBlack, // Pure black for OLED battery savings (NFR-09)
      primary: AppColors.accent,
      primaryLightRef: AppColors.accent, // Fix FlexColorScheme warning
      onPrimary: AppColors.oledBlack, // Update to match new background
      secondary: AppColors.accent,
      secondaryLightRef: AppColors.accent, // Fix FlexColorScheme warning
      onSecondary: AppColors.textPrimary,
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
