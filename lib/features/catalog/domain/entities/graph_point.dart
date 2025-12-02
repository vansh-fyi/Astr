/// Entity representing a single data point on the visibility graph
class GraphPoint {
  final DateTime time;
  final double value; // Altitude in degrees (0-90) or Interference percentage (0-100)

  const GraphPoint({
    required this.time,
    required this.value,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphPoint &&
          runtimeType == other.runtimeType &&
          time == other.time &&
          value == other.value;

  @override
  int get hashCode => time.hashCode ^ value.hashCode;

  @override
  String toString() {
    return 'GraphPoint(time: $time, value: ${value.toStringAsFixed(2)})';
  }
}
