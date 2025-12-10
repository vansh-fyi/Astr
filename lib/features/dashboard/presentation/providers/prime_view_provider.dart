import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/engine/prime_view_calculator.dart';
import 'night_window_provider.dart';
import 'weather_provider.dart';
import '../../../catalog/presentation/providers/visibility_graph_notifier.dart';
import '../../../astronomy/presentation/providers/astronomy_provider.dart';

/// Provider for calculating the Prime View window (optimal observing time)
///
/// Combines:
/// - Cloud cover data (from weather)
/// - Moon altitude curve (from visibility graph)
/// - Moon phase/illumination (from astronomy provider)
///
/// Returns the contiguous time window with the best combined score,
/// or null if conditions are too poor (>80% cloud cover all night)
final primeViewProvider = FutureProvider<PrimeViewWindow?>((ref) async {
  // Get night window (start/end times for the graph)
  final nightWindow = await ref.watch(nightWindowProvider.future);
  final startTime = nightWindow['start']!;
  final endTime = nightWindow['end']!;

  // Get cloud cover data
  final hourlyForecast = await ref.watch(hourlyForecastProvider.future);
  if (hourlyForecast.isEmpty) return null;

  // Get moon data
  final moonGraphState = ref.watch(visibilityGraphProvider('moon'));
  final moonCurve = moonGraphState.graphData?.objectCurve;

  // Get moon phase info
  final astronomyState = await ref.watch(astronomyProvider.future);
  final moonPhase = astronomyState.moonPhaseInfo;

  // Calculate prime view window
  final calculator = PrimeViewCalculator();
  final primeWindow = calculator.calculatePrimeView(
    cloudCoverData: hourlyForecast,
    moonCurve: moonCurve,
    moonPhase: moonPhase,
    startTime: startTime,
    endTime: endTime,
  );

  return primeWindow;
});
