import 'dart:async';
import 'package:astr/core/widgets/glass_panel.dart';
import 'package:astr/features/catalog/domain/entities/visibility_graph_data.dart';
import 'package:astr/features/catalog/presentation/providers/visibility_graph_notifier.dart';
import 'package:astr/features/catalog/presentation/widgets/visibility_graph_painter.dart';
import 'package:astr/features/dashboard/domain/entities/hourly_forecast.dart';
import 'package:astr/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:astr/features/dashboard/presentation/widgets/graph_legend_item.dart';
import 'package:astr/features/dashboard/presentation/theme/graph_theme.dart';

/// Widget that displays the visibility graph using CustomPaint
class VisibilityGraphWidget extends ConsumerStatefulWidget {
  final String objectId;
  final Color? highlightColor;

  const VisibilityGraphWidget({
    super.key,
    required this.objectId,
    this.highlightColor,
  });

  @override
  ConsumerState<VisibilityGraphWidget> createState() =>
      _VisibilityGraphWidgetState();
}

class _VisibilityGraphWidgetState extends ConsumerState<VisibilityGraphWidget> {
  // Scrubber position (0.0 to 1.0)
  double _scrubberPosition = -1.0;
  DateTime? _scrubbedTime;
  double? _scrubbedAltitude;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Fetch graph data when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(visibilityGraphProvider(widget.objectId).notifier).calculateGraph();
    });

    // AC #2: Real-time updates (every minute)
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateScrubber(double dx, double width, VisibilityGraphData data) {
    if (width <= 0) return;
    final position = (dx / width).clamp(0.0, 1.0);
    
    final totalDuration = data.objectCurve.last.time.difference(data.objectCurve.first.time).inMinutes;
    final minutesFromStart = (position * totalDuration).round();
    final time = data.objectCurve.first.time.add(Duration(minutes: minutesFromStart));

    // Find closest altitude point
    double? altitude;
    try {
      final point = data.objectCurve.reduce((a, b) {
        final diffA = a.time.difference(time).abs();
        final diffB = b.time.difference(time).abs();
        return diffA < diffB ? a : b;
      });
      altitude = point.value;
    } catch (e) {
      // ignore
    }

    setState(() {
      _scrubberPosition = position;
      _scrubbedTime = time;
      _scrubbedAltitude = altitude;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visibilityGraphProvider(widget.objectId));
    
    // Fetch Cloud Cover Data
    final hourlyForecastAsync = ref.watch(hourlyForecastProvider);
    final cloudCoverData = hourlyForecastAsync.valueOrNull;

    final highlightColor = widget.highlightColor ?? const Color(0xFF3B82F6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header & Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Visibility',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  GraphLegendItem(label: 'OBJECT', color: GraphTheme.objectCurveColor),
                  const SizedBox(width: 12),
                  GraphLegendItem(label: 'MOON', color: GraphTheme.moonColor),
                  const SizedBox(width: 12),
                  GraphLegendItem(label: 'CLOUD', color: GraphTheme.cloudCoverColor),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),

        // Graph Content
        if (state.isLoading)
          const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.error != null)
          SizedBox(
            height: 200,
            child: Center(child: Text('Error: ${state.error}', style: const TextStyle(color: Colors.red))),
          )
        else if (state.graphData != null)
          _buildGraph(state.graphData!, highlightColor, cloudCoverData)
        else
          const SizedBox(
            height: 200,
            child: Center(child: Text('No data available', style: TextStyle(color: Colors.white54))),
          ),
      ],
    );
  }

  Widget _buildGraph(VisibilityGraphData data, Color highlightColor, List<HourlyForecast>? cloudCoverData) {
    final startTime = data.objectCurve.first.time;
    final endTime = data.objectCurve.last.time;

    return Column(
      children: [
        // Graph Area
        Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Gradient Background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          highlightColor.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Interactive Graph
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onHorizontalDragStart: (details) =>
                          _updateScrubber(details.localPosition.dx, constraints.maxWidth, data),
                      onHorizontalDragUpdate: (details) =>
                          _updateScrubber(details.localPosition.dx, constraints.maxWidth, data),
                      onHorizontalDragEnd: (_) {
                        setState(() {
                          _scrubberPosition = -1.0;
                          _scrubbedTime = null;
                          _scrubbedAltitude = null;
                        });
                      },
                      onTapDown: (details) =>
                          _updateScrubber(details.localPosition.dx, constraints.maxWidth, data),
                      onTapUp: (_) {
                        setState(() {
                          _scrubberPosition = -1.0;
                          _scrubbedTime = null;
                          _scrubbedAltitude = null;
                        });
                      },
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: Size(constraints.maxWidth, 200),
                            painter: VisibilityGraphPainter(
                              data: data,
                              scrubberPosition: _scrubberPosition,
                              startTime: startTime,
                              endTime: endTime,
                              currentTime: DateTime.now(),
                              highlightColor: highlightColor,
                              cloudCoverData: cloudCoverData,
                            ),
                          ),
                          // Floating tooltip when scrubbing
                          if (_scrubberPosition >= 0 && _scrubbedTime != null)
                            Positioned(
                              left: (_scrubberPosition * constraints.maxWidth)
                                  .clamp(0, constraints.maxWidth - 100),
                              top: 10,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat.jm().format(_scrubbedTime!),
                                      style: const TextStyle(
                                          color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    if (_scrubbedAltitude != null)
                                      Text(
                                        'Alt: ${_scrubbedAltitude!.toStringAsFixed(1)}°',
                                        style: TextStyle(
                                            color: highlightColor, fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        
        // X-Axis Labels
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _buildTimeLabels(startTime, endTime),
          ),
        ),
      ],
    );
  }
  
  List<Widget> _buildTimeLabels(DateTime start, DateTime end) {
    // Generate 5 labels evenly spaced
    final duration = end.difference(start);
    final interval = duration.inMinutes ~/ 4;
    
    return List.generate(5, (index) {
      final time = start.add(Duration(minutes: interval * index));
      return Text(
        DateFormat.j().format(time), // e.g., 6 PM
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
    });
  }
}