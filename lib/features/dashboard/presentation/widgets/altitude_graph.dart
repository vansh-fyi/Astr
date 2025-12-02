import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AltitudeGraph extends StatefulWidget {
  final Color themeColor;

  const AltitudeGraph({
    super.key,
    this.themeColor = Colors.orange,
  });

  @override
  State<AltitudeGraph> createState() => _AltitudeGraphState();
}

class _AltitudeGraphState extends State<AltitudeGraph> {
  double _scrubberPosition = -1.0;
  String? _scrubbedTimeLabel;
  double? _scrubbedAltitude;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragStart: (details) => _updateScrubber(details.localPosition.dx, constraints.maxWidth),
          onHorizontalDragUpdate: (details) => _updateScrubber(details.localPosition.dx, constraints.maxWidth),
          onHorizontalDragEnd: (_) => _resetScrubber(),
          onTapDown: (details) => _updateScrubber(details.localPosition.dx, constraints.maxWidth),
          onTapUp: (_) => _resetScrubber(),
          child: Stack(
            children: [
              // Graph Painter
              CustomPaint(
                size: Size.infinite,
                painter: _AltitudeGraphPainter(
                  themeColor: widget.themeColor,
                  scrubberPosition: _scrubberPosition,
                ),
              ),
              
              // Floating Tooltip
              if (_scrubberPosition >= 0 && _scrubbedTimeLabel != null)
                Positioned(
                  left: (_scrubberPosition * constraints.maxWidth).clamp(0, constraints.maxWidth - 80),
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _scrubbedTimeLabel!,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        if (_scrubbedAltitude != null)
                          Text(
                            'Alt: ${_scrubbedAltitude!.toStringAsFixed(1)}°',
                            style: TextStyle(color: widget.themeColor, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ),

              // Labels (X-Axis) - Only show when not scrubbing or show faintly?
              // Keeping them always visible for context
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 30,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('18:00', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    Text('21:00', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    Text('00:00', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text('03:00', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    Text('06:00', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateScrubber(double localDx, double width) {
    final position = (localDx / width).clamp(0.0, 1.0);
    
    // Mock Data Mapping
    // 0.0 -> 18:00
    // 0.5 -> 00:00
    // 1.0 -> 06:00
    // Total 12 hours
    
    final startHour = 18;
    final totalHours = 12;
    final currentHour = (startHour + (position * totalHours)) % 24;
    final minute = ((position * totalHours * 60) % 60).round();
    
    final timeLabel = '${currentHour.floor().toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    
    // Calculate Altitude (Sine wave approximation)
    final yNormalized = sin(position * pi);
    final altitude = yNormalized * 80; // Max 80 degrees

    setState(() {
      _scrubberPosition = position;
      _scrubbedTimeLabel = timeLabel;
      _scrubbedAltitude = altitude;
    });
  }

  void _resetScrubber() {
    setState(() {
      _scrubberPosition = -1.0;
      _scrubbedTimeLabel = null;
      _scrubbedAltitude = null;
    });
  }
}

class _AltitudeGraphPainter extends CustomPainter {
  final Color themeColor;
  final double scrubberPosition;

  // Cache Paint objects
  late final Paint _curvePaint;
  late final Paint _peakDotPaint;
  late final Paint _nowOuterDotPaint;
  late final Paint _nowInnerDotPaint;
  late final Paint _scrubberLinePaint;
  late final Paint _scrubberOuterDotPaint;
  late final Paint _scrubberInnerDotPaint;
  late final Paint _cloudBgPaint;

  _AltitudeGraphPainter({
    required this.themeColor,
    required this.scrubberPosition,
  }) {
    _curvePaint = Paint()
      ..color = themeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    _peakDotPaint = Paint()..color = themeColor;
    _nowOuterDotPaint = Paint()..color = Colors.white;
    _nowInnerDotPaint = Paint()..color = themeColor;
    _scrubberLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 1;
    _scrubberOuterDotPaint = Paint()..color = Colors.white;
    _scrubberInnerDotPaint = Paint()..color = themeColor;
    _cloudBgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height - 30;

    // 1. Draw Cloud Cover Background
    _drawCloudBackground(canvas, width, height);

    // 2. Draw Altitude Parabola
    final path = Path();
    path.moveTo(0, height);
    
    for (double x = 0; x <= width; x++) {
      final t = x / width;
      final yNormalized = sin(t * pi); // 0 -> 1 -> 0
      final y = height - (yNormalized * height * 0.8);
      
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, _curvePaint);

    // Draw Peak Dot
    final peakX = width * 0.5;
    final peakY = height - (height * 0.8);
    canvas.drawCircle(Offset(peakX, peakY), 5, _peakDotPaint);

    // Draw Current Time Indicator (Static "Now")
    // Let's say "Now" is at 0.2
    final nowX = width * 0.2;
    final nowT = 0.2;
    final nowYNormalized = sin(nowT * pi);
    final nowY = height - (nowYNormalized * height * 0.8);

    canvas.drawCircle(Offset(nowX, nowY), 4, _nowOuterDotPaint);
    canvas.drawCircle(Offset(nowX, nowY), 2, _nowInnerDotPaint);

    // Draw Scrubber Line
    if (scrubberPosition >= 0) {
      final x = scrubberPosition * width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, height),
        _scrubberLinePaint,
      );

      // Draw Dot on Curve at Scrubber
      final scrubYNormalized = sin(scrubberPosition * pi);
      final scrubY = height - (scrubYNormalized * height * 0.8);

      canvas.drawCircle(Offset(x, scrubY), 6, _scrubberOuterDotPaint);
      canvas.drawCircle(Offset(x, scrubY), 4, _scrubberInnerDotPaint);
    }
  }

  void _drawCloudBackground(Canvas canvas, double width, double height) {
    final path = Path();
    path.moveTo(0, height);
    
    final points = [
      const Offset(0.0, 0.8),
      const Offset(0.25, 0.3),
      const Offset(0.5, 0.1),
      const Offset(0.75, 0.6),
      const Offset(1.0, 0.9),
    ];

    double mapY(double normalizedY) => height - (normalizedY * height);

    path.lineTo(0, mapY(points[0].dy));
    
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final x1 = p1.dx * width;
      final y1 = mapY(p1.dy);
      final x2 = p2.dx * width;
      final y2 = mapY(p2.dy);
      final cp1x = x1 + (x2 - x1) / 2;
      final cp1y = y1;
      final cp2x = x2 - (x2 - x1) / 2;
      final cp2y = y2;
      path.cubicTo(cp1x, cp1y, cp2x, cp2y, x2, y2);
    }
    
    path.lineTo(width, height);
    path.close();

    canvas.drawPath(path, _cloudBgPaint);
  }

  @override
  bool shouldRepaint(covariant _AltitudeGraphPainter oldDelegate) {
    return oldDelegate.scrubberPosition != scrubberPosition ||
           oldDelegate.themeColor != themeColor;
  }
}
