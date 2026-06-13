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

  group('Zone SQM boundary verification (ZONE-04)', () {
    // SQM boundaries derived from: SQM = 22.0 - 1.7 * log10(1 + 2*radiance)
    // See apply_skyglow.py ZONE_THRESHOLDS for the radiance→zone mapping.
    // Note: Zone 2 lower boundary SQM 21.70 exceeds the Excellent threshold (21.5),
    // so it correctly maps to 'Excellent', not 'Good' as the ZONE_THRESHOLDS comment
    // in the plan implies. The implementation thresholds are authoritative.

    test('SQM 21.70 (Zone 2 lower boundary, radiance=0.25) returns Excellent label', () {
      final (String label, _) = calculator.getDarknessLabel(21.70);
      expect(label, equals('Excellent'));
    });

    test('SQM 21.49 (Zone 3 lower boundary, radiance=0.50) returns Good label', () {
      final (String label, _) = calculator.getDarknessLabel(21.49);
      expect(label, equals('Good'));
    });

    test('SQM 21.19 (Zone 4 lower boundary, radiance=1.0) returns Good label', () {
      final (String label, _) = calculator.getDarknessLabel(21.19);
      expect(label, equals('Good'));
    });

    test('SQM 20.56 (Zone 5 lower boundary, radiance=3.0) returns Fair label', () {
      final (String label, _) = calculator.getDarknessLabel(20.56);
      expect(label, equals('Fair'));
    });

    test('SQM 19.83 (Zone 6 lower boundary, radiance=9.0) returns Poor label', () {
      final (String label, _) = calculator.getDarknessLabel(19.83);
      expect(label, equals('Poor'));
    });

    test('SQM 19.26 (Zone 7 lower boundary, radiance=20.0) returns Poor label', () {
      final (String label, _) = calculator.getDarknessLabel(19.26);
      expect(label, equals('Poor'));
    });

    test('SQM 18.59 (Zone 8 lower boundary, radiance=50.0) returns Very Poor label', () {
      final (String label, _) = calculator.getDarknessLabel(18.59);
      expect(label, equals('Very Poor'));
    });

    test('SQM 17.92 (Zone 9 lower boundary, radiance=125.0) returns Very Poor label', () {
      final (String label, _) = calculator.getDarknessLabel(17.92);
      expect(label, equals('Very Poor'));
    });

    test('Zone 2 boundary SQM (21.70) survives zero-moon calculateDarkness unchanged', () {
      final double result = calculator.calculateDarkness(
        baseMPSAS: 21.70,
        moonPhase: 0.0,
        moonAltitude: 0.0,
      );
      expect(result, closeTo(21.70, 0.001));
    });

    test('Full moon at zenith reduces Zone 3 baseMPSAS (21.49) to Very Poor', () {
      // baseMPSAS 21.49 − 4.0 penalty = 17.49 → Very Poor
      final double result = calculator.calculateDarkness(
        baseMPSAS: 21.49,
        moonPhase: 1.0,
        moonAltitude: 90.0,
      );
      expect(result, closeTo(17.49, 0.01));
      final (String label, _) = calculator.getDarknessLabel(result);
      expect(label, equals('Very Poor'));
    });
  });
}
