import 'package:flutter_test/flutter_test.dart';
import 'package:astr/features/planner/domain/logic/planner_logic.dart';

void main() {
  late PlannerLogic plannerLogic;

  setUp(() {
    plannerLogic = PlannerLogic();
  });

  group('PlannerLogic - using QualitativeConditionService', () {
    test('should return 1 star if cloud cover > 80%', () {
      // Heavy clouds trigger "Sky might be cloudy" -> Poor -> 1 star
      expect(plannerLogic.calculateStarRating(cloudCoverAvg: 90, moonIllumination: 0.0, bortleScale: 1), 1);
      expect(plannerLogic.calculateStarRating(cloudCoverAvg: 100, moonIllumination: 0.0, bortleScale: 1), 1);
    });

    test('should return 5 stars for perfect conditions (0% clouds, new moon, Bortle 1)', () {
      // Bortle 1 -> MPSAS ~21.85, cloudCover 0%, moonIllumination 0.0 -> Excellent -> 5 stars
      expect(plannerLogic.calculateStarRating(cloudCoverAvg: 0, moonIllumination: 0.0, bortleScale: 1), 5);
    });

    test('should achieve Excellent even with full moon in truly dark skies (Bortle 1)', () {
      // Bortle 1 -> MPSAS ~21.85, cloudCover 0%, Excellent achievable despite moon in dark skies
      expect(plannerLogic.calculateStarRating(cloudCoverAvg: 0, moonIllumination: 1.0, bortleScale: 1), 5);
    });

    test('should return 4 stars for Good conditions (moderate clouds, Bortle 5)', () {
      // Bortle 5 -> MPSAS ~19.75, cloudCover 30%, moonIllumination 0.5 -> Good -> 4 stars
      expect(plannerLogic.calculateStarRating(cloudCoverAvg: 30, moonIllumination: 0.5, bortleScale: 5), 4);
    });

    test('should return 3 stars for Fair conditions (moderate clouds, full moon, Bortle 6)', () {
      // Bortle 6 -> MPSAS ~18.55, cloudCover 50%, moonIllumination 1.0 -> Fair -> 3 stars
      expect(plannerLogic.calculateStarRating(cloudCoverAvg: 50, moonIllumination: 1.0, bortleScale: 6), 3);
    });

    test('should return 3 stars for Fair conditions (Bortle 7, moderate clouds)', () {
      // Bortle 7 -> MPSAS ~18.5, cloudCover 60%, moonIllumination 0.5 -> Fair -> 3 stars
      expect(plannerLogic.calculateStarRating(cloudCoverAvg: 60, moonIllumination: 0.5, bortleScale: 7), 3);
    });

    test('should return 2 stars for Bortle 9 with clear skies (excessive light pollution)', () {
      // Bortle 9 -> MPSAS ~16.5, triggers "Excessive Light Pollution" -> Poor -> 2 stars (clouds <80%)
      expect(plannerLogic.calculateStarRating(cloudCoverAvg: 0, moonIllumination: 0.0, bortleScale: 9), 2);
    });

    test('should return 2 stars for Bortle 9 + Full Moon', () {
      // Bortle 9 -> MPSAS ~16.5, triggers "Excessive Light Pollution" -> Poor -> 2 stars
      expect(plannerLogic.calculateStarRating(cloudCoverAvg: 0, moonIllumination: 1.0, bortleScale: 9), 2);
    });

    test('should return 4 stars for Good conditions at Bortle 4 (not dark enough for Excellent)', () {
      // Bortle 4 -> MPSAS ~20.85, cloudCover 10%, moonIllumination 0.1 -> Good -> 4 stars
      // Bortle 4 cannot achieve Excellent (Milky Way visible) - only Bortle 1-3 can
      expect(plannerLogic.calculateStarRating(cloudCoverAvg: 10, moonIllumination: 0.1, bortleScale: 4), 4);
    });
  });
}
