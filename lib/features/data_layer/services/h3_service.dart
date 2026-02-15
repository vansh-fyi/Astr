import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:h3_flutter/h3_flutter.dart';

/// Service providing H3 spatial operations.
///
/// This is the **only** class in the codebase allowed to interact with `h3_flutter`.
/// Per architecture: "Native Bridge" pattern - H3Service encapsulates all FFI operations.
///
/// **Compatibility:**
/// - Flutter SDK: 3.x (verified with Dart SDK >=3.0.5)
/// - h3_flutter: ^0.7.1
/// - Platforms: Android, iOS (FFI native library bundled)
/// - Desktop: Service instantiates but FFI operations not supported
class H3Service {
  H3Service._internal(this._h3);

  /// The underlying H3 instance from h3_flutter
  final H3 _h3;

  /// Factory constructor that loads the H3 FFI library.
  ///
  /// Note: h3_flutter's load() is synchronous. The FFI library must be bundled
  /// for the target platform (Android/iOS). Desktop platforms are not supported.
  ///
  /// Throws [StateError] if the FFI library fails to load.
  /// Throws [UnsupportedError] if called on an unsupported platform.
  factory H3Service() {
    try {
      final h3 = const H3Factory().load();
      return H3Service._internal(h3);
    } catch (e) {
      throw StateError(
        'H3 FFI library failed to initialize. '
        'Ensure h3_flutter native libraries are bundled for this platform (Android/iOS only). '
        'Original error: $e',
      );
    }
  }

  /// Converts a latitude/longitude coordinate to an H3 index at the specified resolution.
  ///
  /// Parameters:
  /// - [lat]: Latitude in degrees (valid range: -90.0 to 90.0)
  /// - [lon]: Longitude in degrees (valid range: -180.0 to 180.0)
  /// - [resolution]: H3 resolution (valid range: 0-15), where 0 is the coarsest and 15 is the finest
  ///
  /// Returns: The H3 index as a [BigInt]
  ///
  /// Throws [ArgumentError] if any parameter is out of valid range.
  ///
  /// Example:
  /// ```dart
  /// final index = h3Service.latLonToH3(37.7749, -122.4194, 8);
  /// // Returns: BigInt representing H3 cell (e.g., 617700169958293503)
  /// ```
  BigInt latLonToH3(double lat, double lon, int resolution) {
    // Validate latitude
    if (lat < -90.0 || lat > 90.0) {
      throw ArgumentError.value(
        lat,
        'lat',
        'Latitude must be between -90.0 and 90.0 degrees',
      );
    }

    // Validate longitude
    if (lon < -180.0 || lon > 180.0) {
      throw ArgumentError.value(
        lon,
        'lon',
        'Longitude must be between -180.0 and 180.0 degrees',
      );
    }

    // Validate resolution
    if (resolution < 0 || resolution > 15) {
      throw ArgumentError.value(
        resolution,
        'resolution',
        'H3 resolution must be between 0 and 15',
      );
    }

    return _h3.geoToCell(GeoCoord(lat: lat, lon: lon), resolution);
  }

  /// Gets the underlying H3 instance for advanced operations.
  ///
  /// Use this for operations not exposed by convenience methods.
  H3 get h3 => _h3;
}

/// Riverpod provider for [H3Service].
///
/// Usage:
/// ```dart
/// final h3Service = ref.read(h3ServiceProvider);
/// final index = h3Service.latLonToH3(0, 0, 8);
/// ```
final Provider<H3Service> h3ServiceProvider = Provider<H3Service>(
  (ProviderRef<H3Service> ref) => H3Service(),
);
