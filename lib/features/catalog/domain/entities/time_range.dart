/// Entity representing a time range (e.g., for optimal viewing windows)
class TimeRange {
  final DateTime start;
  final DateTime end;

  const TimeRange({
    required this.start,
    required this.end,
  });

  /// Duration of this time range
  Duration get duration => end.difference(start);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;

  @override
  String toString() {
    return 'TimeRange(start: $start, end: $end)';
  }
}
