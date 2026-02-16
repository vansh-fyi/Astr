import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/glass_panel.dart';
import '../../domain/entities/celestial_object.dart';
import '../../domain/entities/celestial_type.dart';
import '../providers/rise_set_provider.dart';

/// Widget displaying a single celestial object in the catalog list
class ObjectListItem extends StatelessWidget {

  const ObjectListItem({
    super.key,
    required this.object,
    required this.onTap,
  });
  final CelestialObject object;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        enableBlur: false,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: object.iconPath.isNotEmpty
                    ? Image.asset(
                        object.iconPath,
                        width: 32,
                        height: 32,
                      )
                    : Image.asset(
                        _getDefaultAssetForType(),
                        width: 32,
                        height: 32,
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Name and Type
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    object.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Rise/Set Time
                  Consumer(
                    builder: (BuildContext context, WidgetRef ref, Widget? child) {
                      final AsyncValue<Map<String, DateTime?>> asyncTimes = ref.watch(riseSetProvider(object));

                      return asyncTimes.when(
                        data: (Map<String, DateTime?> times) {
                          final String rise = times['rise'] != null ? DateFormat('HH:mm').format(times['rise']!) : '-- : --';
                          final String set = times['set'] != null ? DateFormat('HH:mm').format(times['set']!) : '-- : --';
                          final String offsetLabel = ref.watch(locationOffsetLabelProvider);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  offsetLabel,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white.withOpacity(0.45),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '↑ $rise | ↓ $set',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => Text(
                          'Calculating...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5),
                            fontFamily: 'monospace',
                          ),
                        ),
                        error: (_, __) => Text(
                          '↑ -- : -- | ↓ -- : --',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5),
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Magnitude (if available)
            if (object.magnitude != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Mag ${object.magnitude!.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(width: 8),

            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  String _getDefaultAssetForType() {
    switch (object.type) {
      case CelestialType.planet:
      case CelestialType.satellite:
        return 'assets/icons/stars/star.webp'; // Fallback for planets/satellites
      case CelestialType.star:
        return 'assets/icons/stars/star.webp';
      case CelestialType.constellation:
        return 'assets/icons/stars/star.webp'; // Fallback for constellations without iconPath
      case CelestialType.galaxy:
        return 'assets/icons/galaxy/andromeda.webp'; // Default galaxy icon
      case CelestialType.nebula:
        return 'assets/icons/nebula/orion_nebula.webp'; // Default nebula icon
      case CelestialType.cluster:
        return 'assets/icons/cluster/pleidas.webp'; // Default cluster icon
    }
  }
}
