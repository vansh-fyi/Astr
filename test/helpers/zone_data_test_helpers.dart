import 'dart:typed_data';

/// Helper to create test bytes for ZoneData with specified values.
///
/// Creates a 12-byte binary buffer following the zones.db schema:
/// - Byte[0]: Bortle class (uint8)
/// - Bytes[1-4]: Ratio (float32, little-endian)
/// - Bytes[5-8]: SQM (float32, little-endian)
/// - Bytes[9-11]: Padding (0x00)
Uint8List createTestZoneBytes({
  required int bortleClass,
  required double ratio,
  required double sqm,
}) {
  final bytes = Uint8List(12);
  final buffer = bytes.buffer.asByteData();

  bytes[0] = bortleClass;
  buffer.setFloat32(1, ratio, Endian.little);
  buffer.setFloat32(5, sqm, Endian.little);
  // Bytes 9-11 are padding (default 0)

  return bytes;
}
