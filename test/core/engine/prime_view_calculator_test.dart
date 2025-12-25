import 'package:astr/core/engine/prime_view_calculator.dart';
import 'package:astr/features/astronomy/domain/entities/moon_phase_info.dart';
import 'package:astr/features/catalog/domain/entities/graph_point.dart';
import 'package:astr/features/dashboard/domain/entities/hourly_forecast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrimeViewCalculator', () {
    late PrimeViewCalculator calculator;
    late DateTime startTime;
    late DateTime endTime;

    setUp(() {
      calculator = PrimeViewCalculator();
      // Set up a typical night window: 8 PM to 6 AM (10 hours)
      startTime = DateTime(2025, 12, 3, 20); // 8 PM
      endTime = DateTime(2025, 12, 4, 6); // 6 AM next day
    });

    group('AC #1: Prime View Calculation', () {
      test('calculates prime view for perfect conditions (clear skies, new moon)', () {
        // Perfect conditions: 0% cloud cover, new moon (no interference)
        final List<HourlyForecast> forecasts = _generateHourlyForecasts(startTime, 10, cloudCover: 0);
        const MoonPhaseInfo moonPhase = MoonPhaseInfo(illumination: 0, phaseAngle: 0);
        final List<GraphPoint> moonCurve = _generateMoonCurve(startTime, 10, belowHorizon: true);

        final PrimeViewWindow? result = calculator.calculatePrimeView(
          cloudCoverData: forecasts,
          moonCurve: moonCurve,
          moonPhase: moonPhase,
          startTime: startTime,
          endTime: endTime,
        );

        expect(result, isNotNull);
        expect(result!.score, lessThan(0.1)); // Near perfect score
        expect(result.duration.inHours, greaterThanOrEqualTo(2)); // Minimum window size
      });

      test('calculates prime view for good conditions (low clouds, crescent moon)', () {
        // Good conditions: 20% cloud cover, crescent moon
        final List<HourlyForecast> forecasts = _generateHourlyForecasts(startTime, 10, cloudCover: 20);
        const MoonPhaseInfo moonPhase = MoonPhaseInfo(illumination: 0.25, phaseAngle: 90);
        final List<GraphPoint> moonCurve = _generateMoonCurve(startTime, 10, maxAltitude: 30);

        final PrimeViewWindow? result = calculator.calculatePrimeView(
          cloudCoverData: forecasts,
          moonCurve: moonCurve,
          moonPhase: moonPhase,
          startTime: startTime,
          endTime: endTime,
        );

        expect(result, isNotNull);
        expect(result!.score, lessThan(0.4)); // Good score
      });

      test('finds best window in mixed conditions', () {
        // Mixed conditions: clear early, cloudy middle, clear late
        final List<HourlyForecast> forecasts = <HourlyForecast>[
          ..._generateHourlyForecasts(startTime, 3, cloudCover: 10), // 8-11 PM: Good
          ..._generateHourlyForecasts(startTime.add(const Duration(hours: 3)), 4, cloudCover: 80), // 11 PM-3 AM: Bad
          ..._generateHourlyForecasts(startTime.add(const Duration(hours: 7)), 3, cloudCover: 15), // 3-6 AM: Good
        ];
        const MoonPhaseInfo moonPhase = MoonPhaseInfo(illumination: 0.5, phaseAngle: 180);
        final List<GraphPoint> moonCurve = _generateMoonCurve(startTime, 10);

        final PrimeViewWindow? result = calculator.calculatePrimeView(
          cloudCoverData: forecasts,
          moonCurve: moonCurve,
          moonPhase: moonPhase,
          startTime: startTime,
          endTime: endTime,
        );

        expect(result, isNotNull);
        // Should find one of the clear windows (either early or late night)
        expect(result!.duration.inHours, greaterThanOrEqualTo(2));
        // Verify it's not in the cloudy middle period
        final DateTime middleTime = startTime.add(const Duration(hours: 5));
        expect(
          result.start.isAfter(middleTime) || result.end.isBefore(middleTime),
          isTrue,
        );
      });
    });

    group('AC #4: No Prime View (Poor Conditions)', () {
      test('returns null for terrible conditions (heavy overcast all night)', () {
        // Terrible conditions: 90% cloud cover, full moon high in sky all night
        final List<HourlyForecast> forecasts = _generateHourlyForecasts(startTime, 10, cloudCover: 90);
        const MoonPhaseInfo moonPhase = MoonPhaseInfo(illumination: 1, phaseAngle: 180);
        // Moon stays consistently high (80 degrees) all night
        final List<GraphPoint> moonCurve = _generateMoonCurve(startTime, 10, maxAltitude: 80, constantAltitude: true);

        final PrimeViewWindow? result = calculator.calculatePrimeView(
          cloudCoverData: forecasts,
          moonCurve: moonCurve,
          moonPhase: moonPhase,
          startTime: startTime,
          endTime: endTime,
        );

        // Should return null because all conditions exceed quality threshold
        // Score calculation: (0.9 * 0.7) + (1.0 * 80/90 * 0.3) = 0.63 + 0.267 = 0.897 > 0.8
        expect(result, isNull);
      });

      test('returns null when all windows exceed quality threshold', () {
        // Marginal conditions just above threshold (85% clouds)
        final List<HourlyForecast> forecasts = _generateHourlyForecasts(startTime, 10, cloudCover: 85);
        const MoonPhaseInfo moonPhase = MoonPhaseInfo(illumination: 0.9, phaseAngle: 170);
        // Moon stays consistently high all night
        final List<GraphPoint> moonCurve = _generateMoonCurve(startTime, 10, maxAltitude: 70, constantAltitude: true);

        final PrimeViewWindow? result = calculator.calculatePrimeView(
          cloudCoverData: forecasts,
          moonCurve: moonCurve,
          moonPhase: moonPhase,
          startTime: startTime,
          endTime: endTime,
        );

        // Score calculation: (0.85 * 0.7) + (0.9 * 70/90 * 0.3) = 0.595 + 0.21 = 0.805 > 0.8
        expect(result, isNull);
      });

      test('returns null when no data available', () {
        const MoonPhaseInfo moonPhase = MoonPhaseInfo(illumination: 0, phaseAngle: 0);

        final PrimeViewWindow? result = calculator.calculatePrimeView(
          cloudCoverData: <HourlyForecast>[],
          moonCurve: null,
          moonPhase: moonPhase,
          startTime: startTime,
          endTime: endTime,
        );

        expect(result, isNull);
      });
    });

    group('Moon Interference Calculation', () {
      test('considers moon altitude in interference score', () {
        final List<HourlyForecast> forecasts = _generateHourlyForecasts(startTime, 10, cloudCover: 10);
        const MoonPhaseInfo moonPhase = MoonPhaseInfo(illumination: 1, phaseAngle: 180);

        // Test 1: Moon below horizon (no interference)
        final List<GraphPoint> moonBelowHorizon = _generateMoonCurve(startTime, 10, belowHorizon: true);
        final PrimeViewWindow? resultBelowHorizon = calculator.calculatePrimeView(
          cloudCoverData: forecasts,
          moonCurve: moonBelowHorizon,
          moonPhase: moonPhase,
          startTime: startTime,
          endTime: endTime,
        );

        // Test 2: Moon high in sky (max interference)
        final List<GraphPoint> moonHighInSky = _generateMoonCurve(startTime, 10, maxAltitude: 80);
        final PrimeViewWindow? resultHighMoon = calculator.calculatePrimeView(
          cloudCoverData: forecasts,
          moonCurve: moonHighInSky,
          moonPhase: moonPhase,
          startTime: startTime,
          endTime: endTime,
        );

        // Score with moon below horizon should be better (lower) than with high moon
        expect(resultBelowHorizon!.score, lessThan(resultHighMoon!.score));
      });

      test('considers moon phase in interference score', () {
        final List<HourlyForecast> forecasts = _generateHourlyForecasts(startTime, 10, cloudCover: 10);
        final List<GraphPoint> moonCurve = _generateMoonCurve(startTime, 10);

        // Test 1: New moon (no interference)
        const MoonPhaseInfo newMoonPhase = MoonPhaseInfo(illumination: 0, phaseAngle: 0);
        final PrimeViewWindow? resultNewMoon = calculator.calculatePrimeView(
          cloudCoverData: forecasts,
          moonCurve: moonCurve,
          moonPhase: newMoonPhase,
          startTime: startTime,
          endTime: endTime,
        );

        // Test 2: Full moon (max interference)
        const MoonPhaseInfo fullMoonPhase = MoonPhaseInfo(illumination: 1, phaseAngle: 180);
        final PrimeViewWindow? resultFullMoon = calculator.calculatePrimeView(
          cloudCoverData: forecasts,
          moonCurve: moonCurve,
          moonPhase: fullMoonPhase,
          startTime: startTime,
          endTime: endTime,
        );

        // Score with new moon should be better (lower) than with full moon
        expect(resultNewMoon!.score, lessThan(resultFullMoon!.score));
      });
    });

    group('Performance & Edge Cases', () {
      test('completes calculation quickly (< 10ms per spec)', () {
        final List<HourlyForecast> forecasts = _generateHourlyForecasts(startTime, 10);
        const MoonPhaseInfo moonPhase = MoonPhaseInfo(illumination: 0.5, phaseAngle: 90);
        final List<GraphPoint> moonCurve = _generateMoonCurve(startTime, 10);

        final Stopwatch stopwatch = Stopwatch()..start();
        calculator.calculatePrimeView(
          cloudCoverData: forecasts,
          moonCurve: moonCurve,
          moonPhase: moonPhase,
          startTime: startTime,
          endTime: endTime,
        );
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });

      test('handles window spanning midnight correctly', () {
        // This is implicitly tested by our setup (8 PM to 6 AM)
        // Just verify it doesn't crash and produces reasonable results
        final List<HourlyForecast> forecasts = _generateHourlyForecasts(startTime, 10, cloudCover: 20);
        const MoonPhaseInfo moonPhase = MoonPhaseInfo(illumination: 0.3, phaseAngle: 60);
        final List<GraphPoint> moonCurve = _generateMoonCurve(startTime, 10);

        final PrimeViewWindow? result = calculator.calculatePrimeView(
          cloudCoverData: forecasts,
          moonCurve: moonCurve,
          moonPhase: moonPhase,
          startTime: startTime,
          endTime: endTime,
        );

        expect(result, isNotNull);
        expect(result!.start.isBefore(result.end), isTrue);
      });

      test('respects minimum window duration (2 hours)', () {
        final List<HourlyForecast> forecasts = _generateHourlyForecasts(startTime, 10);
        const MoonPhaseInfo moonPhase = MoonPhaseInfo(illumination: 0.3, phaseAngle: 60);
        final List<GraphPoint> moonCurve = _generateMoonCurve(startTime, 10);

        final PrimeViewWindow? result = calculator.calculatePrimeView(
          cloudCoverData: forecasts,
          moonCurve: moonCurve,
          moonPhase: moonPhase,
          startTime: startTime,
          endTime: endTime,
        );

        if (result != null) {
          expect(result.duration.inHours, greaterThanOrEqualTo(2));
        }
      });
    });
  });
}

