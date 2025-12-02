import 'package:astr/features/catalog/domain/entities/celestial_type.dart';

/// Entity representing a celestial object in the catalog
class CelestialObject {
  final String id;
  final String name;
  final CelestialType type;
  final String iconPath;
  final double? magnitude; // Visual magnitude (null for constellations)
  final int? ephemerisId; // swisseph ID for planets/stars (null for constellations)
  final double? ra; // Right Ascension in degrees (for Deep Sky Objects)
  final double? dec; // Declination in degrees (for Deep Sky Objects)

  const CelestialObject({
    required this.id,
    required this.name,
    required this.type,
    required this.iconPath,
    this.magnitude,
    this.ephemerisId,
    this.ra,
    this.dec,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CelestialObject &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
