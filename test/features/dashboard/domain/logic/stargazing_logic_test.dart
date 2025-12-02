import 'package:astr/features/dashboard/domain/entities/stargazing_quality.dart';
import 'package:astr/features/dashboard/domain/logic/stargazing_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StargazingLogic', () {
    test('returns Excellent when conditions are perfect', () {
      final result = StargazingLogic.calculate(
        cloudCover: 5,
        moonPhase: 10,
        bortleLevel: 3,
      );
      expect(result, StargazingQuality.excellent);
    });

    test('returns Good when conditions are slightly degraded', () {
      final result = StargazingLogic.calculate(
        cloudCover: 20,
        moonPhase: 40,
        bortleLevel: 5,
      );
      expect(result, StargazingQuality.good);
    });

    test('returns Fair when cloud cover is moderate', () {
      final result = StargazingLogic.calculate(
        cloudCover: 50,
        moonPhase: 80, // High moon doesn't prevent Fair if cloud is okay
        bortleLevel: 8, // High bortle doesn't prevent Fair if cloud is okay
      );
      expect(result, StargazingQuality.fair);
    });

    test('returns Poor when cloud cover is high', () {
      final result = StargazingLogic.calculate(
        cloudCover: 70,
        moonPhase: 0,
        bortleLevel: 1,
      );
      expect(result, StargazingQuality.poor);
    });

    test('returns Good when Excellent conditions missed by one parameter (e.g. Moon)', () {
      final result = StargazingLogic.calculate(
        cloudCover: 5,
        moonPhase: 30, // > 25
        bortleLevel: 3,
      );
      expect(result, StargazingQuality.good);
    });
    
    test('returns Poor when Fair conditions missed (Cloud >= 60)', () {
       final result = StargazingLogic.calculate(
        cloudCover: 60,
        moonPhase: 0,
        bortleLevel: 1,
      );
      expect(result, StargazingQuality.poor);
    });
  });
}
