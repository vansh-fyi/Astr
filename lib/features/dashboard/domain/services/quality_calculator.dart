import 'package:astr/features/dashboard/domain/entities/weather.dart';
import 'package:astr/features/astronomy/domain/entities/moon_phase_info.dart';

class QualityCalculator {
  /// Calculates the Stargazing Quality Score (0-100)
  /// Formula: (Bortle * 0.4) + (Cloud * 0.4) + (Moon * 0.2)
  /// 
  /// Inputs are normalized to 0-100 scale where 100 is best conditions:
  /// - Bortle: 1 is best (100), 9 is worst (0)
  /// - Cloud Cover: 0% is best (100), 100% is worst (0)
  /// - Moon Illumination: 0% is best (100), 100% is worst (0)
  static int calculateScore({
    required double bortleScale,
    required double cloudCover,
    required double moonIllumination,
  }) {
    // 1. Normalize Bortle (1-9) to 0-100 score
    // Bortle 1 -> 100, Bortle 9 -> 0
    // Linear interpolation: y = mx + c
    // 100 = m(1) + c
    // 0 = m(9) + c
    // m = -12.5, c = 112.5
    // Score = 112.5 - 12.5 * Bortle
    // Clamped between 0 and 100
    double bortleScore = (112.5 - (12.5 * bortleScale)).clamp(0.0, 100.0);

    // 2. Normalize Cloud Cover (0-100%) to 0-100 score
    // 0% clouds -> 100 score, 100% clouds -> 0 score
    double cloudScore = (100.0 - cloudCover).clamp(0.0, 100.0);

    // 3. Normalize Moon Illumination (0-1.0) to 0-100 score
    // 0.0 illumination -> 100 score, 1.0 illumination -> 0 score
    double moonScore = (100.0 - (moonIllumination * 100.0)).clamp(0.0, 100.0);

    // 4. Weighted Average
    // Weights: Bortle 0.4, Cloud 0.4, Moon 0.2
    double weightedScore = (bortleScore * 0.4) + (cloudScore * 0.4) + (moonScore * 0.2);

    return weightedScore.round();
  }

  static String getQualityLabel(int score) {
    if (score >= 90) return 'Perfect';
    if (score >= 80) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    if (score >= 30) return 'Poor';
    return 'Bad';
  }
}
