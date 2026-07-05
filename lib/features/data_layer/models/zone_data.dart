import 'package:flutter/foundation.dart';

/// Represents light pollution data for a specific H3 zone.
///
/// Contains scientific-grade data used by the UI to display sky quality:
/// - [astrZone]: Astr Zone value (1-9)
/// - [ratio]: Light pollution ratio (relative to natural sky)
/// - [sqm]: Sky Quality Meter value in mag/arcsec²
///
/// **Binary Format (12 bytes total):**
/// ```
/// Byte[0]    : Astr Zone (uint8, values 1-9)
/// Bytes[1-4] : Light Pollution Ratio (float32, little-endian)
/// Bytes[5-8] : SQM value (float32, little-endian)
/// Bytes[9-11]: Reserved/padding
/// ```
///
/// This class is immutable and follows value semantics.
@immutable
class ZoneData {
  /// Creates a ZoneData instance with the given values.
  ///
  /// **Validation:**
  /// - [astrZone] must be between 1 and 9
  /// - [ratio] must be non-negative
  const ZoneData({
    required this.astrZone,
    required this.ratio,
    required this.sqm,
  });

  /// Parses a 12-byte binary buffer into a [ZoneData] instance.
  ///
  /// **Binary Layout:**
  /// - Byte 0: Astr Zone (uint8)
  /// - Bytes 1-4: Ratio (float32, little-endian)
  /// - Bytes 5-8: SQM (float32, little-endian)
  /// - Bytes 9-11: Padding (ignored)
  ///
  /// Throws:
  /// - [ArgumentError] if [bytes] has fewer than 12 elements
  /// - [FormatException] if parsed values fail validation
  factory ZoneData.fromBytes(Uint8List bytes) {
    if (bytes.length < 12) {
      throw ArgumentError(
        'Expected 12 bytes for ZoneData, but received ${bytes.length} bytes',
      );
    }

    // Use ByteData for endianness-safe parsing
    final ByteData buffer = bytes.buffer.asByteData(bytes.offsetInBytes);

    final int bortleClass = bytes[0];
    final double ratio = buffer.getFloat32(1, Endian.little);
    final double sqm = buffer.getFloat32(5, Endian.little);

    // Validate Astr Zone
    if (bortleClass < 1 || bortleClass > 9) {
      throw FormatException(
        'Astr Zone must be between 1 and 9, but got $bortleClass',
      );
    }

    // Validate ratio
    if (ratio < 0) {
      throw FormatException(
        'Ratio must be non-negative, but got $ratio',
      );
    }

    return ZoneData(
      astrZone: bortleClass,
      ratio: ratio,
      sqm: sqm,
    );
  }

  /// Astr Zone value (1-9).
  ///
  /// - 1: Excellent dark-sky site
  /// - 2: Typical truly dark site
  /// - 3: Rural sky
  /// - 4: Rural/suburban transition
  /// - 5: Suburban sky
  /// - 6: Bright suburban sky
  /// - 7: Suburban/urban transition
  /// - 8: City sky
  /// - 9: Inner-city sky
  final int astrZone;

  /// Light pollution ratio relative to natural sky brightness.
  ///
  /// Values typically range from ~0.1 (pristine) to >10 (heavy pollution).
  /// A value of 1.0 means equal to natural sky background.
  final double ratio;

  /// Sky Quality Meter reading in magnitudes per square arcsecond (mag/arcsec²).
  ///
  /// Typical range is 15.0 (bright city) to 22.0+ (pristine dark site).
  /// Higher values indicate darker skies.
  final double sqm;

  /// Creates a copy of this ZoneData with optional field overrides.
  ZoneData copyWith({
    int? astrZone,
    double? ratio,
    double? sqm,
  }) {
    return ZoneData(
      astrZone: astrZone ?? this.astrZone,
      ratio: ratio ?? this.ratio,
      sqm: sqm ?? this.sqm,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ZoneData &&
        other.astrZone == astrZone &&
        other.ratio == ratio &&
        other.sqm == sqm;
  }

  @override
  int get hashCode => Object.hash(astrZone, ratio, sqm);

  @override
  String toString() {
    return 'ZoneData(astrZone: $astrZone, ratio: $ratio, sqm: $sqm)';
  }
}
