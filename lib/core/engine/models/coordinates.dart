/// Represents equatorial coordinates (RA/Dec)
class EquatorialCoordinates {

  const EquatorialCoordinates({
    required this.rightAscension,
    required this.declination,
  }) : assert(rightAscension >= 0 && rightAscension <= 360, 'RA must be between 0 and 360'),
       assert(declination >= -90 && declination <= 90, 'Dec must be between -90 and 90');

  /// Creates equatorial coordinates from hours:minutes:seconds format
  factory EquatorialCoordinates.fromHMS({
    required int hours,
    required int minutes,
    required double seconds,
    required double decDegrees,
    required double decMinutes,
    required double decSeconds,
    bool isNegative = false,
  }) {
    final double ra = (hours + minutes / 60.0 + seconds / 3600.0) * 15.0; // Convert hours to degrees
    final double dec = (decDegrees + decMinutes / 60.0 + decSeconds / 3600.0) * (isNegative ? -1 : 1);
    return EquatorialCoordinates(rightAscension: ra, declination: dec);
  }
  /// Right Ascension in degrees (0-360)
  final double rightAscension;

  /// Declination in degrees (-90 to +90)
  final double declination;

  @override
  String toString() => 'EquatorialCoordinates(RA: ${rightAscension.toStringAsFixed(4)}°, Dec: ${declination.toStringAsFixed(4)}°)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquatorialCoordinates &&
          runtimeType == other.runtimeType &&
          rightAscension == other.rightAscension &&
          declination == other.declination;

  @override
  int get hashCode => Object.hash(rightAscension, declination);
}

/// Represents horizontal coordinates (Alt/Az)
class HorizontalCoordinates {

  const HorizontalCoordinates({
    required this.altitude,
    required this.azimuth,
  }) : assert(altitude >= -90 && altitude <= 90, 'Altitude must be between -90 and 90'),
       assert(azimuth >= 0 && azimuth <= 360, 'Azimuth must be between 0 and 360');
  /// Altitude in degrees (-90 to +90, horizon is 0)
  final double altitude;

  /// Azimuth in degrees (0-360, North is 0, East is 90)
  final double azimuth;

  @override
  String toString() => 'HorizontalCoordinates(Alt: ${altitude.toStringAsFixed(4)}°, Az: ${azimuth.toStringAsFixed(4)}°)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HorizontalCoordinates &&
          runtimeType == other.runtimeType &&
          altitude == other.altitude &&
          azimuth == other.azimuth;

  @override
  int get hashCode => Object.hash(altitude, azimuth);
}
