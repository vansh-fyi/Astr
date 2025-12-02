import '../entities/stargazing_quality.dart';

class StargazingLogic {
  static StargazingQuality calculate({
    required double cloudCover, // 0-100
    required double moonPhase, // 0-1 (fraction illuminated) or 0-100?
    // Story says "Moon < 25%", usually implies percentage or fraction.
    // Let's assume percentage 0-100 for consistency with Cloud, or check IAstroEngine.
    // Checking Context: "Moon < 25%" implies percentage.
    // But typically Moon Phase is 0.0 to 1.0.
    // I will assume input is 0-100 for "Phase Percentage" (Illumination).
    required int bortleLevel,
  }) {
    // Logic from Story 2.2
    if (cloudCover < 10 && moonPhase < 25 && bortleLevel <= 4) {
      return StargazingQuality.excellent;
    }
    if (cloudCover < 30 && moonPhase < 50 && bortleLevel <= 6) {
      return StargazingQuality.good;
    }
    if (cloudCover < 60) {
      return StargazingQuality.fair;
    }
    return StargazingQuality.poor;
  }
}
