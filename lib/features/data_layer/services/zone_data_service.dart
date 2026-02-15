import 'dart:typed_data';

import '../models/zone_data.dart';
import 'binary_reader_service.dart';

/// Service for retrieving light pollution zone data by H3 index.
///
/// This service orchestrates data retrieval from `zones.db` using:
/// - Binary search to locate H3 index in sorted array
/// - [BinaryReaderService] for efficient file I/O
/// - [ZoneData.fromBytes] for binary parsing
///
/// **Architecture:**
/// - Part of "Data Service Layer" pattern
/// - Delegates all `dart:io` operations to [BinaryReaderService]
/// - Stateless service with dependency injection
///
/// **Binary Format (zones.db):**
/// ```
/// [Header: 16 bytes]
///   - Magic: "ASTR" (4 bytes)
///   - Version: 1 (4 bytes, uint32)
///   - Record Count: N (8 bytes, uint64)
///
/// [Records: N × 20 bytes, sorted by h3_index]
///   Each record:
///   - h3_index: 8 bytes (uint64)
///   - bortle: 1 byte (uint8)
///   - ratio: 4 bytes (float32)
///   - sqm: 4 bytes (float32)
///   - reserved: 3 bytes (padding)
/// ```
///
/// **Performance:**
/// - Meet NFR-01: < 100ms lookup time
/// - O(log n) binary search (~22 iterations for 4M records)
/// - No full file loading (sovereign binary access)
class ZoneDataService {
  /// Creates a ZoneDataService with the given [BinaryReaderService].
  ///
  /// The binary reader must be initialized before use.
  ZoneDataService({required BinaryReaderService binaryReader})
      : _binaryReader = binaryReader;

  final BinaryReaderService _binaryReader;

  /// Size of the file header in bytes.
  static const int headerSize = 16;

  /// Size in bytes of each zone data record (including h3_index).
  static const int recordSizeBytes = 20;

  /// Size in bytes of just the zone data portion (without h3_index).
  static const int zoneSizeBytes = 12;

  /// Retrieves zone data for the given H3 index.
  ///
  /// **Lookup Strategy:**
  /// Uses binary search on the sorted array of records in zones.db.
  /// 1. Read header to get record count
  /// 2. Binary search: read middle record's h3_index, compare, repeat
  /// 3. If found: extract zone data bytes (skip h3_index)
  ///
  /// Parameters:
  /// - [h3Index]: The H3 spatial index (Resolution 8). Must be non-negative.
  ///
  /// Returns: [ZoneData] containing Bortle class, ratio, and SQM values.
  ///
  /// Throws:
  /// - [ArgumentError] if [h3Index] is negative
  /// - [RangeError] if [h3Index] not found in zones.db
  /// - [FormatException] if the binary data fails validation or header is invalid
  Future<ZoneData> getZoneData(BigInt h3Index) async {
    _validateH3Index(h3Index);

    // Read header to get record count
    final header = await _binaryReader.readBytes(offset: 0, length: headerSize);
    _validateHeader(header);
    final recordCount = _parseRecordCount(header);

    // Binary search for h3_index
    int left = 0;
    int right = recordCount - 1;

    while (left <= right) {
      final mid = (left + right) ~/ 2;
      final recordOffset = headerSize + (mid * recordSizeBytes);

      // Read the h3_index at this position (first 8 bytes of record)
      final indexBytes = await _binaryReader.readBytes(
        offset: recordOffset,
        length: 8,
      );
      final midH3Index = indexBytes.buffer.asByteData().getUint64(0, Endian.little);
      final midH3BigInt = BigInt.from(midH3Index);

      if (midH3BigInt == h3Index) {
        // Found! Read the zone data (skip h3_index, read next 12 bytes)
        final zoneBytes = await _binaryReader.readBytes(
          offset: recordOffset + 8,
          length: zoneSizeBytes,
        );
        return ZoneData.fromBytes(zoneBytes);
      } else if (midH3BigInt < h3Index) {
        left = mid + 1;
      } else {
        right = mid - 1;
      }
    }

    // Not found
    throw RangeError(
      'H3 index $h3Index not found in zones.db. '
      'This location may not have light pollution data available.',
    );
  }

  /// Retrieves zone data synchronously for performance-critical paths.
  ///
  /// Use this method when async overhead is unacceptable.
  /// **Warning:** May block the main isolate - use judiciously.
  ///
  /// Parameters:
  /// - [h3Index]: The H3 spatial index (Resolution 8). Must be non-negative.
  ///
  /// Returns: [ZoneData] containing Bortle class, ratio, and SQM values.
  ///
  /// Throws:
  /// - [ArgumentError] if [h3Index] is negative
  /// - [RangeError] if [h3Index] not found in zones.db
  /// - [FormatException] if the binary data fails validation or header is invalid
  ZoneData getZoneDataSync(BigInt h3Index) {
    _validateH3Index(h3Index);

    // Read header to get record count
    final header = _binaryReader.readBytesSync(offset: 0, length: headerSize);
    _validateHeader(header);
    final recordCount = _parseRecordCount(header);

    // Binary search for h3_index
    int left = 0;
    int right = recordCount - 1;

    while (left <= right) {
      final mid = (left + right) ~/ 2;
      final recordOffset = headerSize + (mid * recordSizeBytes);

      // Read the h3_index at this position (first 8 bytes of record)
      final indexBytes = _binaryReader.readBytesSync(
        offset: recordOffset,
        length: 8,
      );
      final midH3Index = indexBytes.buffer.asByteData().getUint64(0, Endian.little);
      final midH3BigInt = BigInt.from(midH3Index);

      if (midH3BigInt == h3Index) {
        // Found! Read the zone data (skip h3_index, read next 12 bytes)
        final zoneBytes = _binaryReader.readBytesSync(
          offset: recordOffset + 8,
          length: zoneSizeBytes,
        );
        return ZoneData.fromBytes(zoneBytes);
      } else if (midH3BigInt < h3Index) {
        left = mid + 1;
      } else {
        right = mid - 1;
      }
    }

    // Not found
    throw RangeError(
      'H3 index $h3Index not found in zones.db. '
      'This location may not have light pollution data available.',
    );
  }

  /// Validates the zones.db header magic and version.
  void _validateHeader(Uint8List header) {
    if (header.length < headerSize) {
      throw FormatException(
        'Invalid zones.db header: expected $headerSize bytes, got ${header.length}',
      );
    }

    // Check magic "ASTR"
    final magic = String.fromCharCodes(header.sublist(0, 4));
    if (magic != 'ASTR') {
      throw FormatException(
        'Invalid zones.db magic: expected "ASTR", got "$magic"',
      );
    }

    // Check version (currently only version 1 supported)
    final version = header.buffer.asByteData().getUint32(4, Endian.little);
    if (version != 1) {
      throw FormatException(
        'Unsupported zones.db version: expected 1, got $version',
      );
    }
  }

  /// Parses the record count from the header.
  int _parseRecordCount(Uint8List header) {
    return header.buffer.asByteData().getUint64(8, Endian.little);
  }

  /// Validates that the H3 index is non-negative.
  void _validateH3Index(BigInt h3Index) {
    if (h3Index < BigInt.zero) {
      throw ArgumentError(
        'H3 index must be non-negative, but got $h3Index',
      );
    }
  }
}
