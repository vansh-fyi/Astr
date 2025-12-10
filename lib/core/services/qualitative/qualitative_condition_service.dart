import 'package:flutter/material.dart';
import 'package:astr/core/engine/models/condition_quality.dart';
import 'package:astr/core/engine/models/condition_result.dart';

/// Service for evaluating qualitative observing conditions
///
/// Combines weather, moon, and darkness data to provide user-friendly advice
class QualitativeConditionService {
  /// Evaluates current observing conditions and returns qualitative result
  ///
  /// [cloudCover] Cloud coverage percentage (0-100)
  /// [moonIllumination] Moon illumination fraction (0.0-1.0)
  /// [mpsas] Sky brightness in magnitudes per square arcsecond (17-22)
  ///
  /// Returns [ConditionResult] with quality assessment and advice
  ConditionResult evaluate({
    required double cloudCover,
    required double moonIllumination,
    required double mpsas,
  }) {
    // Normalize inputs to 0-1 scale (higher = better)
    final double cloudScore = _normalizeCloudCover(cloudCover);
    final double moonScore = _normalizeMoonIllumination(moonIllumination);
    final double darknessScore = _normalizeMPSAS(mpsas);

    // Weighted combination
    // Cloud cover is most critical (40%), followed by darkness (35%) and moon (25%)
    const double cloudWeight = 0.40;
    const double darknessWeight = 0.35;
    const double moonWeight = 0.25;

    final double overallScore =
        (cloudScore * cloudWeight) +
        (darknessScore * darknessWeight) +
        (moonScore * moonWeight);

    // Determine quality and generate advice
    return _determineQualityAndAdvice(
      overallScore: overallScore,
      cloudCover: cloudCover,
      moonIllumination: moonIllumination,
      mpsas: mpsas,
    );
  }

  /// Normalizes cloud cover to 0-1 scale (lower cloud = higher score)
  double _normalizeCloudCover(double cloudCover) {
    // 0% cloud = 1.0, 100% cloud = 0.0
    return 1.0 - (cloudCover / 100.0).clamp(0.0, 1.0);
  }

  /// Normalizes moon illumination to 0-1 scale (lower illumination = higher score)
  double _normalizeMoonIllumination(double moonIllumination) {
    // New moon (0.0) = 1.0, Full moon (1.0) = 0.0
    return 1.0 - moonIllumination.clamp(0.0, 1.0);
  }

  /// Normalizes MPSAS to 0-1 scale (higher MPSAS = higher score)
  double _normalizeMPSAS(double mpsas) {
    // Map 17.0-22.0 MPSAS range to 0.0-1.0
    // 17.0 (bright city) = 0.0, 22.0 (dark sky) = 1.0
    const double minMPSAS = 17.0;
    const double maxMPSAS = 22.0;
    return ((mpsas - minMPSAS) / (maxMPSAS - minMPSAS)).clamp(0.0, 1.0);
  }

  /// Determines quality level and generates appropriate advice
  ConditionResult _determineQualityAndAdvice({
    required double overallScore,
    required double cloudCover,
    required double moonIllumination,
    required double mpsas,
  }) {
    // Check for high cloud cover first (most immediate blocker)
    if (cloudCover > 70.0) {
      return const ConditionResult(
        quality: ConditionQuality.poor,
        shortSummary: 'Poor',
        detailedAdvice: 'Sky might be cloudy',
        statusColor: Color(0xFFF44336), // Red
      );
    }

    // Check for extreme light pollution (Bortle Zone 8-9)
    if (mpsas < 17.5) {
      return const ConditionResult(
        quality: ConditionQuality.poor,
        shortSummary: 'Poor',
        detailedAdvice: 'Excessive Light Pollution',
        statusColor: Color(0xFFF44336), // Red
      );
    }

    // Excellent: Score > 0.60, Low clouds (<30%), Truly dark skies (>=21.3)
    // Only achievable in Bortle 1-3 zones (dark sky sites with Milky Way visible)
    if (overallScore > 0.60 && cloudCover < 30.0 && mpsas >= 21.3) {
      return const ConditionResult(
        quality: ConditionQuality.excellent,
        shortSummary: 'Excellent',
        detailedAdvice: 'Milky Way visible',
        statusColor: Color(0xFF4CAF50), // Green
      );
    }

    // Good: Score > 0.40, Moderate clouds (<50%), Dark to suburban skies (>=19.1)
    // Achievable in Bortle 4-5 zones (rural/suburban with good star visibility)
    if (overallScore > 0.40 && cloudCover < 50.0 && mpsas >= 19.1) {
      return const ConditionResult(
        quality: ConditionQuality.good,
        shortSummary: 'Good',
        detailedAdvice: 'Starry sky today',
        statusColor: Color(0xFF8BC34A), // Light Green
      );
    }

    // Fair: Score > 0.25, Some visibility possible
    // More lenient threshold to accommodate various edge cases
    // But exclude extremely poor darkness (inner city) or very heavy clouds
    if (overallScore > 0.25 && cloudCover < 80.0 && mpsas > 17.3) {
      return const ConditionResult(
        quality: ConditionQuality.fair,
        shortSummary: 'Fair',
        detailedAdvice: 'Planets visible',
        statusColor: Color(0xFFFFEB3B), // Yellow
      );
    }

    // Poor: Everything else
    return const ConditionResult(
      quality: ConditionQuality.poor,
      shortSummary: 'Poor',
      detailedAdvice: 'Few stars visible',
      statusColor: Color(0xFFF44336), // Red
    );
  }
}
