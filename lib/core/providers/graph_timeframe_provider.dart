import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/astronomy/domain/services/astronomy_service.dart';
import '../../features/context/domain/entities/astr_context.dart';
import '../../features/context/presentation/providers/astr_context_provider.dart';

/// Represents a time range for graph display (Sunset to Sunrise)
class GraphTimeframe {

  const GraphTimeframe({
    required this.start,
    required this.end,
  });
  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphTimeframe &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'GraphTimeframe(start: $start, end: $end)';
}

/// Provider for calculating the graph timeframe (Sunset to Sunrise)
///
/// This provider watches the selected date and location from astrContext,
/// then calculates the sunset/sunrise window for that night using the AstronomyService.
///
/// AC #1: Returns timeframe from Sunset (Day N) to Sunrise (Day N+1)
/// AC #2: Handles case when current time is outside window (shows relevant night)
///
/// Note: This is functionally equivalent to nightWindowProvider but provides
/// a structured GraphTimeframe object instead of a Map<String, DateTime>.
final AutoDisposeFutureProvider<GraphTimeframe> graphTimeframeProvider = FutureProvider.autoDispose<GraphTimeframe>(
  (AutoDisposeFutureProviderRef<GraphTimeframe> ref) async {
    final AstronomyService astronomyService = ref.watch(astronomyServiceProvider);
    final AsyncValue<AstrContext> contextState = ref.watch(astrContextProvider);

    if (!contextState.hasValue) {
      // Return default window if context not ready (e.g. now to now+12h)
      final DateTime now = DateTime.now();
      return GraphTimeframe(
        start: now,
        end: now.add(const Duration(hours: 12)),
      );
    }

    final AstrContext astrContext = contextState.value!;

    // Calculate the night window (sunset to sunrise)
    // getNightWindow already handles AC #2 logic:
    // - If time is before sunrise, returns yesterday's sunset → today's sunrise
    // - If time is during day, returns today's sunset → tomorrow's sunrise
    // - If time is after sunset, returns today's sunset → tomorrow's sunrise
    final Map<String, DateTime> nightWindow = await astronomyService.getNightWindow(
      date: astrContext.selectedDate,
      lat: astrContext.location.latitude,
      long: astrContext.location.longitude,
    );

    return GraphTimeframe(
      start: nightWindow['start']!,
      end: nightWindow['end']!,
    );
  },
);
