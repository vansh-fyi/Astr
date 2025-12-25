import '../../../../core/engine/models/condition_quality.dart';
import '../../../../core/engine/models/condition_result.dart';
import '../../../../core/services/qualitative/qualitative_condition_service.dart';
import '../../../../core/utils/bortle_mpsas_converter.dart';

class PlannerLogic {
  final QualitativeConditionService _conditionService = QualitativeConditionService();

  /// Calculates a 1-5 star rating based on cloud cover, moon illumination, and light pollution.
  ///
  /// Uses the same QualitativeConditionService as the home screen for consistency.
  /// Maps quality levels to star ratings:
  /// - Excellent -> 5 stars
  /// - Good -> 4 stars
  /// - Fair -> 3 stars
  /// - Poor -> 1-2 stars (depending on cloud cover)
  int calculateStarRating({
    required double cloudCoverAvg,
    required double moonIllumination,
    required int bortleScale,
  }) {
    // Convert Bortle to MPSAS
    final double mpsas = BortleMpsasConverter.bortleToMpsas(bortleScale);

    // Evaluate conditions using the same service as home screen
    final ConditionResult result = _conditionService.evaluate(
      cloudCover: cloudCoverAvg,
      moonIllumination: moonIllumination,
      mpsas: mpsas,
    );

    // Map quality to star rating
    switch (result.quality) {
      case ConditionQuality.excellent:
        return 5;
      case ConditionQuality.good:
        return 4;
      case ConditionQuality.fair:
        return 3;
      case ConditionQuality.poor:
        // Poor conditions: differentiate based on severity
        // Very cloudy (>80%) = 1 star, otherwise 2 stars
        return cloudCoverAvg > 80 ? 1 : 2;
      case ConditionQuality.unknown:
        // If quality unknown, fallback to basic cloud-based rating
        return cloudCoverAvg > 80 ? 1 : 2;
    }
  }
}
