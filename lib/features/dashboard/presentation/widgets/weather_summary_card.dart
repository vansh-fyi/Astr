import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/weather.dart';
import '../providers/weather_provider.dart';
import 'atmospherics_sheet.dart';
import 'data_card.dart';

/// Displays weather summary: Cloud Cover, Temperature, Wind (FR-11).
///
/// Shows:
/// - Cloud cover percentage (primary metric for stargazing)
/// - Temperature and wind conditions
/// - Seeing conditions (if available)
class WeatherSummaryCard extends ConsumerWidget {
  const WeatherSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Weather> weatherAsync = ref.watch(weatherProvider);
    final ThemeData theme = Theme.of(context);

    return weatherAsync.when(
      data: (Weather weather) {
        return GestureDetector(
          onTap: () {
            // Story 4.4 AC #1: Open hourly conditions sheet on tap
            showModalBottomSheet<void>(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (BuildContext context) => const AtmosphericsSheet(),
            );
          },
          child: DataCard(
            title: 'Conditions',
            icon: weather.isStale ? Icons.cloud_off : Icons.cloud_outlined,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Cloud Cover - Primary metric for stargazing
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    '${weather.cloudCover.round()}%',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: _getCloudCoverColor(context, weather.cloudCover),
                      fontWeight: FontWeight.bold,
                      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'cloud cover',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  // Stale data indicator (Task 4.4)
                  if (weather.isStale) ...<Widget>[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Colors.red.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Secondary metrics row
              Row(
                children: <Widget>[
                  // Temperature
                  if (weather.temperatureC != null)
                    _buildMetric(
                      context,
                      'Temp',
                      '${weather.temperatureC!.round()}°C',
                    ),
                  if (weather.temperatureC != null) const SizedBox(width: 24),
                  // Wind
                  if (weather.windSpeedKph != null)
                    _buildMetric(
                      context,
                      'Wind',
                      '${weather.windSpeedKph!.round()} km/h',
                    ),
                  if (weather.windSpeedKph != null) const SizedBox(width: 24),
                  // Seeing (if available)
                  if (weather.seeingLabel != null)
                    _buildMetric(
                      context,
                      'Seeing',
                      weather.seeingLabel!,
                    ),
                ],
              ),
            ],
          ),
          ),
        );
      },
      loading: () => DataCard(
        title: 'Conditions',
        icon: Icons.cloud_outlined,
        child: SizedBox(
          height: 60,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
      error: (Object _, StackTrace __) => DataCard(
        title: 'Conditions',
        icon: Icons.cloud_outlined,
        child: Row(
          children: <Widget>[
            Icon(
              Icons.cloud_off,
              size: 24,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Text(
              'Offline',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  /// Returns a color based on cloud cover for visual feedback.
  /// Lower cloud cover (better for stargazing) = success tones.
  /// Higher cloud cover = warning tones.
  /// Uses theme colors for Red Mode compatibility (Epic 5).
  Color _getCloudCoverColor(BuildContext context, double cloudCover) {
    final ThemeData theme = Theme.of(context);

    if (cloudCover < 20) {
      // Excellent - use theme's success/primary variant
      return theme.colorScheme.primary;
    } else if (cloudCover < 40) {
      // Good - lighter primary
      return theme.colorScheme.primary.withValues(alpha: 0.8);
    } else if (cloudCover < 60) {
      // Moderate - neutral
      return theme.colorScheme.onSurface;
    } else if (cloudCover < 80) {
      // Poor - muted warning
      return theme.colorScheme.onSurface.withValues(alpha: 0.8);
    } else {
      // Very poor - muted color
      return theme.colorScheme.onSurface.withValues(alpha: 0.7);
    }
  }
}
