import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astr/core/design/app_colors.dart';
import 'package:astr/core/design/app_typography.dart';
import 'package:astr/core/design/app_spacing.dart';

void main() {
  group('Design Tokens Tests', () {
    test('AppColors token values', () {
      expect(AppColors.surface, const Color(0xFF0C0F11));
      expect(AppColors.accent, const Color(0xFF448AFF));
      expect(AppColors.glowShadow.length, 2);
      expect(AppColors.glowShadow[1].color, const Color(0xFF3A7FFF));
    });

    test('AppSpacing token values', () {
      expect(AppSpacing.kConditionsCardWidth, 345.0);
      expect(AppSpacing.kMiniCardWidth, 164.0);
    });

    test('AppTypography token values', () {
      expect(AppTypography.display.fontSize, 72.0);
      expect(AppTypography.display.fontWeight, FontWeight.w700);
    });
  });
}
