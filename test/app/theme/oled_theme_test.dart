import 'package:astr/app/theme/app_theme.dart';
import 'package:astr/core/design/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OLED Theme Tests (Story 4.2 - NFR-09)', () {
    test('AppColors.oledBlack should be pure black (#000000)', () {
      // Arrange & Act
      const Color oledBlack = AppColors.oledBlack;

      // Assert
      expect(oledBlack.value, equals(0xFF000000));
      expect(oledBlack.red, equals(0));
      expect(oledBlack.green, equals(0));
      expect(oledBlack.blue, equals(0));
      expect(oledBlack.alpha, equals(255));
    });

    test('darkTheme should use AppColors.oledBlack for scaffoldBackground', () {
      // Arrange
      final ThemeData theme = AppTheme.darkTheme;

      // Act
      final Color scaffoldBg = theme.scaffoldBackgroundColor;

      // Assert
      expect(scaffoldBg, equals(AppColors.oledBlack));
    });

    test('darkTheme should use AppColors.oledBlack for surface color', () {
      // Arrange
      final ThemeData theme = AppTheme.darkTheme;

      // Act
      final Color surface = theme.colorScheme.surface;

      // Assert
      expect(surface, equals(AppColors.oledBlack));
    });

    test('onPrimary should use AppColors.oledBlack for high contrast', () {
      // Arrange
      final ThemeData theme = AppTheme.darkTheme;

      // Act
      final Color onPrimary = theme.colorScheme.onPrimary;

      // Assert: onPrimary should match the surface background color
      expect(onPrimary, equals(AppColors.oledBlack));
    });
  });
}
