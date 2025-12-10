import 'dart:math';
import 'package:astr/features/dashboard/domain/entities/hourly_forecast.dart';
import 'package:astr/features/catalog/domain/entities/graph_point.dart';
import 'package:astr/features/astronomy/domain/entities/moon_phase_info.dart';

/// Represents the optimal observing window
class PrimeViewWindow {
  final DateTime start;
  final DateTime end;
  final double score; // 0.0 (perfect) to 1.0 (terrible)

  const PrimeViewWindow({
    required this.start,
    required this.end,
    required this.score,
  });

  /// Duration of the prime view window
  Duration get duration => end.difference(start);

  @override
  String toString() => 'PrimeViewWindow(start: $start, end: $end, score: ${score.toStringAsFixed(2)})';
}

/// Calculator for finding the optimal observing window based on weather and moon conditions
class PrimeViewCalculator {
  /// Maximum acceptable score threshold (0-1 scale)
  /// Windows with scores above this are considered "poor" and won't be returned
  static const double qualityThreshold = 0.8;

  /// Minimum duration (in hours) for a valid prime view window
  static const int minWindowHours = 2;

  /// Calculate the Prime View window for the given conditions
  ///
  /// Returns the contiguous time window with the lowest combined score of:
  /// - Cloud cover (0% = perfect, 100% = terrible)
  /// - Moon interference (based on illumination × altitude)
  ///
  /// Returns null if:
  /// - No data available
  /// - All conditions exceed quality threshold (too poor)
  /// - No contiguous window meets minimum duration
  PrimeViewWindow? calculatePrimeView({
    required List<HourlyForecast> cloudCoverData,
    required List<GraphPoint>? moonCurve,
    required MoonPhaseInfo moonPhase,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    if (cloudCoverData.isEmpty) return null;

    // Filter data to night window
    final relevantForecasts = cloudCoverData
        .where((f) => !f.time.isBefore(startTime) && !f.time.isAfter(endTime))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    if (relevantForecasts.isEmpty) return null;

    // Calculate scores for each hourly point
    final scores = <_ScoredPoint>[];
    for (final forecast in relevantForecasts) {
      final cloudScore = forecast.cloudCover / 100.0; // 0.0 to 1.0

      // Calculate moon interference
      double moonScore = 0.0;
      if (moonCurve != null && moonCurve.isNotEmpty) {
        // Find moon altitude at this time
        final moonAltitude = _getMoonAltitudeAt(forecast.time, moonCurve);
        if (moonAltitude > 0) {
          // Moon is above horizon - calculate interference
          // Interference = illumination × (altitude/90) × seeing impact factor
          // Higher altitude = more light pollution
          moonScore = moonPhase.illumination * (moonAltitude / 90.0);
        }
      }

      final totalScore = _calculateCombinedScore(cloudScore, moonScore);
      scores.add(_ScoredPoint(time: forecast.time, score: totalScore));
    }

    if (scores.isEmpty) return null;

    // Find the best contiguous window
    return _findBestContiguousWindow(scores, minWindowHours);
  }

  /// Combines cloud and moon scores with appropriate weighting
  /// Cloud cover is weighted more heavily (70%) than moon (30%)
  double _calculateCombinedScore(double cloudScore, double moonScore) {
    const cloudWeight = 0.7;
    const moonWeight = 0.3;
    return (cloudScore * cloudWeight) + (moonScore * moonWeight);
  }

  /// Gets moon altitude at specific time by interpolating from curve
  double _getMoonAltitudeAt(DateTime time, List<GraphPoint> moonCurve) {
    if (moonCurve.isEmpty) return 0.0;

    // Find surrounding points
    GraphPoint? before;
    GraphPoint? after;

    for (final point in moonCurve) {
      if (point.time.isBefore(time) || point.time.isAtSameMomentAs(time)) {
        before = point;
      }
      if (point.time.isAfter(time) || point.time.isAtSameMomentAs(time)) {
        after = point;
        break;
      }
    }

    // Exact match
    if (before != null && before.time.isAtSameMomentAs(time)) {
      return max(0.0, before.value);
    }
    if (after != null && after.time.isAtSameMomentAs(time)) {
      return max(0.0, after.value);
    }

    // Interpolate between points
    if (before != null && after != null) {
      final totalDuration = after.time.difference(before.time).inSeconds;
      if (totalDuration == 0) return max(0.0, before.value);

      final elapsed = time.difference(before.time).inSeconds;
      final ratio = elapsed / totalDuration;

      final interpolated = before.value + (after.value - before.value) * ratio;
      return max(0.0, interpolated);
    }

    // Extrapolate from closest point
    if (before != null) return max(0.0, before.value);
    if (after != null) return max(0.0, after.value);

    return 0.0;
  }

  /// Finds the best contiguous window meeting minimum duration
  /// Uses a sliding window approach to find the period with lowest average score
  PrimeViewWindow? _findBestContiguousWindow(
    List<_ScoredPoint> scores,
    int minHours,
  ) {
    if (scores.isEmpty) return null;

    // Try different window sizes from minHours to full night
    PrimeViewWindow? bestWindow;
    double bestScore = double.infinity;

    // Window size in number of hourly points
    // Need minHours + 1 points to span minHours duration
    // (e.g., 3 points span 2 hours: 8PM, 9PM, 10PM = 8-10PM = 2 hours)
    final minWindowSize = minHours + 1;

    // Ensure we have enough points for minimum window
    if (scores.length < minWindowSize) return null;

    for (int windowSize = minWindowSize; windowSize <= scores.length; windowSize++) {
      // Slide window across the scores
      for (int i = 0; i <= scores.length - windowSize; i++) {
        final windowScores = scores.sublist(i, i + windowSize);
        final avgScore = windowScores.map((s) => s.score).reduce((a, b) => a + b) / windowSize;

        if (avgScore < bestScore) {
          bestScore = avgScore;
          bestWindow = PrimeViewWindow(
            start: windowScores.first.time,
            end: windowScores.last.time,
            score: avgScore,
          );
        }
      }
    }

    // Return null if best window exceeds quality threshold
    if (bestWindow != null && bestWindow.score > qualityThreshold) {
      return null;
    }

    return bestWindow;
  }
}

/// Internal class for tracking scored time points
class _ScoredPoint {
  final DateTime time;
  final double score;

  _ScoredPoint({required this.time, required this.score});
}
