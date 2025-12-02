import 'package:astr/features/dashboard/domain/entities/hourly_forecast.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CloudCoverGraphPainter extends CustomPainter {
  final List<HourlyForecast> data;
  final DateTime startTime;
  final DateTime endTime;
  final Color cloudColor;
  final Color nowIndicatorColor;

  // Cache Paint objects to avoid recreation in paint()
  late final Paint _fillPaint;
  late final Paint _strokePaint;
  late final Paint _nowDotPaint;

  CloudCoverGraphPainter({
    required this.data,
    required this.startTime,
    required this.endTime,
    required this.cloudColor,
    required this.nowIndicatorColor,
  }) {
    _fillPaint = Paint()
      ..color = cloudColor
      ..style = PaintingStyle.fill;

    _strokePaint = Paint()
      ..color = cloudColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    _nowDotPaint = Paint()..color = nowIndicatorColor;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // 1. Draw Cloud Cover Area
    _drawCloudCover(canvas, size);

    // 2. Draw Now Indicator
    _drawNowIndicator(canvas, size);
  }

  void _drawCloudCover(Canvas canvas, Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    final totalDuration = endTime.difference(startTime).inMinutes;

    if (totalDuration == 0) return;

    path.moveTo(0, height);

    bool isFirst = true;
    for (final point in data) {
      if (point.time.isBefore(startTime) || point.time.isAfter(endTime)) continue;

      final minutesFromStart = point.time.difference(startTime).inMinutes;
      final x = (minutesFromStart / totalDuration) * width;
      final y = height - (point.weather.cloudCover / 100 * height);

      if (isFirst) {
        path.lineTo(x, y);
        isFirst = false;
      } else {
        path.lineTo(x, y);
      }
    }

    // Close the path
    // Find the last point's x to close properly
    // Actually, let's just draw to the last point and then down
    // But we iterate through data points which might be sparse or hourly.
    // We should probably interpolate or just draw lines between points.
    
    // Let's ensure we close it at the bottom right
    final lastPoint = data.lastWhere((p) => !p.time.isAfter(endTime), orElse: () => data.last);
    final lastMinutes = lastPoint.time.difference(startTime).inMinutes;
    final lastX = (lastMinutes / totalDuration) * width;
    
    path.lineTo(lastX, height);
    path.close();

    canvas.drawPath(path, _fillPaint);
      
    // Re-create open path for stroke
    final strokePath = Path();
    isFirst = true;
    for (final point in data) {
      if (point.time.isBefore(startTime) || point.time.isAfter(endTime)) continue;

      final minutesFromStart = point.time.difference(startTime).inMinutes;
      final x = (minutesFromStart / totalDuration) * width;
      final y = height - (point.weather.cloudCover / 100 * height);

      if (isFirst) {
        strokePath.moveTo(x, y);
        isFirst = false;
      } else {
        strokePath.lineTo(x, y);
      }
    }
    canvas.drawPath(strokePath, _strokePaint);
  }

  void _drawNowIndicator(Canvas canvas, Size size) {
    final now = DateTime.now();
    if (now.isBefore(startTime) || now.isAfter(endTime)) return;

    final totalDuration = endTime.difference(startTime).inMinutes;
    final minutesFromStart = now.difference(startTime).inMinutes;
    final x = (minutesFromStart / totalDuration) * size.width;
    final height = size.height;
    
    final topY = 20.0; // Leave space for label

    // Gradient Line
    final nowLinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          nowIndicatorColor.withOpacity(0.5),
          nowIndicatorColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(x, topY, 1, height - topY));

    canvas.drawLine(
      Offset(x, topY),
      Offset(x, height),
      nowLinePaint,
    );
    
    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'NOW',
        style: TextStyle(
          color: nowIndicatorColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    textPainter.paint(canvas, Offset(x + 4, topY));

    // Dot
    canvas.drawCircle(Offset(x, topY), 3, _nowDotPaint);
  }

  @override
  bool shouldRepaint(covariant CloudCoverGraphPainter oldDelegate) {
    return oldDelegate.data != data ||
           oldDelegate.startTime != startTime ||
           oldDelegate.endTime != endTime;
  }
}
