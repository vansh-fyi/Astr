class PlannerLogic {
  /// Calculates a 1-5 star rating based on cloud cover, moon illumination, and light pollution.
  ///
  /// Logic:
  /// - Cloud Cover (0-100%): Heavily weighted. >80% clouds = 1 star.
  /// - Moon Illumination (0.0-1.0): Affects visibility of deep sky objects.
  /// - Bortle Scale (1-9): Light pollution penalty.
  ///
  /// Heuristic:
  /// 1. Base Score = 100
  /// 2. Cloud Penalty: -1 point per 1% cloud cover.
  /// 3. Moon Penalty: -30 points * moonIllumination.
  /// 4. Bortle Penalty: -(Bortle - 1) * 5 points. (Bortle 1 = 0, Bortle 9 = -40)
  /// 5. Map Score to 1-5:
  ///    - > 80: 5 stars
  ///    - > 60: 4 stars
  ///    - > 40: 3 stars
  ///    - > 20: 2 stars
  ///    - <= 20: 1 star
  int calculateStarRating({
    required double cloudCoverAvg,
    required double moonIllumination,
    required int bortleScale,
  }) {
    // 1. Cloud Penalty (Critical)
    // If it's completely cloudy, it's bad regardless of anything else.
    if (cloudCoverAvg > 80) return 1;

    double score = 100;

    // Cloud Penalty: Linear reduction
    score -= cloudCoverAvg;

    // Moon Penalty: Max 30 points reduction (Full Moon)
    // We only penalize if clouds are low enough to see the moon/stars
    if (cloudCoverAvg < 50) {
      score -= (moonIllumination * 30);
    }

    // Bortle Penalty:
    // Bortle 1 (Excellent) -> 0 penalty
    // Bortle 9 (City) -> 40 penalty
    // This ensures a city user rarely gets 5 stars unless conditions are perfect.
    score -= ((bortleScale - 1) * 5);

    // Clamp score
    if (score < 0) score = 0;

    // Map to 1-5
    if (score >= 80) return 5;
    if (score >= 60) return 4;
    if (score >= 40) return 3;
    if (score >= 20) return 2;
    return 1;
  }
}
