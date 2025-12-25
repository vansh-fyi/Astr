import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../../catalog/domain/entities/celestial_object.dart';
import '../../../catalog/domain/entities/visibility_graph_data.dart';
import '../../../catalog/presentation/providers/object_detail_notifier.dart';
import '../../../catalog/presentation/providers/rise_set_provider.dart';
import '../../../catalog/presentation/providers/visibility_graph_notifier.dart';
import '../../../catalog/presentation/widgets/visibility_graph_widget.dart';

class CelestialDetailSheet extends ConsumerWidget {

  const CelestialDetailSheet({
    super.key,
    required this.objectId,
    required this.title,
    required this.subtitle,
    this.themeColor = Colors.orange,
  });
  final String objectId;
  final String title;
  final String subtitle;
  final Color themeColor;

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Fetch Object Data (for Type, etc.)
    final ObjectDetailState objectState = ref.watch(objectDetailNotifierProvider(objectId));
    final CelestialObject? object = objectState.object;

    // 2. Fetch Rise/Set/Transit Times
    String transitTime = '--:--';
    String setTime = '--:--';
    
    if (object != null) {
      final AsyncValue<Map<String, DateTime?>> riseSetAsync = ref.watch(riseSetProvider(object));
      final Map<String, DateTime?>? times = riseSetAsync.valueOrNull;
      if (times != null) {
        if (times['transit'] != null) {
          transitTime = DateFormat('HH:mm').format(times['transit']!);
        }
        if (times['set'] != null) {
          setTime = DateFormat('HH:mm').format(times['set']!);
        }
      }
    }

    final double screenHeight = MediaQuery.of(context).size.height;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Stack(
          children: <Widget>[
            // 1. Background (Fixed)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  color: const Color(0xFF0A0A0B).withValues(alpha: 0.8),
                ),
              ),
            ),

            // 2. Scrollable Content
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  24,
                  150, // Top padding for header
                  24,
                  20 + bottomPadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Visibility Graph (Real Data)
                    VisibilityGraphWidget(
                      objectId: objectId,
                      highlightColor: themeColor,
                    ),
                    
                    const SizedBox(height: 24),

                    // Conditions Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'OBSERVING CONDITIONS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.5),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Excellent',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: themeColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Rise/Set Cards
                          Consumer(
                            builder: (BuildContext context, WidgetRef ref, Widget? child) {
                              final VisibilityGraphState visibilityState = ref.watch(visibilityGraphProvider(objectId));
                              final VisibilityGraphData? data = visibilityState.graphData;
                              
                              if (data == null) return const SizedBox.shrink();

                              return Row(
                                children: <Widget>[
                                  Expanded(child: _buildTimeCard('SUNRISE', data.sunRise)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildTimeCard('SUNSET', data.sunSet)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildTimeCard('MOONRISE', data.moonRise)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildTimeCard('MOONSET', data.moonSet)),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Grid Stats
                    Row(
                      children: <Widget>[
                        // _buildStat('Altitude', altitude, Colors.white), // Removed for now as we don't have real current altitude easily
                        _buildStat('Transit', transitTime, themeColor),
                        _buildStat('Set', setTime, Colors.white),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 3. Fixed Header with Blur
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0B).withValues(alpha: 0.7),
                      border: Border(
                        bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: themeColor,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Ionicons.close_circle, color: Colors.white54, size: 28),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(String label, DateTime? time) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 8,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            time != null ? DateFormat.Hm().format(time) : '--:--',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
