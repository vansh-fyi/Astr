import 'package:equatable/equatable.dart';

/// Domain entity representing a user-created observing location.
///
/// This entity is stored in the user locations SQLite database and supports:
/// - Persistence via [toMap]/[fromMap] for sqflite serialization
/// - Immutability via [copyWith] pattern
/// - Staleness tracking via [lastViewedTimestamp]
/// - Priority control via [isPinned]
///
/// H3 Index is stored at Resolution 8 for consistent zone data lookups.
///
/// **Coordinate Validation:**
/// Latitude must be in range [-90, 90] and longitude in range [-180, 180].
/// Invalid coordinates throw [ArgumentError].
class UserLocation extends Equatable {
  /// Creates a new UserLocation instance.
  ///
  /// All fields are required:
  /// - [id]: Unique identifier (typically UUID)
  /// - [name]: User-provided display name
  /// - [latitude]/[longitude]: GPS coordinates (validated)
  /// - [h3Index]: H3 index at Resolution 8 for zone lookups
  /// - [lastViewedTimestamp]: When user last viewed this location's dashboard
  /// - [isPinned]: Whether location is protected from staleness cleanup
  /// - [createdAt]: When the location was originally created
  ///
  /// Throws [ArgumentError] if latitude or longitude are out of valid range.
  const UserLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.h3Index,
    required this.lastViewedTimestamp,
    required this.isPinned,
    required this.createdAt,
  }) : assert(latitude >= -90 && latitude <= 90, 'Latitude must be between -90 and 90'),
       assert(longitude >= -180 && longitude <= 180, 'Longitude must be between -180 and 180');

  /// Creates a UserLocation from a sqflite database map.
  ///
  /// Handles SQLite-specific type conversions:
  /// - DateTime stored as milliseconds since epoch (INTEGER)
  /// - bool stored as 0/1 (INTEGER)
  /// - coordinates may come as int or double
  factory UserLocation.fromMap(Map<String, dynamic> map) {
    return UserLocation(
      id: map['id'] as String,
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      h3Index: map['h3Index'] as String,
      lastViewedTimestamp: DateTime.fromMillisecondsSinceEpoch(
        map['lastViewedTimestamp'] as int,
      ),
      isPinned: (map['isPinned'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int,
      ),
    );
  }

  /// Unique identifier for this location.
  final String id;

  /// User-provided display name.
  final String name;

  /// GPS latitude in decimal degrees.
  final double latitude;

  /// GPS longitude in decimal degrees.
  final double longitude;

  /// H3 index at Resolution 8 for light pollution zone lookups.
  final String h3Index;

  /// Timestamp of when user last viewed this location's dashboard.
  ///
  /// Used for staleness detection (see Story 2.3).
  /// A location is considered "stale" if:
  /// `(now - lastViewedTimestamp) > 10 days AND isPinned == false`
  final DateTime lastViewedTimestamp;

  /// Whether this location is protected from staleness cleanup.
  ///
  /// Pinned locations are always included in background weather updates,
  /// regardless of [lastViewedTimestamp].
  final bool isPinned;

  /// Timestamp of when this location was originally created.
  final DateTime createdAt;

  /// Creates a copy of this location with optional field updates.
  ///
  /// All fields default to their current values if not specified.
  UserLocation copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? h3Index,
    DateTime? lastViewedTimestamp,
    bool? isPinned,
    DateTime? createdAt,
  }) {
    return UserLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      h3Index: h3Index ?? this.h3Index,
      lastViewedTimestamp: lastViewedTimestamp ?? this.lastViewedTimestamp,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts this location to a map for sqflite storage.
  ///
  /// Type conversions for SQLite:
  /// - DateTime → milliseconds since epoch (INTEGER)
  /// - bool → 0/1 (INTEGER)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'h3Index': h3Index,
      'lastViewedTimestamp': lastViewedTimestamp.millisecondsSinceEpoch,
      'isPinned': isPinned ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        latitude,
        longitude,
        h3Index,
        lastViewedTimestamp,
        isPinned,
        createdAt,
      ];

  @override
  String toString() {
    return 'UserLocation(id: $id, name: $name, lat: $latitude, lng: $longitude, '
        'h3: $h3Index, pinned: $isPinned)';
  }
}
