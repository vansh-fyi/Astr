import 'package:astr/core/engine/models/coordinates.dart';

/// Type of celestial object
enum CelestialObjectType {
  star,
  planet,
  dso, // Deep Sky Object
  moon,
  sun,
}

/// Represents a celestial object with its equatorial coordinates
class CelestialObject {
  /// Unique identifier for the object
  final String id;

  /// Name of the object (e.g., "Sirius", "Mars", "M31")
  final String name;

  /// Type of celestial object
  final CelestialObjectType type;

  /// Equatorial coordinates (RA/Dec)
  final EquatorialCoordinates coordinates;

  /// Visual magnitude (brightness)
  final double? magnitude;

  /// Constellation name
  final String? constellation;

  const CelestialObject({
    required this.id,
    required this.name,
    required this.type,
    required this.coordinates,
    this.magnitude,
    this.constellation,
  });

  @override
  String toString() => 'CelestialObject(id: $id, name: $name, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CelestialObject &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          coordinates == other.coordinates &&
          magnitude == other.magnitude &&
          constellation == other.constellation;

  @override
  int get hashCode => Object.hash(id, name, type, coordinates, magnitude, constellation);
}
