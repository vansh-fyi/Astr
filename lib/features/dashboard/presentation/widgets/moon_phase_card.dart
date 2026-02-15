import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../astronomy/domain/entities/astronomy_state.dart';
import '../../../astronomy/domain/entities/moon_phase_info.dart';
import '../../../astronomy/presentation/providers/astronomy_provider.dart';
import '../../../catalog/domain/entities/celestial_object.dart';
import '../../../catalog/presentation/providers/object_detail_notifier.dart';
import '../../../catalog/presentation/providers/rise_set_provider.dart';
import 'data_card.dart';

/// Displays moon phase information (FR-11).
///
/// Shows:
/// - Phase name (New Moon, First Quarter, Full, Last Quarter, etc.)
/// - Illumination percentage
/// - Visual moon phase indicator
class MoonPhaseCard extends ConsumerWidget {
  const MoonPhaseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AstronomyState> astronomyAsync = ref.watch(astronomyProvider);
    final ThemeData theme = Theme.of(context);

    // Get moon object for rise/set times
    final ObjectDetailState moonState = ref.watch(objectDetailNotifierProvider('moon'));
    final CelestialObject? moonObject = moonState.object;
    final Map<String, DateTime?>? moonTimes = moonObject != null
        ? ref.watch(riseSetProvider(moonObject)).valueOrNull
        : null;

    return astronomyAsync.when(
      data: (AstronomyState astronomy) {
        final MoonPhaseInfo moon = astronomy.moonPhaseInfo;
        final String phaseName = _getPhaseName(moon.phaseAngle);
        final int illuminationPercent = (moon.illumination * 100).round();

        return DataCard(
          title: 'Moon',
          icon: Icons.brightness_2,
          child: Row(
            children: <Widget>[
              // Moon phase visual indicator
              _buildMoonIndicator(context, moon),
              const SizedBox(width: 16),
              // Moon data
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Phase name - Primary
                    Text(
                      phaseName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Illumination - Secondary
                    Text(
                      '$illuminationPercent% illuminated',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                      ),
                    ),
                    // Rise/Set times (AC #2)
                    if (moonTimes != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          if (moonTimes['rise'] != null) ...<Widget>[
                            Icon(
                              Icons.arrow_upward,
                              size: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('HH:mm').format(moonTimes['rise']!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (moonTimes['set'] != null) ...<Widget>[
                            Icon(
                              Icons.arrow_downward,
                              size: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('HH:mm').format(moonTimes['set']!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => DataCard(
        title: 'Moon',
        icon: Icons.brightness_2,
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
        title: 'Moon',
        icon: Icons.brightness_2,
        child: Text(
          'No Data',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  /// Builds a simple visual moon phase indicator using a clipped circle.
  Widget _buildMoonIndicator(BuildContext context, MoonPhaseInfo moon) {
    final ThemeData theme = Theme.of(context);
    const double size = 48;

    // Determine how much of the moon is lit based on phase angle
    // Phase angle: 0=New, 90=First Quarter, 180=Full, 270=Last Quarter
    final double phaseAngle = moon.phaseAngle;
    final bool isWaxing = phaseAngle < 180;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: CustomPaint(
          size: const Size(size, size),
          painter: _MoonPhasePainter(
            illumination: moon.illumination,
            isWaxing: isWaxing,
            moonColor: theme.colorScheme.onSurface,
            shadowColor: theme.colorScheme.surface,
          ),
        ),
      ),
    );
  }

  /// Returns the moon phase name based on the phase angle.
  String _getPhaseName(double phaseAngle) {
    // Normalize angle to 0-360
    final double angle = phaseAngle % 360;

    if (angle < 11.25 || angle >= 348.75) {
      return 'New Moon';
    } else if (angle < 78.75) {
      // Waxing Crescent: 11.25° - 78.75°
      return 'Waxing Crescent';
    } else if (angle < 101.25) {
      return 'First Quarter';
    } else if (angle < 168.75) {
      // Waxing Gibbous: 101.25° - 168.75°
      return 'Waxing Gibbous';
    } else if (angle < 191.25) {
      return 'Full Moon';
    } else if (angle < 258.75) {
      // Waning Gibbous: 191.25° - 258.75°
      return 'Waning Gibbous';
    } else if (angle < 281.25) {
      return 'Last Quarter';
    } else {
      // Waning Crescent: 281.25° - 348.75°
      return 'Waning Crescent';
    }
  }
}

/// Custom painter for moon phase visualization.
class _MoonPhasePainter extends CustomPainter {
  _MoonPhasePainter({
    required this.illumination,
    required this.isWaxing,
    required this.moonColor,
    required this.shadowColor,
  });

  final double illumination;
  final bool isWaxing;
  final Color moonColor;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint moonPaint = Paint()..color = moonColor;
    final Paint shadowPaint = Paint()..color = shadowColor;

    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    // Draw full moon (lit part)
    canvas.drawCircle(center, radius, moonPaint);

    // Draw shadow overlay based on illumination
    // illumination 0 = full shadow, 1 = no shadow
    final double shadowWidth = (1 - illumination) * size.width;

    if (shadowWidth > 0) {
      final Rect shadowRect = isWaxing
          ? Rect.fromLTWH(0, 0, shadowWidth, size.height)
          : Rect.fromLTWH(size.width - shadowWidth, 0, shadowWidth, size.height);

      canvas.drawOval(shadowRect, shadowPaint);
    }
  }

  @override
  bool shouldRepaint(_MoonPhasePainter oldDelegate) {
    return illumination != oldDelegate.illumination ||
        isWaxing != oldDelegate.isWaxing ||
        moonColor != oldDelegate.moonColor ||
        shadowColor != oldDelegate.shadowColor;
  }
}
