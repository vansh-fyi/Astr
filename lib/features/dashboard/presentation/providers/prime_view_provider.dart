import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/engine/prime_view_calculator.dart';
import '../../../astronomy/domain/entities/astronomy_state.dart';
import '../../../astronomy/domain/entities/moon_phase_info.dart';
import '../../../astronomy/presentation/providers/astronomy_provider.dart';
import '../../../catalog/domain/entities/graph_point.dart';
import '../../../catalog/presentation/providers/visibility_graph_notifier.dart';
import '../../domain/entities/hourly_forecast.dart';
import 'night_window_provider.dart';
import 'weather_provider.dart';

/// Provider for calculating the Prime View window (optimal observing time)
///
/// Combines:
/// - Cloud cover data (from weather)
/// - Moon altitude curve (from visibility graph)
/// - Moon phase/illumination (from astronomy provider)
///
/// Returns the contiguous time window with the best combined score,
/// or null if conditions are too poor (>80% cloud cover all night)
final FutureProvider<PrimeViewWindow?> primeViewProvider = FutureProvider<PrimeViewWindow?>((FutureProviderRef<PrimeViewWindow?> ref) async {
  // Get night window (start/end times for the graph)
  final Map<String, DateTime> nightWindow = await ref.watch(nightWindowProvider.future);
  final DateTime startTime = nightWindow['start']!;
  final DateTime endTime = nightWindow['end']!;

  // Get cloud cover data
  final List<HourlyForecast> hourlyForecast = await ref.watch(hourlyForecastProvider.future);
  if (hourlyForecast.isEmpty) return null;

  // Get moon data
  final VisibilityGraphState moonGraphState = ref.watch(visibilityGraphProvider('moon'));
  final List<GraphPoint>? moonCurve = moonGraphState.graphData?.objectCurve;

  // Get moon phase info
  final AstronomyState astronomyState = await ref.watch(astronomyProvider.future);
  final MoonPhaseInfo moonPhase = astronomyState.moonPhaseInfo;

  // Calculate prime view window
  final PrimeViewCalculator calculator = PrimeViewCalculator();
  final PrimeViewWindow? primeWindow = calculator.calculatePrimeView(
    cloudCoverData: hourlyForecast,
    moonCurve: moonCurve,
    moonPhase: moonPhase,
    startTime: startTime,
    endTime: endTime,
  );

  return primeWindow;
});
