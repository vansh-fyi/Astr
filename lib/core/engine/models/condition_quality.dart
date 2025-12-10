/// Represents the qualitative quality of observing conditions
enum ConditionQuality {
  /// Excellent conditions - ideal for all deep sky objects including faint galaxies
  excellent,

  /// Good conditions - suitable for most observations
  good,

  /// Fair conditions - planets and bright objects visible
  fair,

  /// Poor conditions - limited observing opportunities
  poor,

  /// Unknown - insufficient data to determine quality
  unknown,
}
