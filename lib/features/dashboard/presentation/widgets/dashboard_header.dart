import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../context/domain/entities/astr_context.dart';
import '../../../context/presentation/providers/astr_context_provider.dart';
import '../../domain/entities/weather.dart';
import '../providers/weather_provider.dart';

/// Dashboard header widget displaying location name and last updated timestamp.
///
/// Story 4.2 (FR-13): Displays "Last Updated" indicator showing data freshness.
/// - Format: "Updated 23m ago" (recent), "Updated 2:34 PM" (today), "Updated 2d ago" (old)
/// - Stale data shows error icon and red text
/// - Silent fail if timestamp unavailable
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Weather> weatherAsync = ref.watch(weatherProvider);
    final AsyncValue<AstrContext> contextAsync = ref.watch(astrContextProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          // Location name (from AstrContext)
          Flexible(
            child: contextAsync.when(
              data: (AstrContext astrContext) => Text(
                astrContext.location?.name ?? 'Current Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              loading: () => const SizedBox.shrink(),
              error: (Object _, StackTrace __) => const SizedBox.shrink(),
            ),
          ),

          const SizedBox(width: 8),

          // Last Updated indicator (FR-13)
          weatherAsync.when(
            data: (Weather weather) => _buildLastUpdated(context, weather),
            loading: () => const SizedBox.shrink(),
            error: (Object _, StackTrace __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Builds the "Last Updated" indicator with timestamp.
  ///
  /// Format logic:
  /// - <1h: "Updated 23m ago" (timeago format)
  /// - 1-24h: "Updated 2:34 PM" (time format)
  /// - >24h: "Updated 2d ago" (timeago format)
  Widget _buildLastUpdated(BuildContext context, Weather weather) {
    final DateTime? lastUpdated = weather.lastUpdated;

    // Silent fail if no timestamp (FR-13)
    if (lastUpdated == null) {
      return const SizedBox.shrink();
    }

    // Calculate time difference
    final Duration diff = DateTime.now().difference(lastUpdated);
    final String timeText;

    if (diff.inMinutes < 60) {
      // Recent: "Updated 23m ago"
      timeText = 'Updated ${timeago.format(lastUpdated, locale: 'en_short')}';
    } else if (diff.inHours < 24) {
      // Today: "Updated 2:34 PM"
      timeText = 'Updated ${DateFormat.jm().format(lastUpdated)}';
    } else {
      // Older: "Updated 2d ago"
      timeText = 'Updated ${timeago.format(lastUpdated, locale: 'en_short')}';
    }

    // Determine icon and color based on stale status
    final IconData icon = weather.isStale ? Icons.sync_problem : Icons.sync;
    final Color color = weather.isStale
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          timeText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
