import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_panel.dart';
import '../../../astronomy/domain/entities/celestial_body.dart';
import '../../domain/entities/highlight_item.dart';

class HighlightCard extends StatelessWidget {

  const HighlightCard({
    super.key,
    required this.item,
    this.onTap,
  });
  final HighlightItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset(
              _getAssetPath(item.body),
              width: 32,
              height: 32,
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

  String _getAssetPath(CelestialBody body) {
    switch (body) {
      case CelestialBody.sun:
        return 'assets/icons/stars/sun.webp';
      case CelestialBody.moon:
        return 'assets/img/moon_full.webp'; // Moon phases stay in img/
      case CelestialBody.mercury:
        return 'assets/icons/planets/mercury.webp';
      case CelestialBody.venus:
        return 'assets/icons/planets/venus.webp';
      case CelestialBody.mars:
        return 'assets/icons/planets/mars.webp';
      case CelestialBody.jupiter:
        return 'assets/icons/planets/jupiter.webp';
      case CelestialBody.saturn:
        return 'assets/icons/planets/saturn.webp';
      case CelestialBody.uranus:
        return 'assets/icons/planets/uranus.webp';
      case CelestialBody.neptune:
        return 'assets/icons/planets/neptune.webp';
      case CelestialBody.pluto:
        return 'assets/icons/stars/star.webp'; // Fallback to star for pluto
    }
  }
}
