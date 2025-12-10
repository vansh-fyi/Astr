import 'package:astr/features/catalog/domain/entities/visibility_graph_data.dart';
import 'package:astr/features/catalog/domain/entities/graph_point.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:astr/features/dashboard/domain/entities/hourly_forecast.dart';

class VisibilityGraphPainter extends CustomPainter {
  final VisibilityGraphData data;
  final double scrubberPosition; // 0.0 to 1.0
  final DateTime startTime;
  final DateTime endTime;
  final Color? highlightColor;
  final List<HourlyForecast>? cloudCoverData;

  // Cache Paint objects
  late final Paint _objectCurvePaint;
  late final Paint _objectCurveGlowPaint;
  late final Paint _peakDotPaint;
  late final Paint _moonFillPaint;
  late final Paint _moonStrokePaint;

  final DateTime currentTime;

  VisibilityGraphPainter({
    required this.data,
    required this.scrubberPosition,
    required this.startTime,
    required this.endTime,
    required this.currentTime,
    this.highlightColor,
    this.cloudCoverData,
  }) {
    final color = highlightColor ?? const Color(0xFF3B82F6);

    _objectCurvePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _objectCurveGlowPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    _peakDotPaint = Paint()..color = color;

    _moonFillPaint = Paint()
      ..color = const Color(0xFF1E1B4B).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    _moonStrokePaint = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Cloud Cover (Background Layer)
    _drawCloudCover(canvas, size);

    // 2. Draw Moon Interference (if any)
    _drawMoonInterference(canvas, size);

    // 3. Draw Object Curve
    _drawObjectCurve(canvas, size);

    // 3.5. Draw Current Position Indicator (AC #1)
    _drawCurrentPositionIndicator(canvas, size);

    // 4. Draw Current Time Indicator
    _drawNowIndicator(canvas, size);

    // 5. Draw Moon Rise Indicator
    _drawMoonRiseIndicator(canvas, size);

    // 6. Draw Peak Altitude (Blue Circle)
    _drawPeakIndicator(canvas, size);

    // 7. Draw Scrubber (if active)
    if (scrubberPosition >= 0) {
      _drawScrubber(canvas, size);
    }
  }

  void _drawPeakIndicator(Canvas canvas, Size size) {
    if (data.objectCurve.isEmpty) return;

    // Find peak point
    GraphPoint? peakPoint;
    for (final point in data.objectCurve) {
      if (peakPoint == null || point.value > peakPoint.value) {
        peakPoint = point;
      }
    }

    if (peakPoint == null) return;

    final totalDuration = endTime.difference(startTime).inMinutes;
    final minutesFromStart = peakPoint.time.difference(startTime).inMinutes;
    
    // If peak is outside graph range, don't draw? Or clamp?
    // Usually we want to see it if it's within the window.
    if (minutesFromStart < 0 || minutesFromStart > totalDuration) return;

    final x = (minutesFromStart / totalDuration) * size.width;
    final y = size.height - (peakPoint.value / 90 * size.height *0.7);

    // Draw Peak Dot (Filled Circle, same color as line)
    canvas.drawCircle(Offset(x, y), 5, _peakDotPaint);
  }

  void _drawCloudCover(Canvas canvas, Size size) {
    if (cloudCoverData == null || cloudCoverData!.isEmpty) {
        // Fallback to subtle aesthetic background if no data
        _drawAestheticBackground(canvas, size);
        return;
    }

    final width = size.width;
    final height = size.height;
    final totalDuration = endTime.difference(startTime).inMinutes;

    if (totalDuration == 0) return;

    final path = Path();
    path.moveTo(0, height);

    bool isFirst = true;
    // Filter and sort data
    final relevantData = cloudCoverData!.where((d) => 
        !d.time.isBefore(startTime.subtract(const Duration(hours: 1))) && 
        !d.time.isAfter(endTime.add(const Duration(hours: 1)))
    ).toList()..sort((a, b) => a.time.compareTo(b.time));

    if (relevantData.isEmpty) {
        _drawAestheticBackground(canvas, size);
        return;
    }

    final points = <Offset>[];
    for (final point in relevantData) {
      final minutesFromStart = point.time.difference(startTime).inMinutes;
      final x = (minutesFromStart / totalDuration) * width;
      final y = height - (point.cloudCover / 100 * height);
      points.add(Offset(x, y));
    }

    if (points.isEmpty) {
      _drawAestheticBackground(canvas, size);
      return;
    }

    path.moveTo(points.first.dx, height);
    path.lineTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[max(0, i - 1)];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[min(points.length - 1, i + 2)];

      final cp1 = p1 + (p2 - p0) * 0.2;
      final cp2 = p2 - (p3 - p1) * 0.2;

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    
    // Close path
    path.lineTo(points.last.dx, height);
    path.lineTo(width, height);
    path.close();

    // Fill Gradient
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
      
    canvas.drawPath(path, paint);
    
    // Stroke
    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    // Re-create open path for stroke
    final strokePath = Path();
    strokePath.moveTo(points.first.dx, points.first.dy);
    
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[max(0, i - 1)];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[min(points.length - 1, i + 2)];

      final cp1 = p1 + (p2 - p0) * 0.2;
      final cp2 = p2 - (p3 - p1) * 0.2;

      strokePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    canvas.drawPath(strokePath, strokePaint);
  }

