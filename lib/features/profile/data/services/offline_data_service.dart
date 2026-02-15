import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Service for managing offline zones.db download from Cloudflare R2.
///
/// Handles downloading, deleting, and checking status of the local
/// zones.db file for fully offline light pollution lookups.
class OfflineDataService {
  OfflineDataService({
    required String baseUrl,
    Dio? dio,
  })  : _baseUrl = baseUrl,
        _dio = dio ?? Dio();

  final String _baseUrl;
  final Dio _dio;

  static const String _fileName = 'zones.db';

  /// Returns the path where zones.db is stored locally.
  Future<String> get _localPath async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$_fileName';
  }

  /// Whether zones.db has been downloaded locally.
  Future<bool> get isDownloaded async {
    final String path = await _localPath;
    return File(path).existsSync();
  }

  /// Returns the file size in bytes, or null if not downloaded.
  Future<int?> getFileSize() async {
    final String path = await _localPath;
    final File file = File(path);
    if (await file.exists()) {
      return file.lengthSync();
    }
    return null;
  }

  /// Returns the local file path if downloaded, null otherwise.
  Future<String?> getLocalDbPath() async {
    final String path = await _localPath;
    if (File(path).existsSync()) {
      return path;
    }
    return null;
  }

  /// Downloads zones.db from the Cloudflare Worker /download endpoint.
  ///
  /// [onProgress] callback receives values from 0.0 to 1.0.
  /// [cancelToken] can be used to cancel the download.
  ///
  /// Returns the local file path on success.
  /// Throws on network errors or cancellation.
  Future<String> download({
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    final String path = await _localPath;
    final String tempPath = '$path.tmp';

    try {
      await _dio.download(
        '$_baseUrl/download',
        tempPath,
        cancelToken: cancelToken,
        onReceiveProgress: (int received, int total) {
          if (total > 0) {
            onProgress(received / total);
          }
        },
      );

      // Rename temp file to final path (atomic on most filesystems)
      final File tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.rename(path);
      }

      debugPrint('OfflineDataService: Downloaded zones.db to $path');
      return path;
    } catch (e) {
      // Clean up temp file on failure
      final File tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }

  /// Deletes the local zones.db file.
  ///
  /// Returns true if the file was deleted, false if it didn't exist.
  Future<bool> delete() async {
    final String path = await _localPath;
    final File file = File(path);
    if (await file.exists()) {
      await file.delete();
      debugPrint('OfflineDataService: Deleted zones.db');
      return true;
    }
    return false;
  }

  /// Disposes the Dio client.
  void dispose() {
    _dio.close();
  }
}
