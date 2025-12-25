import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../dashboard/domain/entities/hourly_forecast.dart';
import '../../../dashboard/presentation/providers/weather_provider.dart';
import '../../../dashboard/presentation/theme/graph_theme.dart';
import '../../../dashboard/presentation/widgets/graph_legend_item.dart';
import '../../domain/entities/graph_point.dart';
import '../../domain/entities/visibility_graph_data.dart';
import '../providers/visibility_graph_notifier.dart';
import 'visibility_graph_painter.dart';

/// Widget that displays the visibility graph using CustomPaint
class VisibilityGraphWidget extends ConsumerStatefulWidget {

  const VisibilityGraphWidget({
    super.key,
    required this.objectId,
    this.highlightColor,
  });
  final String objectId;
  final Color? highlightColor;

  @override
  ConsumerState<VisibilityGraphWidget> createState() =>
      _VisibilityGraphWidgetState();
}

class _VisibilityGraphWidgetState extends ConsumerState<VisibilityGraphWidget> {
  // Scrubber position (0.0 to 1.0)
  double _scrubberPosition = -1;
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
    final double position = (dx / width).clamp(0.0, 1.0);
    
    final int totalDuration = data.objectCurve.last.time.difference(data.objectCurve.first.time).inMinutes;
    final int minutesFromStart = (position * totalDuration).round();
    final DateTime time = data.objectCurve.first.time.add(Duration(minutes: minutesFromStart));

    // Find closest altitude point
    double? altitude;
    try {
      final GraphPoint point = data.objectCurve.reduce((GraphPoint a, GraphPoint b) {
        final Duration diffA = a.time.difference(time).abs();
        final Duration diffB = b.time.difference(time).abs();
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
    final VisibilityGraphState state = ref.watch(visibilityGraphProvider(widget.objectId));
    
    // Fetch Cloud Cover Data
    final AsyncValue<List<HourlyForecast>> hourlyForecastAsync = ref.watch(hourlyForecastProvider);
    final List<HourlyForecast>? cloudCoverData = hourlyForecastAsync.valueOrNull;

    final Color highlightColor = widget.highlightColor ?? const Color(0xFF3B82F6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Header & Legend
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Visibility',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: <Widget>[
                  GraphLegendItem(label: 'OBJECT', color: GraphTheme.objectCurveColor),
                  SizedBox(width: 12),
                  GraphLegendItem(label: 'MOON', color: GraphTheme.moonColor),
                  SizedBox(width: 12),
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
    final DateTime startTime = data.objectCurve.first.time;
    final DateTime endTime = data.objectCurve.last.time;

    return Column(
      children: <Widget>[
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
              children: <Widget>[
                // Gradient Background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          highlightColor.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Interactive Graph
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return GestureDetector(
                      onHorizontalDragStart: (DragStartDetails details) =>
                          _updateScrubber(details.localPosition.dx, constraints.maxWidth, data),
                      onHorizontalDragUpdate: (DragUpdateDetails details) =>
                          _updateScrubber(details.localPosition.dx, constraints.maxWidth, data),
                      onHorizontalDragEnd: (_) {
                        setState(() {
                          _scrubberPosition = -1.0;
                          _scrubbedTime = null;
                          _scrubbedAltitude = null;
                        });
                      },
                      onTapDown: (TapDownDetails details) =>
                          _updateScrubber(details.localPosition.dx, constraints.maxWidth, data),
                      onTapUp: (_) {
                        setState(() {
                          _scrubberPosition = -1.0;
                          _scrubbedTime = null;
                          _scrubbedAltitude = null;
                        });
                      },
                      child: Stack(
                        children: <Widget>[
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
                                  children: <Widget>[
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
    final Duration duration = end.difference(start);
    final int interval = duration.inMinutes ~/ 4;
    
    return List.generate(5, (int index) {
      final DateTime time = start.add(Duration(minutes: interval * index));
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