  void _drawAestheticBackground(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final path = Path();
    path.moveTo(0, height);
    
    // Aesthetic "cloud" curves
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

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;
      
    canvas.drawPath(path, paint);

    // Stroke
    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Re-create open path for stroke to avoid bottom line
    final strokePath = Path();
    strokePath.moveTo(0, mapY(points[0].dy));
    
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
      strokePath.cubicTo(cp1x, cp1y, cp2x, cp2y, x2, y2);
    }
    
    canvas.drawPath(strokePath, strokePaint);
  }

  void _drawMoonInterference(Canvas canvas, Size size) {
    if (data.moonCurve.isEmpty) return;

    final path = Path();
    final totalDuration = endTime.difference(startTime).inMinutes;
    
    final moonPath = Path();
    moonPath.moveTo(0, size.height);
    
    bool isFirst = true;
    bool isMoonUp = false;
    double firstMoonUpX = -1;

    for (final point in data.moonCurve) {
      final minutesFromStart = point.time.difference(startTime).inMinutes;
      final x = (minutesFromStart / totalDuration) * size.width;
      // Scale moon altitude to be visible but background
      final y = size.height - (point.value / 90 * size.height * 0.7); 
      
      if (point.value > 0) {
        if (!isMoonUp) {
            firstMoonUpX = x;
            isMoonUp = true;
        }
      }

      if (isFirst) {
        moonPath.lineTo(x, y);
        isFirst = false;
      } else {
        moonPath.lineTo(x, y);
      }
    }
    moonPath.lineTo(size.width, size.height);
    moonPath.close();

    canvas.drawPath(moonPath, _moonFillPaint);

    // Re-create open path for stroke
    final strokePath = Path();
    isFirst = true;
    isMoonUp = false;
    
    for (final point in data.moonCurve) {
      final minutesFromStart = point.time.difference(startTime).inMinutes;
      final x = (minutesFromStart / totalDuration) * size.width;
      final y = size.height - (point.value / 90 * size.height * 0.7); 
      
      if (point.value > 0) {
        if (!isMoonUp) {
            isMoonUp = true;
        }
      }

      if (isFirst) {
        strokePath.moveTo(x, y);
        isFirst = false;
      } else {
        strokePath.lineTo(x, y);
      }
    }

    canvas.drawPath(strokePath, _moonStrokePaint);
  }

  void _drawObjectCurve(Canvas canvas, Size size) {
    if (data.objectCurve.isEmpty) return;

    final path = Path();
    final totalDuration = endTime.difference(startTime).inMinutes;

    bool isFirst = true;
    for (final point in data.objectCurve) {
      final minutesFromStart = point.time.difference(startTime).inMinutes;
      final x = (minutesFromStart / totalDuration) * size.width;
      final y = size.height - (point.value / 90 * size.height *0.7);

      if (isFirst) {
        path.moveTo(x, y);
        isFirst = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, _objectCurveGlowPaint);
    canvas.drawPath(path, _objectCurvePaint);
  }

  void _drawCurrentPositionIndicator(Canvas canvas, Size size) {
    final now = currentTime;
    if (now.isBefore(startTime) || now.isAfter(endTime)) return;

    if (data.objectCurve.isEmpty) return;

    // Find surrounding points for interpolation
    GraphPoint? p1;
    GraphPoint? p2;

    for (int i = 0; i < data.objectCurve.length - 1; i++) {
      if (data.objectCurve[i].time.isBefore(now) && 
          data.objectCurve[i+1].time.isAfter(now)) {
        p1 = data.objectCurve[i];
        p2 = data.objectCurve[i+1];
        break;
      }
    }

    // Handle edge case where now matches a point exactly or is first/last
    if (p1 == null) {
       // Check if it matches exactly
       try {
         final exact = data.objectCurve.firstWhere((p) => p.time.isAtSameMomentAs(now));
         p1 = exact;
         p2 = exact;
       } catch (e) {
         return; // Should be covered by range check, but safety first
       }
    }

    // Interpolate Altitude
    final totalMillis = p2!.time.difference(p1!.time).inMilliseconds;
    final nowMillis = now.difference(p1.time).inMilliseconds;
    final fraction = totalMillis == 0 ? 0.0 : nowMillis / totalMillis;
    
    final altitude = p1.value + (p2.value - p1.value) * fraction;

    // Calculate Coordinates
    final totalDuration = endTime.difference(startTime).inMinutes;
    final minutesFromStart = now.difference(startTime).inMinutes;
    final x = (minutesFromStart / totalDuration) * size.width;
    final y = size.height - (altitude / 90 * size.height * 0.7);

    // Draw Indicator (White Circle with Colored Stroke)
    // AC #4: Glass UI aesthetic (4px stroke width, white fill)
    final strokeColor = highlightColor ?? const Color(0xFF3B82F6);
    
    // Outer Glow
    canvas.drawCircle(
      Offset(x, y),
      8,
      Paint()..color = strokeColor.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Stroke
    canvas.drawCircle(
      Offset(x, y),
      5, // Radius
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Fill
    canvas.drawCircle(
      Offset(x, y),
      5, // Radius matches stroke radius (stroke is centered)
      Paint()..color = Colors.white,
    );
  }

  void _drawNowIndicator(Canvas canvas, Size size) {
    final now = currentTime;
    if (now.isBefore(startTime) || now.isAfter(endTime)) return;

    final totalDuration = endTime.difference(startTime).inMinutes;
    final minutesFromStart = now.difference(startTime).inMinutes;
    final x = (minutesFromStart / totalDuration) * size.width;

    // Height constraint: Stay below SQM badge (approx 40px from top)
    // Let's start the line from top + 80 (Lowered as requested)
    final topY = 80.0;
    final height = size.height;

    // Gradient Line
    final nowLinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFF97316).withOpacity(0.5), // Orange-500/50
          const Color(0xFFF97316).withOpacity(0.0), // Transparent
        ],
      ).createShader(Rect.fromLTWH(x, topY, 1, height - topY));

    canvas.drawLine(
      Offset(x, topY),
      Offset(x, height),
      nowLinePaint,
    );

    // Now Label with Dot next to it
    _drawNowLabel(canvas, x, topY);
  }

  void _drawScrubber(Canvas canvas, Size size) {
    final x = scrubberPosition * size.width;
    final color = highlightColor ?? const Color(0xFFF97316);
    canvas.drawLine(
      Offset(x, 0), 
      Offset(x, size.height), 
      Paint()..color = color.withValues(alpha: 0.8)..strokeWidth = 1
    );
  }

  void _drawMoonRiseIndicator(Canvas canvas, Size size) {
    if (data.moonCurve.isEmpty) return;
    
    DateTime? riseTime;
    for (int i = 0; i < data.moonCurve.length - 1; i++) {
        final p1 = data.moonCurve[i];
        final p2 = data.moonCurve[i+1];
        if (p1.value <= 0 && p2.value > 0) {
            final totalDiff = p2.value - p1.value;
            final fraction = (0 - p1.value) / totalDiff;
            final timeDiff = p2.time.difference(p1.time).inMilliseconds;
            riseTime = p1.time.add(Duration(milliseconds: (timeDiff * fraction).round()));
            break;
        }
    }
    
    if (riseTime == null) return;
    if (riseTime.isBefore(startTime) || riseTime.isAfter(endTime)) return;

    final totalDuration = endTime.difference(startTime).inMinutes;
    final minutesFromStart = riseTime.difference(startTime).inMinutes;
    final x = (minutesFromStart / totalDuration) * size.width;
    final height = size.height;
    final labelY = height * 0.75;

    // Vertical Line (Short, up to label)
    final linePaint = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.5) // Indigo-500
      ..strokeWidth = 1;
    
    canvas.drawLine(
      Offset(x, height),
      Offset(x, labelY + 10),
      linePaint,
    );

    // Shiny Purple Dot
    canvas.drawCircle(
      Offset(x, labelY + 5),
      3,
      Paint()..color = const Color(0xFFA855F7), // Purple-500
    );
    canvas.drawCircle(
      Offset(x, labelY + 5),
      6,
      Paint()..color = const Color(0xFFA855F7).withOpacity(0.3), // Glow
    );

    // Moon Label (No Icon)
    _drawMoonLabel(canvas, x + 8, labelY);
  }

  void _drawMoonLabel(Canvas canvas, double x, double y) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'MOON RISE',
        style: TextStyle(
          color: Color(0xFFA5B4FC), // Indigo-300
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final padding = 4.0;
    final rect = Rect.fromLTWH(x, y, textPainter.width + padding * 2, textPainter.height + padding);

    final bgPaint = Paint()
      ..color = const Color(0xFF312E81).withOpacity(0.5) // Indigo-900/50
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.3) // Indigo-500/30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), borderPaint);

    textPainter.paint(canvas, Offset(x + padding, y + padding / 2));
  }

  void _drawNowLabel(Canvas canvas, double x, double y) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'NOW',
        style: TextStyle(
          color: Color(0xFFFB923C), // Orange-400
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final padding = 4.0;
    // Position label to the right of the line
    final rect = Rect.fromLTWH(x + 6, y, textPainter.width + padding * 2, textPainter.height + padding);

    final bgPaint = Paint()
      ..color = const Color(0xFFF97316).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFF97316).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), borderPaint);

    textPainter.paint(canvas, Offset(x + 6 + padding, y + padding / 2));
    
    // Dot at the top of the line (next to label)
    canvas.drawCircle(Offset(x, y), 3, Paint()..color = const Color(0xFFFB923C));
  }

  @override
  bool shouldRepaint(covariant VisibilityGraphPainter oldDelegate) {
    return oldDelegate.data != data || 
           oldDelegate.scrubberPosition != scrubberPosition ||
           oldDelegate.startTime != startTime ||
           oldDelegate.endTime != endTime ||
           oldDelegate.currentTime != currentTime;
  }
}

