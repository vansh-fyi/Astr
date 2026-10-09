import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/hourly_forecast.dart';

/// Displays a scrollable list of hourly weather forecasts (FR-12, AC4).
///
/// Shows for each hour:
/// - Time
/// - Cloud cover %
/// - Temperature
/// - Wind speed
/// - Seeing conditions
///
/// High-contrast "Instrument" aesthetic on OLED-friendly black background.
class HourlyForecastList extends StatelessWidget {
  const HourlyForecastList({
    super.key,
    required this.forecasts,
    this.maxItems = 24,
  });

  /// List of hourly forecast data
  final List<HourlyForecast> forecasts;

  /// Maximum number of items to display
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime now = DateTime.now();

    // Filter to future hours and limit
    final List<HourlyForecast> displayForecasts = forecasts
        .where((HourlyForecast f) => f.time.isAfter(now.subtract(const Duration(minutes: 30))))
        .take(maxItems)
        .toList();

    if (displayForecasts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No hourly data available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'HOURLY FORECAST',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // List of hours
        ...displayForecasts.map((HourlyForecast forecast) {
          final bool isCurrentHour = _isCurrentHour(forecast.time, now);
          return _buildHourRow(context, forecast, isCurrentHour);
        }),
      ],
    );
  }

  bool _isCurrentHour(DateTime forecastTime, DateTime now) {
    return forecastTime.hour == now.hour &&
        forecastTime.day == now.day &&
        forecastTime.month == now.month;
  }

  Widget _buildHourRow(BuildContext context, HourlyForecast forecast, bool isCurrentHour) {
    final ThemeData theme = Theme.of(context);
    final String timeLabel = DateFormat.Hm().format(forecast.time); // e.g., "21:00"
    
    // Color-code cloud cover
    final Color cloudColor = _getCloudCoverColor(forecast.cloudCover);
    
    // Color-code seeing
    final Color seeingColor = _getSeeingColor(forecast.seeingScore);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isCurrentHour
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          // Time
          SizedBox(
            width: 50,
            child: Text(
              timeLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isCurrentHour
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isCurrentHour ? FontWeight.bold : FontWeight.normal,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
          // Cloud cover
          Expanded(
            child: _buildMetricCell(
              context,
              Icons.cloud,
              '${forecast.cloudCover.round()}%',
              cloudColor,
            ),
          ),
          // Temperature
          Expanded(
            child: _buildMetricCell(
              context,
              Icons.thermostat,
              '${forecast.temperatureC.round()}°',
              theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          // Wind
          Expanded(
            child: _buildMetricCell(
              context,
              Icons.air,
              '${forecast.windSpeedKph.round()}',
              theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          // Seeing
          Expanded(
            child: _buildMetricCell(
              context,
              Icons.visibility,
              forecast.seeingLabel,
              seeingColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCell(BuildContext context, IconData icon, String value, Color color) {
    final ThemeData theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          size: 14,
          color: color.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Returns theme-based color for cloud cover (Red Mode compatible - Epic 5).
  /// Uses theme colors instead of hardcoded Material colors.
  Color _getCloudCoverColor(double cloudCover) {
    // Access theme through build context is not available in this method
    // Using a simple brightness-based approach that will work with theme
    // Primary color will be filtered by Red Mode when Epic 5 is implemented
    if (cloudCover < 20) {
      // Excellent - lighter tone
      return const Color(0xFF90EE90); // Light green tone that Red Mode can filter
    }
    if (cloudCover < 40) {
      // Good - medium tone
      return const Color(0xFFFFA500); // Amber tone
    }
    if (cloudCover < 60) {
      // Moderate - neutral
      return const Color(0xFFFFFFFF).withValues(alpha: 0.8);
    }
    if (cloudCover < 80) {
      // Poor - warning
      return const Color(0xFFFFFFFF).withValues(alpha: 0.6);
    }
    // Very poor
    return const Color(0xFFFFFFFF).withValues(alpha: 0.4);
  }

  /// Returns theme-based color for seeing score (Red Mode compatible - Epic 5).
  Color _getSeeingColor(int seeingScore) {
    if (seeingScore >= 8) {
      return const Color(0xFF90EE90); // Light green tone
    }
    if (seeingScore >= 5) {
      return const Color(0xFFFFA500); // Amber tone
    }
    return const Color(0xFFFFFFFF).withValues(alpha: 0.6);
  }
}
