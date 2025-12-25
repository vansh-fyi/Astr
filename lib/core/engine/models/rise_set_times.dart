/// Represents the rise, transit, and set times for a celestial object
class RiseSetTimes {

  const RiseSetTimes({
    this.riseTime,
    this.transitTime,
    this.setTime,
    this.isCircumpolar = false,
    this.neverRises = false,
  }) : assert(
         !(isCircumpolar && neverRises),
         'Object cannot be both circumpolar and never rising',
       );
  /// The time when the object rises above the horizon (null if circumpolar or never rises)
  final DateTime? riseTime;

  /// The time when the object reaches its highest point (transit/culmination)
  final DateTime? transitTime;

  /// The time when the object sets below the horizon (null if circumpolar or never sets)
  final DateTime? setTime;

  /// True if the object is circumpolar (always above horizon)
  final bool isCircumpolar;

  /// True if the object never rises above the horizon
  final bool neverRises;

  @override
  String toString() {
    if (isCircumpolar) {
      return 'RiseSetTimes(circumpolar, transit: $transitTime)';
    }
    if (neverRises) {
      return 'RiseSetTimes(never rises)';
    }
    return 'RiseSetTimes(rise: $riseTime, transit: $transitTime, set: $setTime)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiseSetTimes &&
          runtimeType == other.runtimeType &&
          riseTime == other.riseTime &&
          transitTime == other.transitTime &&
          setTime == other.setTime &&
          isCircumpolar == other.isCircumpolar &&
          neverRises == other.neverRises;

  @override
  int get hashCode => Object.hash(riseTime, transitTime, setTime, isCircumpolar, neverRises);
}
