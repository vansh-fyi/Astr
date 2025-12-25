import 'package:astr/core/services/darkness_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for DarknessCalculator
/// Validates r^6 Darkness Model (MPSAS)
/// Reference: docs/calculations.md
void main() {
  late DarknessCalculator calculator;

  setUp(() {
    calculator = DarknessCalculator();
  });

  group('DarknessCalculator', () {
    test('should return base MPSAS when moon is below horizon', () {
      final double result = calculator.calculateDarkness(
        baseMPSAS: 21.5,
        moonPhase: 1, // Full Moon
        moonAltitude: -10, // Below horizon
      );
      expect(result, 21.5);
    });

    test('should return base MPSAS when moon is New (phase 0.0)', () {
      final double result = calculator.calculateDarkness(
        baseMPSAS: 21.5,
        moonPhase: 0, // New Moon
        moonAltitude: 45, // High up
      );
      expect(result, 21.5);
    });

    test('should apply max penalty for Full Moon at Zenith', () {
      final double result = calculator.calculateDarkness(
        baseMPSAS: 22,
        moonPhase: 1, // Full Moon
        moonAltitude: 90, // Zenith
      );
      // Penalty = 4.0 * 1.0 * sin(90) = 4.0
      // Result = 22.0 - 4.0 = 18.0
      expect(result, closeTo(18.0, 0.01));
    });

    test('should apply partial penalty for Full Moon at 30 degrees', () {
      final double result = calculator.calculateDarkness(
        baseMPSAS: 22,
        moonPhase: 1, // Full Moon
        moonAltitude: 30, 
      );
      // Penalty = 4.0 * 1.0 * sin(30) = 4.0 * 0.5 = 2.0
      // Result = 22.0 - 2.0 = 20.0
      expect(result, closeTo(20.0, 0.01));
    });

    test('should apply partial penalty for Half Moon at Zenith', () {
      final double result = calculator.calculateDarkness(
        baseMPSAS: 22,
        moonPhase: 0.5, // Half Moon
        moonAltitude: 90, // Zenith
      );
      // Penalty = 4.0 * 0.5 * sin(90) = 2.0
      // Result = 22.0 - 2.0 = 20.0
      expect(result, closeTo(20.0, 0.01));
    });
  });

  group('getDarknessLabel', () {
    test('should return Excellent for >= 21.5', () {
      expect(calculator.getDarknessLabel(21.5).$1, 'Excellent');
      expect(calculator.getDarknessLabel(22).$1, 'Excellent');
    });

    test('should return Good for 21.0 - 21.49', () {
      expect(calculator.getDarknessLabel(21).$1, 'Good');
      expect(calculator.getDarknessLabel(21.4).$1, 'Good');
    });

    test('should return Fair for 20.0 - 20.99', () {
      expect(calculator.getDarknessLabel(20).$1, 'Fair');
      expect(calculator.getDarknessLabel(20.9).$1, 'Fair');
    });

    test('should return Poor for 19.0 - 19.99', () {
      expect(calculator.getDarknessLabel(19).$1, 'Poor');
      expect(calculator.getDarknessLabel(19.9).$1, 'Poor');
    });

    test('should return Very Poor for < 19.0', () {
      expect(calculator.getDarknessLabel(18.9).$1, 'Very Poor');
      expect(calculator.getDarknessLabel(15).$1, 'Very Poor');
    });
  });
}
