import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/widgets/glass_panel.dart';
import '../providers/offline_data_provider.dart';

/// Settings card for downloading/managing offline global zone data.
///
/// Displays three states:
/// - Not downloaded: download prompt with size info
/// - Downloading: progress bar with cancel option
/// - Downloaded: storage info with delete option
class OfflineDataCard extends ConsumerWidget {
  const OfflineDataCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OfflineDataState state = ref.watch(offlineDataProvider);

    return switch (state.status) {
      OfflineDataStatus.checking => const SizedBox.shrink(),
      OfflineDataStatus.notDownloaded => _buildDownloadPrompt(context, ref),
      OfflineDataStatus.downloading => _buildDownloading(context, ref, state),
      OfflineDataStatus.downloaded => _buildDownloaded(context, ref, state),
      OfflineDataStatus.error => _buildError(context, ref, state),
    };
  }

  // ── Not Downloaded ──────────────────────────────────────────────────────

  Widget _buildDownloadPrompt(BuildContext context, WidgetRef ref) {
    return GlassPanel(
      enableBlur: false,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Ionicons.cloud_download, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Download Global Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Full offline light zones coverage · ~1 GB\nYou can delete it anytime to clear storage',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _DownloadButton(
            onPressed: () {
              ref.read(offlineDataProvider.notifier).startDownload();
            },
          ),
        ],
      ),
    );
  }

  // ── Downloading ─────────────────────────────────────────────────────────

  Widget _buildDownloading(
    BuildContext context,
    WidgetRef ref,
    OfflineDataState state,
  ) {
    final int percent = (state.progress * 100).round();

    return GlassPanel(
      enableBlur: false,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Downloading…',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  ref.read(offlineDataProvider.notifier).cancelDownload();
                },
                icon: Icon(
                  Icons.close,
                  color: Colors.white.withOpacity(0.5),
                ),
                tooltip: 'Cancel',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 4,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  // ── Downloaded ──────────────────────────────────────────────────────────

  Widget _buildDownloaded(
    BuildContext context,
    WidgetRef ref,
    OfflineDataState state,
  ) {
    final String sizeText = _formatFileSize(state.fileSizeBytes);

    return GlassPanel(
      enableBlur: false,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Ionicons.checkmark_circle, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Global Data Downloaded',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Using $sizeText · Full offline coverage',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context, ref),
            icon: Icon(
              Ionicons.trash_outline,
              color: Colors.red.withOpacity(0.7),
              size: 20,
            ),
            tooltip: 'Delete offline data',
          ),
        ],
      ),
    );
  }

  // ── Error ───────────────────────────────────────────────────────────────

  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    OfflineDataState state,
  ) {
    return GlassPanel(
      enableBlur: false,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Ionicons.warning, color: Colors.red),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Download Failed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.error ?? 'An unknown error occurred',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _DownloadButton(
            label: 'Retry',
            onPressed: () {
              ref.read(offlineDataProvider.notifier).startDownload();
            },
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Offline Data?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Zone lookups will use the network instead.\nYou can re-download anytime.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(offlineDataProvider.notifier).deleteData();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'Unknown size';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Compact download/retry button matching the settings UI style.
class _DownloadButton extends StatelessWidget {
  const _DownloadButton({
    required this.onPressed,
    this.label = 'Download',
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Colors.blue.withOpacity(0.15),
        foregroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
