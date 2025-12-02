import 'package:astr/features/catalog/domain/entities/graph_point.dart';
import 'package:astr/features/catalog/domain/entities/time_range.dart';

/// Entity containing all data needed to render the visibility graph
class VisibilityGraphData {
  final List<GraphPoint> objectCurve; // Object altitude over time
  final List<GraphPoint> moonCurve;   // Moon interference over time
  final List<TimeRange> optimalWindows; // Time ranges where viewing is best
  final DateTime? sunRise;
  final DateTime? sunSet;
  final DateTime? moonRise;
  final DateTime? moonSet;

  const VisibilityGraphData({
    required this.objectCurve,
    required this.moonCurve,
    required this.optimalWindows,
    this.sunRise,
    this.sunSet,
    this.moonRise,
    this.moonSet,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisibilityGraphData &&
          runtimeType == other.runtimeType &&
          objectCurve == other.objectCurve &&
          moonCurve == other.moonCurve &&
          optimalWindows == other.optimalWindows;

  @override
  int get hashCode =>
      objectCurve.hashCode ^ moonCurve.hashCode ^ optimalWindows.hashCode;

  @override
  String toString() {
    return 'VisibilityGraphData(objectPoints: ${objectCurve.length}, moonPoints: ${moonCurve.length}, optimalWindows: ${optimalWindows.length})';
  }
}
