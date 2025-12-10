import 'package:astr/core/engine/models/celestial_object.dart';
import 'package:astr/core/engine/models/coordinates.dart';

/// Type of Deep Sky Object
enum DSOType {
  galaxy('Galaxy'),
  nebula('Nebula'),
  cluster('Cluster'),
  unknown('Unknown');

  final String displayName;
  const DSOType(this.displayName);

  /// Parse from string (case-insensitive)
  static DSOType fromString(String? value) {
    if (value == null || value.isEmpty) return unknown;
    final normalized = value.toLowerCase();

    for (final type in DSOType.values) {
      if (type.displayName.toLowerCase() == normalized) {
        return type;
      }
    }
    return unknown;
  }
}

/// Represents a Deep Sky Object (Messier, NGC, IC catalogs)
class DSO extends CelestialObject {
  /// Messier ID (e.g., "M31")
  final String? messierId;

  /// NGC/IC ID (e.g., "NGC224")
  final String? ngcId;

  /// Type of DSO
  final DSOType dsoType;

  const DSO({
    required super.id,
    required super.name,
    this.messierId,
    this.ngcId,
    required this.dsoType,
    required super.coordinates,
    super.magnitude,
    super.constellation,
  }) : super(type: CelestialObjectType.dso);

  /// Creates a DSO from SQLite row data
  factory DSO.fromMap(Map<String, dynamic> map) {
    return DSO(
      id: map['id'].toString(),
      messierId: map['messier_id'] as String?,
      ngcId: map['ngc_id'] as String?,
      name: map['name'] as String? ?? (map['messier_id'] ?? map['ngc_id'] ?? 'Unknown'),
      dsoType: DSOType.fromString(map['type'] as String?),
      coordinates: EquatorialCoordinates(
        rightAscension: (map['ra'] as num).toDouble(),
        declination: (map['dec'] as num).toDouble(),
      ),
      magnitude: map['mag'] != null ? (map['mag'] as num).toDouble() : null,
      constellation: map['constellation'] as String?,
    );
  }

  /// Converts DSO to a map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      'id': int.parse(id),
      'messier_id': messierId,
      'ngc_id': ngcId,
      'type': dsoType.displayName,
      'ra': coordinates.rightAscension,
      'dec': coordinates.declination,
      'mag': magnitude,
      'name': name,
      'constellation': constellation,
    };
  }

  @override
  String toString() =>
      'DSO(id: $messierId/$ngcId, name: $name, type: ${dsoType.displayName}, mag: $magnitude)';
}
