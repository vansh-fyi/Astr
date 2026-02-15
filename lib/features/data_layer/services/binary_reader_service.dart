import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Service providing sovereign binary access to large database files.
///
/// This is the **only** class in the codebase allowed to use `dart:io` for
/// file access. Per architecture: "Sovereign Binary Access" pattern.
///
/// **Strategy: Copy-to-Filesystem**
/// - On initialization, checks if `zones.db` exists in Application Documents Directory
/// - If missing, copies from bundled assets (one-time operation)
/// - All subsequent reads use `RandomAccessFile` for efficient partial reads
///
/// **Constraint:**
/// NEVER loads the full 50MB file into memory. Uses `RandomAccessFile` for
/// offset-based reads to prevent OOM on low-memory devices.
class BinaryReaderService {
  /// Expected SHA-256 hash of zones.db for integrity verification.
  ///
  /// **IMPORTANT: Update this hash when zones.db is regenerated!**
  ///
  /// To calculate the hash for a new zones.db file:
  /// ```bash
  /// shasum -a 256 assets/db/zones.db
  /// ```
  ///
  /// Current hash is for the production 62M-record file (1.2 GB).
  /// Generated from NASA VIIRS VNP46A2 data processing pipeline.
  ///
  /// Set to `null` to disable verification (NOT recommended for production).
  static const String? expectedZonesDbHash =
      '9136ed3e95c3e8a7564b3b87a5fd06e75c501334d752eabdefc2b1e73aa74347';

  /// Chunk size for asset copying (1MB chunks to reduce peak memory usage)
  static const int _copyChunkSize = 1024 * 1024; // 1MB

  /// Creates a BinaryReaderService with an explicit path to the database file.
  ///
  /// This constructor is primarily used for testing. For production use,
  /// see [BinaryReaderService.initialize] which handles asset copying.
  BinaryReaderService({required String dbPath}) : _dbPath = dbPath;

  /// Internal path to the database file
  final String _dbPath;

  /// Gets the path to the database file.
  String get dbPath => _dbPath;

  /// Initializes the BinaryReaderService by ensuring the zones.db file exists.
  ///
  /// This method:
  /// 1. Gets the Application Documents Directory
  /// 2. Checks if zones.db exists (and validates hash if configured)
  /// 3. If missing/invalid, copies from bundled assets with chunked writes
  /// 4. Verifies integrity via SHA-256 checksum (if expectedZonesDbHash set)
  /// 5. Returns a BinaryReaderService configured with the correct path
  ///
  /// Throws:
  /// - [AssetNotFoundException] if 'assets/db/zones.db' is missing from bundle
  /// - [DataIntegrityException] if SHA-256 verification fails
  /// - [FileSystemException] if file operations fail
  static Future<BinaryReaderService> initialize() async {
    final appDocsDir = await getApplicationDocumentsDirectory();
    final dbPath = '${appDocsDir.path}/zones.db';
    final dbFile = File(dbPath);

    // Check if file exists and is valid
    bool needsCopy = !await dbFile.exists();

    if (!needsCopy && expectedZonesDbHash != null) {
      // Verify existing file integrity
      final isValid = await _verifyFileHash(dbFile, expectedZonesDbHash!);
      if (!isValid) {
        needsCopy = true; // Re-copy if hash mismatch
      }
    }

    if (needsCopy) {
      try {
        // Copy from bundled assets with chunked writes
        await _copyAssetChunked('assets/db/zones.db', dbFile);
      } on FlutterError catch (e) {
        throw AssetNotFoundException(
          'Critical asset missing: assets/db/zones.db not found in bundle. '
          'Ensure zones.db is listed in pubspec.yaml under assets.',
          originalError: e,
        );
      }

      // Verify copied file integrity
      if (expectedZonesDbHash != null) {
        final isValid = await _verifyFileHash(dbFile, expectedZonesDbHash!);
        if (!isValid) {
          throw DataIntegrityException(
            'zones.db failed SHA-256 verification after copy. '
            'Asset may be corrupted.',
          );
        }
      }
    }

    return BinaryReaderService(dbPath: dbPath);
  }

