import 'package:flutter/material.dart';
import 'package:astr/core/widgets/glass_panel.dart';
import '../../domain/entities/light_pollution.dart';

class BortleBar extends StatefulWidget {
  final LightPollution lightPollution;
  final VoidCallback? onTap;

  const BortleBar({
    super.key,
    required this.lightPollution,
    this.onTap,
  });

  @override
  State<BortleBar> createState() => _BortleBarState();
}

class _BortleBarState extends State<BortleBar> {


  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      enableBlur: false,
      onTap: widget.onTap,
      child: SizedBox(
        height: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Header and Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'VISIBILITY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.4),
                    letterSpacing: 1.0,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    'Zone ${widget.lightPollution.zone}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            // Middle: Big Label
            Center(
              child: Text(
                _getShortLabel(widget.lightPollution.visibilityIndex),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // Bottom: MPSAS and Scale
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.lightPollution.mpsas.toStringAsFixed(2)} MPSAS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Segmented Bar
                Row(
                  children: List.generate(5, (index) {
                    final isActive = index == ((widget.lightPollution.visibilityIndex - 1) / 2).floor();
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.blue : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: isActive ? [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.6),
                              blurRadius: 8,
                            )
                          ] : null,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getShortLabel(int cls) {
    if (cls <= 2) return 'Dark Sky';
    if (cls <= 4) return 'Rural';
    if (cls <= 6) return 'Suburban';
    return 'Urban';
  }
}
