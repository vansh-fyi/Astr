/// Represents the 6 distinct visual sky states used for background selection and hero display.
enum SkyState {
  /// Milky Way visible (Excellent conditions)
  milkyWayVisible,

  /// Clear starry sky (Good conditions)
  starrySkies,

  /// Planets visible (Fair conditions)
  planetsVisible,

  /// Few stars visible (Poor conditions)
  fewStars,

  /// Heavy cloud cover (Cloudy conditions)
  cloudy,

  /// Excessive light pollution (Bright conditions)
  tooMuchLight,
}
