import 'package:flutter/material.dart';

/// Base container widget for dashboard data cards (Story 4.3).
///
/// Optimized for OLED displays (NFR-09):
/// - Transparent/black background (pixels off)
/// - White border for visual separation
/// - High contrast text (4.5:1 - NFR-08)
///
/// Compatible with Red Mode (Epic 5) via Theme colors.
class DataCard extends StatelessWidget {
  const DataCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
  });

  /// Card title displayed at the top
  final String title;

  /// Optional icon displayed next to the title
  final IconData? icon;

  /// Card content (the actual data display)
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // OLED-friendly: No background color (pixels off)
        color: Colors.transparent,
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Header row with title and optional icon
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Card content
          child,
        ],
      ),
    );
  }
}
