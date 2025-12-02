import 'package:astr/core/widgets/glass_panel.dart';
import 'package:astr/features/catalog/domain/entities/celestial_object.dart';
import 'package:astr/features/catalog/domain/entities/celestial_type.dart';
import 'package:astr/features/catalog/presentation/providers/rise_set_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Widget displaying a single celestial object in the catalog list
class ObjectListItem extends StatelessWidget {
  final CelestialObject object;
  final VoidCallback onTap;

  const ObjectListItem({
    super.key,
    required this.object,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  _getIconForType(),
                  size: 32,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Name and Type
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Text(
                    object.type.displayName.substring(
                      0,
                      object.type.displayName.length - 1,
                    ), // Remove plural 's'
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Rise/Set Time (placeholder for Story 3.2)
                  const SizedBox(height: 4),
                  // Rise/Set Time
                  Consumer(
                    builder: (context, ref, child) {
                      final asyncTimes = ref.watch(riseSetProvider(object));
                      
                      return asyncTimes.when(
                        data: (times) {
                          final rise = times['rise'] != null ? DateFormat('HH:mm').format(times['rise']!) : '-- : --';
                          final set = times['set'] != null ? DateFormat('HH:mm').format(times['set']!) : '-- : --';
                          return Text(
                            '↑ $rise | ↓ $set',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              fontFamily: 'monospace',
                            ),
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

  IconData _getIconForType() {
    switch (object.type) {
      case CelestialType.planet:
        return Icons.public;
      case CelestialType.star:
        return Icons.star;
      case CelestialType.constellation:
        return Icons.grid_on;
      case CelestialType.galaxy:
        return Icons.blur_circular;
      case CelestialType.nebula:
        return Icons.cloud;
      case CelestialType.cluster:
        return Icons.grain;
    }
  }
}
