import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../context/domain/entities/astr_context.dart';
import '../../../context/presentation/providers/astr_context_provider.dart';
import '../../domain/entities/light_pollution.dart';
import '../providers/visibility_provider.dart';
import 'data_card.dart';

/// Displays light pollution data: Bortle Class, SQM, and Ratio (FR-02, FR-11).
///
/// Uses data from VisibilityProvider (LightPollution entity).
/// Adheres to "Instrument" aesthetic: high contrast, data-first display.
class DarknessCard extends ConsumerWidget {
  const DarknessCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final VisibilityState visibilityState = ref.watch(visibilityProvider);
    final AsyncValue<AstrContext> contextAsync = ref.watch(astrContextProvider);
    final ThemeData theme = Theme.of(context);

    // Check if we have a valid location
    final bool hasLocation = contextAsync.hasValue;

    if (!hasLocation) {
      return const SizedBox.shrink();
    }

    final LightPollution data = visibilityState.lightPollution;

    // No data state
    if (data.visibilityIndex == 0 && data.source == LightPollutionSource.estimated) {
      return DataCard(
        title: 'Darkness',
        icon: Icons.nightlight_round,
        child: Text(
          'No Data',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return DataCard(
      title: 'Darkness',
      icon: Icons.nightlight_round,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Bortle Class - Primary value
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                'Class ${data.visibilityIndex}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _getBortleLabel(data.visibilityIndex),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // SQM and Ratio - Secondary values
          Row(
            children: <Widget>[
              _buildMetric(
                context,
                'SQM',
                '${data.mpsas.toStringAsFixed(1)} mag/arcsec²',
              ),
              const SizedBox(width: 24),
              if (data.brightnessRatio > 0)
                _buildMetric(
                  context,
                  'Ratio',
                  data.brightnessRatio.toStringAsFixed(2),
                ),
            ],
          ),
        ],
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

  String _getBortleLabel(int bortle) {
    switch (bortle) {
      case 1:
        return 'Excellent';
      case 2:
        return 'Truly Dark';
      case 3:
        return 'Rural';
      case 4:
        return 'Rural/Suburban';
      case 5:
        return 'Suburban';
      case 6:
        return 'Bright Suburban';
      case 7:
        return 'Suburban/Urban';
      case 8:
        return 'City';
      case 9:
        return 'Inner City';
      default:
        return '';
    }
  }
}
