import 'package:astr/core/widgets/glass_panel.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_body.dart';
import 'package:astr/features/dashboard/domain/entities/highlight_item.dart';
import 'package:flutter/material.dart';

class HighlightCard extends StatelessWidget {
  final HighlightItem item;
  final VoidCallback? onTap;

  const HighlightCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIcon(item.body),
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              item.body.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.isVisible ? 'Visible Now' : 'Below Horizon',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(CelestialBody body) {
    switch (body) {
      case CelestialBody.sun:
        return Icons.wb_sunny;
      case CelestialBody.moon:
        return Icons.nightlight_round;
      default:
        return Icons.public; // Generic planet icon
    }
  }
}
