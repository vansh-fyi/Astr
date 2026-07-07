import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../domain/entities/weather.dart';
import '../providers/weather_provider.dart';

/// Dashboard header widget displaying location name and last updated timestamp.
///
/// Story 4.2 (FR-13): Displays location name from AstrContext and "Last Updated"
/// indicator showing data freshness.
/// - Location name: from AstrContext.location.name, falls back to "Current Location"
/// - Format: "Updated 23m ago" (recent), "Updated 2:34 PM" (today), "Updated 2d ago" (old)
/// - Stale data shows error icon and red text
/// - Silent fail if timestamp unavailable
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Weather> weatherAsync = ref.watch(weatherProvider);

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: weatherAsync.when(
          data: (Weather weather) => _buildLastUpdated(context, weather),
          loading: () => const SizedBox.shrink(),
          error: (Object _, StackTrace __) => const SizedBox.shrink(),
        ),
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

    if (lastUpdated == null) {
      return const SizedBox.shrink();
    }

    final Duration diff = DateTime.now().difference(lastUpdated);
    final String timeText;

    if (diff.inMinutes < 60) {
      timeText = 'Updated ${timeago.format(lastUpdated, locale: 'en_short')}';
    } else if (diff.inHours < 24) {
      timeText = 'Updated ${DateFormat.jm().format(lastUpdated)}';
    } else {
      timeText = 'Updated ${timeago.format(lastUpdated, locale: 'en_short')}';
    }

    final IconData icon = weather.isStale ? Icons.sync_problem : Icons.sync;
    final Color color = weather.isStale
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: color),
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
