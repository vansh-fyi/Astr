import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../data/services/offline_data_service.dart';

// ============================================================================
// State
// ============================================================================

/// State for the offline data download feature.
@immutable
class OfflineDataState {
  const OfflineDataState({
    this.status = OfflineDataStatus.checking,
    this.progress = 0.0,
    this.fileSizeBytes,
    this.error,
    this.localDbPath,
  });

  final OfflineDataStatus status;

  /// Download progress from 0.0 to 1.0 (only relevant when downloading).
  final double progress;

  /// Size of downloaded file in bytes (only set when downloaded).
  final int? fileSizeBytes;

  /// Error message if download failed.
  final String? error;

  /// Path to local zones.db file (only set when downloaded).
  final String? localDbPath;

  OfflineDataState copyWith({
    OfflineDataStatus? status,
    double? progress,
    int? fileSizeBytes,
    String? error,
    String? localDbPath,
  }) {
    return OfflineDataState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      error: error,
      localDbPath: localDbPath ?? this.localDbPath,
    );
  }
}

enum OfflineDataStatus {
  checking,
  notDownloaded,
  downloading,
  downloaded,
  error,
}

// ============================================================================
// Notifier
// ============================================================================

class OfflineDataNotifier extends StateNotifier<OfflineDataState> {
  OfflineDataNotifier(this._service) : super(const OfflineDataState()) {
    _checkStatus();
  }

  final OfflineDataService _service;
  CancelToken? _cancelToken;

  static const String _settingsBox = 'settings';
  static const String _keyDownloaded = 'offline_data_downloaded';

  /// Check if zones.db is already downloaded.
  Future<void> _checkStatus() async {
    final bool downloaded = await _service.isDownloaded;
    if (downloaded) {
      final int? size = await _service.getFileSize();
      final String? path = await _service.getLocalDbPath();
      state = OfflineDataState(
        status: OfflineDataStatus.downloaded,
        fileSizeBytes: size,
        localDbPath: path,
      );
    } else {
      // Clean up stale flag if file was deleted externally
      final Box<dynamic> box = Hive.box(_settingsBox);
      await box.put(_keyDownloaded, false);
      state = const OfflineDataState(status: OfflineDataStatus.notDownloaded);
    }
  }

  /// Start downloading zones.db.
  Future<void> startDownload() async {
    if (state.status == OfflineDataStatus.downloading) return;

    _cancelToken = CancelToken();
    state = const OfflineDataState(
      status: OfflineDataStatus.downloading,
      progress: 0.0,
    );

    try {
      await _service.download(
        onProgress: (double progress) {
          if (mounted) {
            state = state.copyWith(progress: progress);
          }
        },
        cancelToken: _cancelToken,
      );

      // Mark as downloaded
      final int? size = await _service.getFileSize();
      final String? path = await _service.getLocalDbPath();
      final Box<dynamic> box = Hive.box(_settingsBox);
      await box.put(_keyDownloaded, true);

      if (mounted) {
        state = OfflineDataState(
          status: OfflineDataStatus.downloaded,
          fileSizeBytes: size,
          localDbPath: path,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        if (mounted) {
          state = const OfflineDataState(
            status: OfflineDataStatus.notDownloaded,
          );
        }
      } else {
        debugPrint('Download failed: $e');
        if (mounted) {
          state = OfflineDataState(
            status: OfflineDataStatus.error,
            error: 'Download failed. Please check your connection.',
          );
        }
      }
    } catch (e) {
      debugPrint('Download failed: $e');
      if (mounted) {
        state = OfflineDataState(
          status: OfflineDataStatus.error,
          error: 'Download failed: ${e.toString()}',
        );
      }
    }
  }

  /// Cancel an in-progress download.
  void cancelDownload() {
    _cancelToken?.cancel('User cancelled');
    _cancelToken = null;
  }

  /// Delete the downloaded zones.db file.
  Future<void> deleteData() async {
    await _service.delete();
    final Box<dynamic> box = Hive.box(_settingsBox);
    await box.put(_keyDownloaded, false);
    state = const OfflineDataState(status: OfflineDataStatus.notDownloaded);
  }
}

// ============================================================================
// Providers
// ============================================================================

final Provider<OfflineDataService> offlineDataServiceProvider =
    Provider<OfflineDataService>((Ref ref) {
  return OfflineDataService(
    baseUrl: 'https://astr-zones.astr-vansh-fyi.workers.dev',
  );
});

final StateNotifierProvider<OfflineDataNotifier, OfflineDataState>
    offlineDataProvider =
    StateNotifierProvider<OfflineDataNotifier, OfflineDataState>((Ref ref) {
  final OfflineDataService service = ref.watch(offlineDataServiceProvider);
  return OfflineDataNotifier(service);
});
