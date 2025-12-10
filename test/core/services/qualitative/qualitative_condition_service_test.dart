import 'package:astr/core/services/qualitative/qualitative_condition_service.dart';
import 'package:astr/core/engine/models/condition_quality.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QualitativeConditionService', () {
    late QualitativeConditionService service;

    setUp(() {
      service = QualitativeConditionService();
    });

    group('Excellent Conditions', () {
      test('returns Excellent for perfect conditions (clear skies, new moon, dark site)', () {
        final result = service.evaluate(
          cloudCover: 5.0,
          moonIllumination: 0.0,
          mpsas: 21.8,
        );

        expect(result.quality, ConditionQuality.excellent);
        expect(result.shortSummary, 'Excellent');
        expect(result.detailedAdvice, 'Milky Way visible');
      });

      test('returns Excellent for near-perfect conditions in Bortle 3 zone', () {
        final result = service.evaluate(
          cloudCover: 15.0,
          moonIllumination: 0.2,
          mpsas: 21.4, // Bortle 3 zone
        );

        expect(result.quality, ConditionQuality.excellent);
        expect(result.shortSummary, 'Excellent');
      });
    });

    group('Good Conditions', () {
      test('returns Good for moderate conditions (some clouds, half moon, fair darkness)', () {
        final result = service.evaluate(
          cloudCover: 30.0,
          moonIllumination: 0.5,
          mpsas: 20.0,
        );

        expect(result.quality, ConditionQuality.good);
        expect(result.shortSummary, 'Good');
        expect(result.detailedAdvice, 'Starry sky today');
      });

      test('returns Good for clear skies in Bortle 5 zone despite bright moon', () {
        final result = service.evaluate(
          cloudCover: 10.0,
          moonIllumination: 0.8,
          mpsas: 19.8, // Bortle 5 zone
        );

        // Clear skies in suburban zone = good (not excellent, as Milky Way not visible)
        expect(result.quality, ConditionQuality.good);
      });
    });

    group('Fair Conditions', () {
      test('returns Fair for marginal conditions (moderate clouds, full moon)', () {
        final result = service.evaluate(
          cloudCover: 50.0,
          moonIllumination: 1.0,
          mpsas: 18.5,
        );

        expect(result.quality, ConditionQuality.fair);
        expect(result.shortSummary, 'Fair');
        expect(result.detailedAdvice, 'Planets visible');
      });

      test('returns Fair for clear skies with very poor darkness (city)', () {
        final result = service.evaluate(
          cloudCover: 20.0,
          moonIllumination: 0.3,
          mpsas: 17.5,
        );

        expect(result.quality, ConditionQuality.fair);
      });
    });

    group('Poor Conditions', () {
      test('returns Poor for heavy cloud cover', () {
        final result = service.evaluate(
          cloudCover: 90.0,
          moonIllumination: 0.0,
          mpsas: 21.0,
        );

        expect(result.quality, ConditionQuality.poor);
        expect(result.shortSummary, 'Poor');
        expect(result.detailedAdvice, 'Sky might be cloudy');
      });

      test('returns Poor for complete overcast', () {
        final result = service.evaluate(
          cloudCover: 100.0,
          moonIllumination: 0.5,
          mpsas: 19.0,
        );

        expect(result.quality, ConditionQuality.poor);
      });

      test('returns Poor for very bright city skies despite clear weather', () {
        final result = service.evaluate(
          cloudCover: 10.0,
          moonIllumination: 0.9,
          mpsas: 17.0,
        );

        expect(result.quality, ConditionQuality.poor);
        expect(result.detailedAdvice, 'Excessive Light Pollution');
      });
    });

    group('Edge Cases', () {
      test('handles minimum values (worst possible)', () {
        final result = service.evaluate(
          cloudCover: 100.0,
          moonIllumination: 1.0,
          mpsas: 17.0,
        );

        expect(result.quality, ConditionQuality.poor);
        expect(result.detailedAdvice, 'Sky might be cloudy');
      });

      test('handles maximum values (best possible)', () {
        final result = service.evaluate(
          cloudCover: 0.0,
          moonIllumination: 0.0,
          mpsas: 22.0,
        );

        expect(result.quality, ConditionQuality.excellent);
      });

      test('handles values slightly outside normal ranges', () {
        final result = service.evaluate(
          cloudCover: 105.0, // Above 100
          moonIllumination: 1.1, // Above 1.0
          mpsas: 23.0, // Above typical max
        );

        // Should not crash and should handle gracefully
        expect(result.quality, isA<ConditionQuality>());
      });
    });

    group('Threshold Boundary Tests', () {
      test('tests boundary between Excellent and Good', () {
        // At Excellent threshold: cloudCover < 30%, mpsas >= 21.3, overallScore > 0.60
        final atExcellent = service.evaluate(
          cloudCover: 25.0, // Below 30% threshold
          moonIllumination: 0.1,
          mpsas: 21.5, // Bortle 2 zone - truly dark
        );

        expect(atExcellent.quality, ConditionQuality.excellent);

        // Just below Excellent: Bortle 4 zone (not dark enough for Milky Way)
        final belowExcellent = service.evaluate(
          cloudCover: 25.0, // Below 30% threshold
          moonIllumination: 0.1,
          mpsas: 20.8, // Bortle 4 zone - below 21.3 threshold
        );

        expect(belowExcellent.quality, ConditionQuality.good); // Good, not Excellent
      });

      test('tests boundary between Fair and Poor', () {
        // Marginal Fair conditions (score should be > 0.25)
        final marginalFair = service.evaluate(
          cloudCover: 60.0, // 60% clouds
          moonIllumination: 0.5, // Half moon
          mpsas: 18.5, // Suburban sky
        );

        expect(marginalFair.quality, ConditionQuality.fair);

        // Just into Poor territory - heavy overcast
        final justPoor = service.evaluate(
          cloudCover: 85.0, // Above 80% threshold
          moonIllumination: 0.7,
          mpsas: 18.0,
        );

        expect(justPoor.quality, ConditionQuality.poor);

        // Poor due to extremely poor darkness (inner city)
        final poorDarkness = service.evaluate(
          cloudCover: 20.0, // Clear skies
          moonIllumination: 0.3,
          mpsas: 17.0, // Below 17.5 threshold - Zone 8-9
        );

        expect(poorDarkness.quality, ConditionQuality.poor);
        expect(poorDarkness.detailedAdvice, 'Excessive Light Pollution');
      });
    });
  });
}
