/// Represents a geographic location with latitude, longitude, and elevation
class Location {

  const Location({
    required this.latitude,
    required this.longitude,
    this.elevation = 0.0,
  }) : assert(latitude >= -90 && latitude <= 90, 'Latitude must be between -90 and 90'),
       assert(longitude >= -180 && longitude <= 180, 'Longitude must be between -180 and 180');
  /// Latitude in degrees (-90 to +90, North is positive)
  final double latitude;

  /// Longitude in degrees (-180 to +180, East is positive)
  final double longitude;

  /// Elevation in meters above sea level
  final double elevation;

  @override
  String toString() => 'Location(lat: $latitude, lon: $longitude, elev: $elevation)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Location &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          elevation == other.elevation;

  @override
  int get hashCode => Object.hash(latitude, longitude, elevation);
}