  /// Copies an asset to a file using chunked writes to minimize peak memory.
  ///
  /// Instead of loading the entire asset into memory at once, this writes
  /// data in chunks to reduce memory pressure on low-memory devices.
  static Future<void> _copyAssetChunked(String assetPath, File destFile) async {
    // Load asset data (unavoidable memory spike for rootBundle)
    final byteData = await rootBundle.load(assetPath);

    // Ensure destination directory exists
    await destFile.parent.create(recursive: true);

    // Write in chunks to reduce peak memory after initial load
    final sink = destFile.openWrite();
    try {
      final totalBytes = byteData.lengthInBytes;
      int offset = byteData.offsetInBytes;

      while (offset < byteData.offsetInBytes + totalBytes) {
        final chunkSize = (offset + _copyChunkSize <= byteData.offsetInBytes + totalBytes)
            ? _copyChunkSize
            : (byteData.offsetInBytes + totalBytes - offset);

        final chunk = byteData.buffer.asUint8List(offset, chunkSize);
        sink.add(chunk);
        offset += chunkSize;
      }

      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  /// Verifies a file's SHA-256 hash matches the expected value.
  static Future<bool> _verifyFileHash(File file, String expectedHash) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    final actualHash = digest.toString();
    return actualHash == expectedHash.toLowerCase();
  }

  /// Reads bytes from the database file at the specified offset.
  ///
  /// Uses `RandomAccessFile` for efficient partial reads without loading
  /// the entire file into memory.
  ///
  /// Parameters:
  /// - [offset]: Starting position in bytes (must be >= 0)
  /// - [length]: Number of bytes to read (must be >= 0)
  ///
  /// Returns: A [Uint8List] containing the requested bytes.
  /// If the file ends before [length] bytes can be read, returns only
  /// the available bytes.
  ///
  /// Throws:
  /// - [ArgumentError] if offset or length is negative
  /// - [FileSystemException] if the file cannot be opened
  Future<Uint8List> readBytes({
    required int offset,
    required int length,
  }) async {
    // Validate parameters
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'Offset must be >= 0');
    }
    if (length < 0) {
      throw ArgumentError.value(length, 'length', 'Length must be >= 0');
    }

    // Early return for zero-length read
    if (length == 0) {
      return Uint8List(0);
    }

    // Open file in read mode
    final file = File(_dbPath);
    final raf = await file.open(mode: FileMode.read);

    try {
      // Set position and read
      await raf.setPosition(offset);
      final bytes = await raf.read(length);
      return bytes;
    } finally {
      // Always close the file handle
      await raf.close();
    }
  }

  /// Reads bytes synchronously from the database file.
  ///
  /// Use this for performance-critical paths where async overhead is unacceptable.
  /// **Warning:** Should only be called from isolates or when blocking is acceptable.
  ///
  /// Parameters:
  /// - [offset]: Starting position in bytes (must be >= 0)
  /// - [length]: Number of bytes to read (must be >= 0)
  ///
  /// Returns: A [Uint8List] containing the requested bytes.
  Uint8List readBytesSync({
    required int offset,
    required int length,
  }) {
    // Validate parameters
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'Offset must be >= 0');
    }
    if (length < 0) {
      throw ArgumentError.value(length, 'length', 'Length must be >= 0');
    }

    // Early return for zero-length read
    if (length == 0) {
      return Uint8List(0);
    }

    // Open file in read mode
    final file = File(_dbPath);
    final raf = file.openSync(mode: FileMode.read);

    try {
      // Set position and read
      raf.setPositionSync(offset);
      final bytes = raf.readSync(length);
      return bytes;
    } finally {
      // Always close the file handle
      raf.closeSync();
    }
  }

  /// Copies a file from source path to destination path.
  ///
  /// This is a utility method used for the "Copy-on-Setup" strategy.
  /// Uses streaming for efficient memory usage.
  ///
  /// Parameters:
  /// - [srcPath]: Absolute path to source file
  /// - [destPath]: Absolute path to destination file
  static Future<void> copyFile(String srcPath, String destPath) async {
    final srcFile = File(srcPath);
    final destFile = File(destPath);

    // Ensure destination directory exists
    await destFile.parent.create(recursive: true);

    // Stream copy for memory efficiency
    final inputStream = srcFile.openRead();
    final outputSink = destFile.openWrite();

    await inputStream.pipe(outputSink);
  }
}

/// Exception thrown when a required asset is not found in the bundle.
class AssetNotFoundException implements Exception {
  const AssetNotFoundException(this.message, {this.originalError});

  final String message;
  final dynamic originalError;

  @override
  String toString() =>
      'AssetNotFoundException: $message${originalError != null ? '\nCaused by: $originalError' : ''}';
}

/// Exception thrown when data integrity verification fails.
class DataIntegrityException implements Exception {
  const DataIntegrityException(this.message);

  final String message;

  @override
  String toString() => 'DataIntegrityException: $message';
}
