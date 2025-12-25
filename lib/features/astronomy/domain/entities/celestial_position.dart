import 'celestial_body.dart';

class CelestialPosition { // Apparent magnitude

  const CelestialPosition({
    this.body,
    required this.name,
    required this.time,
    required this.altitude,
    required this.azimuth,
    required this.distance,
    required this.magnitude,
  });
  final CelestialBody? body;
  final String name;
  final DateTime time;
  final double altitude; // Degrees
  final double azimuth; // Degrees
  final double distance; // AU (Astronomical Units)
  final double magnitude;

  @override
  String toString() {
    return 'CelestialPosition(name: $name, alt: ${altitude.toStringAsFixed(2)}°, az: ${azimuth.toStringAsFixed(2)}°, mag: ${magnitude.toStringAsFixed(2)})';
  }
}