/// Helper: Generate hourly forecasts with specified cloud cover
List<HourlyForecast> _generateHourlyForecasts(
  DateTime startTime,
  int hours, {
  double cloudCover = 30.0,
}) {
  return List.generate(hours, (int i) {
    return HourlyForecast(
      time: startTime.add(Duration(hours: i)),
      cloudCover: cloudCover,
      temperatureC: 15,
      humidity: 60,
      windSpeedKph: 10,
      seeingScore: 7,
      seeingLabel: 'Good',
    );
  });
}

/// Helper: Generate moon altitude curve
List<GraphPoint> _generateMoonCurve(
  DateTime startTime,
  int hours, {
  double maxAltitude = 45.0,
  bool belowHorizon = false,
  bool constantAltitude = false,
}) {
  return List.generate(hours, (int i) {
    final DateTime time = startTime.add(Duration(hours: i));

    double altitude;
    if (belowHorizon) {
      altitude = -10.0;
    } else if (constantAltitude) {
      // Keep moon at consistent altitude all night
      altitude = maxAltitude;
    } else {
      // Simple parabolic curve peaking at middle of night
      final double fraction = i / hours;
      altitude = maxAltitude * (1 - 4 * (fraction - 0.5) * (fraction - 0.5));
    }

    return GraphPoint(time: time, value: altitude);
  });
}
