import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/hourly_forecast.dart';

class CloudCoverGraphPainter extends CustomPainter {

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
  final List<HourlyForecast> data;
  final DateTime startTime;
  final DateTime endTime;
  final Color cloudColor;
  final Color nowIndicatorColor;

  // Cache Paint objects to avoid recreation in paint()
  late final Paint _fillPaint;
  late final Paint _strokePaint;
  late final Paint _nowDotPaint;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // 1. Draw Cloud Cover Area
    _drawCloudCover(canvas, size);

    // 2. Draw Now Indicator
    _drawNowIndicator(canvas, size);
  }

  void _drawCloudCover(Canvas canvas, Size size) {
    final Path path = Path();
    final double width = size.width;
    final double height = size.height;
    final int totalDuration = endTime.difference(startTime).inMinutes;

    if (totalDuration == 0) return;

    path.moveTo(0, height);

    bool isFirst = true;
    for (final HourlyForecast point in data) {
      if (point.time.isBefore(startTime) || point.time.isAfter(endTime)) continue;

      final int minutesFromStart = point.time.difference(startTime).inMinutes;
      final double x = (minutesFromStart / totalDuration) * width;
      final double y = height - (point.weather.cloudCover / 100 * height);

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
    final HourlyForecast lastPoint = data.lastWhere((HourlyForecast p) => !p.time.isAfter(endTime), orElse: () => data.last);
    final int lastMinutes = lastPoint.time.difference(startTime).inMinutes;
    final double lastX = (lastMinutes / totalDuration) * width;
    
    path.lineTo(lastX, height);
    path.close();

    canvas.drawPath(path, _fillPaint);
      
    // Re-create open path for stroke
    final Path strokePath = Path();
    isFirst = true;
    for (final HourlyForecast point in data) {
      if (point.time.isBefore(startTime) || point.time.isAfter(endTime)) continue;

      final int minutesFromStart = point.time.difference(startTime).inMinutes;
      final double x = (minutesFromStart / totalDuration) * width;
      final double y = height - (point.weather.cloudCover / 100 * height);

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
    final DateTime now = DateTime.now();
    if (now.isBefore(startTime) || now.isAfter(endTime)) return;

    final int totalDuration = endTime.difference(startTime).inMinutes;
    final int minutesFromStart = now.difference(startTime).inMinutes;
    final double x = (minutesFromStart / totalDuration) * size.width;
    final double height = size.height;
    
    const double topY = 20; // Leave space for label

    // Gradient Line
    final Paint nowLinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          nowIndicatorColor.withOpacity(0.5),
          nowIndicatorColor.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(x, topY, 1, height - topY));

    canvas.drawLine(
      Offset(x, topY),
      Offset(x, height),
      nowLinePaint,
    );
    
    // Label
    final TextPainter textPainter = TextPainter(
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
