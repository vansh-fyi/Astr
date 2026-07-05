import 'package:astr/app/theme/app_theme.dart';
import 'package:astr/core/design/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OLED Theme Tests (Story 4.2 - NFR-09)', () {
    test('oledBlack constant should be pure black (#000000)', () {
      // Arrange & Act
      const Color oledBlack = AppTheme.oledBlack;

      // Assert
      expect(oledBlack.value, equals(0xFF000000));
      expect(oledBlack.red, equals(0));
      expect(oledBlack.green, equals(0));
      expect(oledBlack.blue, equals(0));
      expect(oledBlack.alpha, equals(255));
    });

    test('darkTheme should use AppColors.surface for scaffoldBackground', () {
      // Arrange
      final ThemeData theme = AppTheme.darkTheme;

      // Act
      final Color scaffoldBg = theme.scaffoldBackgroundColor;

      // Assert
      expect(scaffoldBg, equals(AppColors.surface));
    });

    test('darkTheme should use AppColors.surface for surface color', () {
      // Arrange
      final ThemeData theme = AppTheme.darkTheme;

      // Act
      final Color surface = theme.colorScheme.surface;

      // Assert
      expect(surface, equals(AppColors.surface));
    });

    test('oledBlack should NOT equal deepCosmos (near-black)', () {
      // Arrange
      const Color oledBlack = AppTheme.oledBlack;
      const Color deepCosmos = AppTheme.deepCosmos;

      // Act & Assert: Verify they are different
      expect(oledBlack, isNot(equals(deepCosmos)));
      expect(oledBlack.value, equals(0xFF000000)); // Pure black
      expect(deepCosmos.value, equals(0xFF020204)); // Near-black
    });

    test('onPrimary should use AppColors.surface for high contrast', () {
      // Arrange
      final ThemeData theme = AppTheme.darkTheme;

      // Act
      final Color onPrimary = theme.colorScheme.onPrimary;

      // Assert: onPrimary should match the surface background color
      expect(onPrimary, equals(AppColors.surface));
    });
  });
}
