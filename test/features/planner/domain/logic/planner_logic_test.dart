import 'package:flutter_test/flutter_test.dart';
import 'package:astr/features/planner/domain/logic/planner_logic.dart';

void main() {
  late PlannerLogic plannerLogic;

  setUp(() {
    plannerLogic = PlannerLogic();
  });

  group('PlannerLogic', () {
    test('should return 1 star if cloud cover is > 80%', () {
      expect(plannerLogic.calculateStarRating(cloudCoverAvg: 81, moonIllumination: 0.0, bortleScale: 1), 1);
      expect(plannerLogic.calculateStarRating(cloudCoverAvg: 100, moonIllumination: 0.0, bortleScale: 1), 1);
    });

    test('should return 5 stars for perfect conditions (0% clouds, 0.0 moon, Bortle 1)', () {
      // Score = 100 - 0 - 0 - 0 = 100 -> 5 stars
      expect(plannerLogic.calculateStarRating(cloudCoverAvg: 0, moonIllumination: 0.0, bortleScale: 1), 5);
    });

    test('should return lower rating for full moon even with clear skies (Bortle 1)', () {
      // Score = 100 - 0 - (1.0 * 30) - 0 = 70 -> 4 stars
      expect(plannerLogic.calculateStarRating(cloudCoverAvg: 0, moonIllumination: 1.0, bortleScale: 1), 4);
    });

    test('should return 3 stars for moderate clouds (40%) and new moon (Bortle 1)', () {
      // Score = 100 - 40 - (0 * 30) - 0 = 60 -> 4 stars
      expect(plannerLogic.calculateStarRating(cloudCoverAvg: 40, moonIllumination: 0.0, bortleScale: 1), 4);
    });

    test('should return 2 stars for moderate clouds (50%) and full moon (Bortle 1)', () {
      // Score = 100 - 50 = 50. (No moon penalty as clouds >= 50)
      // 50 >= 40 -> 3 stars.
      expect(plannerLogic.calculateStarRating(cloudCoverAvg: 50, moonIllumination: 1.0, bortleScale: 1), 3);
    });

    test('should return 1 star for heavy clouds (70%) (Bortle 1)', () {
      // Score = 100 - 70 = 30.
      // 30 >= 20 -> 2 stars.
      expect(plannerLogic.calculateStarRating(cloudCoverAvg: 70, moonIllumination: 0.0, bortleScale: 1), 2);
    });

    // New Tests for Bortle Scale
    test('should penalize for light pollution (Bortle 9)', () {
      // Perfect weather but City lights.
      // Score = 100 - 0 - 0 - ((9-1)*5) = 100 - 40 = 60.
      // 60 -> 4 stars.
      expect(plannerLogic.calculateStarRating(cloudCoverAvg: 0, moonIllumination: 0.0, bortleScale: 9), 4);
    });

    test('should degrade significantly for Bortle 9 + Full Moon', () {
      // Score = 100 - 0 - 30 - 40 = 30.
      // 30 -> 2 stars.
      expect(plannerLogic.calculateStarRating(cloudCoverAvg: 0, moonIllumination: 1.0, bortleScale: 9), 2);
    });
  });
}
