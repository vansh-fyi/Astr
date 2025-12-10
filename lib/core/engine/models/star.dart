import 'package:astr/core/engine/models/celestial_object.dart';
import 'package:astr/core/engine/models/coordinates.dart';

/// Represents a Star with Hipparcos catalog data
class Star extends CelestialObject {
  /// Hipparcos catalog ID
  final int hipId;

  /// Bayer designation (e.g., "Alpha CMa" for Sirius)
  final String? bayer;

  const Star({
    required super.id,
    required super.name,
    required this.hipId,
    required super.coordinates,
    super.magnitude,
    super.constellation,
    this.bayer,
  }) : super(type: CelestialObjectType.star);

  /// Creates a Star from SQLite row data
  factory Star.fromMap(Map<String, dynamic> map) {
    return Star(
      id: map['id'].toString(),
      hipId: map['hip_id'] as int,
      name: map['name'] as String? ?? '',
      coordinates: EquatorialCoordinates(
        rightAscension: (map['ra'] as num).toDouble(),
        declination: (map['dec'] as num).toDouble(),
      ),
      magnitude: map['mag'] != null ? (map['mag'] as num).toDouble() : null,
      constellation: map['constellation'] as String?,
      bayer: map['bayer'] as String?,
    );
  }

  /// Converts Star to a map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      'id': int.parse(id),
      'hip_id': hipId,
      'ra': coordinates.rightAscension,
      'dec': coordinates.declination,
      'mag': magnitude,
      'name': name,
      'bayer': bayer,
      'constellation': constellation,
    };
  }

  @override
  String toString() =>
      'Star(hipId: $hipId, name: $name, mag: $magnitude, constellation: $constellation)';
}
