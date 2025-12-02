import 'package:astr/features/catalog/domain/entities/graph_point.dart';
import 'package:astr/features/dashboard/domain/entities/hourly_forecast.dart';
import 'dart:math';
import 'package:flutter/material.dart';

class ConditionsGraph extends StatelessWidget {
  final Color themeColor;
  final DateTime? moonRiseTime;
  final List<GraphPoint>? moonCurve;
  final List<HourlyForecast>? cloudCoverData;
  final DateTime startTime;
  final DateTime endTime;

  const ConditionsGraph({
    super.key,
    this.themeColor = Colors.indigo,
    this.moonRiseTime,
    this.moonCurve,
    this.cloudCoverData,
    required this.startTime,
    required this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Graph Painter
        CustomPaint(
          size: Size.infinite,
          painter: _ConditionsGraphPainter(
            themeColor: themeColor,
            moonRiseTime: moonRiseTime,
            moonCurve: moonCurve,
            cloudCoverData: cloudCoverData,
            startTime: startTime,
            endTime: endTime,
          ),
        ),
        
        // Labels (X-Axis)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _buildTimeLabels(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTimeLabels() {
    final labels = <Widget>[];
    final duration = endTime.difference(startTime);
    for (int i = 0; i <= 4; i++) {
        final time = startTime.add(Duration(minutes: (duration.inMinutes * (i / 4)).round()));
        final isMidnight = time.hour == 0;
        labels.add(
            Text(
                '${time.hour.toString().padLeft(2, '0')}:00',
                style: TextStyle(
                    color: isMidnight ? Colors.white : Colors.grey, 
                    fontSize: 10, 
                    fontWeight: isMidnight ? FontWeight.bold : FontWeight.normal
                ),
            ),
        );
    }
    return labels;
  }
}

class _ConditionsGraphPainter extends CustomPainter {
  final Color themeColor;
  final DateTime? moonRiseTime;
  final List<GraphPoint>? moonCurve;
  final List<HourlyForecast>? cloudCoverData;
  final DateTime startTime;
  final DateTime endTime;

  _ConditionsGraphPainter({
    required this.themeColor,
    this.moonRiseTime,
    this.moonCurve,
    this.cloudCoverData,
    required this.startTime,
    required this.endTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height - 30; // Reserve space for labels

    // 1. Draw Grid
    _drawGrid(canvas, width, height);

    // 2. Draw Cloud Cover (Area Chart)
    _drawCloudCover(canvas, width, height);

    // 3. Draw Moon Path (Overlay)
    if (moonCurve != null && moonCurve!.isNotEmpty) {
      _drawMoonCurve(canvas, width, height);
    }

    // 4. Moon Rise Indicator
    if (moonRiseTime != null && moonRiseTime!.isBefore(endTime) && moonRiseTime!.isAfter(startTime)) {
        final totalMinutes = endTime.difference(startTime).inMinutes;
        final moonMinutes = moonRiseTime!.difference(startTime).inMinutes;
        final moonX = (moonMinutes / totalMinutes) * width;
        final labelY = height * 0.75; // Low position
        
        // Vertical Line (Short, up to label)
        final linePaint = Paint()
          ..color = const Color(0xFF6366F1).withValues(alpha: 0.5) // Indigo-500
          ..strokeWidth = 1;
        
        canvas.drawLine(
          Offset(moonX, height),
          Offset(moonX, labelY + 10), // Stop at label
          linePaint,
        );

        // Shiny Purple Dot
        canvas.drawCircle(
          Offset(moonX, labelY + 5),
          3,
          Paint()..color = const Color(0xFFA855F7), // Purple-500
        );
        canvas.drawCircle(
          Offset(moonX, labelY + 5),
          6,
          Paint()..color = const Color(0xFFA855F7).withValues(alpha: 0.3), // Glow
        );

        // Moon Label (No Icon)
        _drawMoonLabel(canvas, moonX + 8, labelY);
    }

    // 5. Prime View Highlight
    // Keep fixed for now as requested
    final primeX = width * 0.5;
    
    // Gradient Line for Prime View
    final primeLinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF10B981).withValues(alpha: 0.5), // Emerald-500/50
          const Color(0xFF10B981).withValues(alpha: 0.0), // Transparent
        ],
      ).createShader(Rect.fromLTWH(primeX, height - 40, 1, 40));

    canvas.drawLine(Offset(primeX, height - 40), Offset(primeX, height), primeLinePaint);

    // Prime View Badge
    _drawPrimeViewBadge(canvas, primeX, height - 40);

    // 6. Current Time Indicator
    final now = DateTime.now();
    if (now.isAfter(startTime) && now.isBefore(endTime)) {
        final totalMinutes = endTime.difference(startTime).inMinutes;
        final nowMinutes = now.difference(startTime).inMinutes;
        final nowX = (nowMinutes / totalMinutes) * width;
        
        // Height constraint: Higher up (approx 35% from top)
        final indicatorHeight = height * 0.65; 
        final topY = height * 0.35;

        // Gradient Line for Now
        final nowLinePaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF97316).withValues(alpha: 0.5), // Orange-500/50
              const Color(0xFFF97316).withValues(alpha: 0.0), // Transparent
            ],
          ).createShader(Rect.fromLTWH(nowX, topY, 1, indicatorHeight));

        canvas.drawLine(
          Offset(nowX, topY),
          Offset(nowX, height),
          nowLinePaint,
        );
        
        // Now Label with Dot next to it
        _drawNowLabel(canvas, nowX, topY);
    }
  }

  void _drawMoonCurve(Canvas canvas, double width, double height) {
    if (moonCurve == null || moonCurve!.isEmpty) return;

    final path = Path();
    final paint = Paint()
      ..color = const Color(0xFF1E1B4B).withValues(alpha: 0.5) // Dark Indigo (Matches Visibility Graph)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.5) // Indigo-500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final totalDuration = endTime.difference(startTime).inMinutes;
    
    path.moveTo(0, height);
    
    bool isFirst = true;
    for (final point in moonCurve!) {
      final minutesFromStart = point.time.difference(startTime).inMinutes;
      final x = (minutesFromStart / totalDuration) * width;
      // Scale moon altitude (0-90) to graph height, clamping to 0 (horizon)
      final altitude = max(0.0, point.value);
      final y = height - (altitude / 90 * height); 
      
      if (isFirst) {
        path.lineTo(x, y);
        isFirst = false;
      } else {
        path.lineTo(x, y);
      }
    }
    path.lineTo(width, height);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Draw Stroke
    final strokePath = Path();
    isFirst = true;
    for (final point in moonCurve!) {
      final minutesFromStart = point.time.difference(startTime).inMinutes;
      final x = (minutesFromStart / totalDuration) * width;
      final altitude = max(0.0, point.value);
      final y = height - (altitude / 90 * height); 
      
      if (isFirst) {
        strokePath.moveTo(x, y);
        isFirst = false;
      } else {
        strokePath.lineTo(x, y);
      }
    }
    canvas.drawPath(strokePath, strokePaint);
  }

  void _drawCloudCover(Canvas canvas, double width, double height) {
    if (cloudCoverData == null || cloudCoverData!.isEmpty) return;

    final path = Path();
    path.moveTo(0, height); // Start bottom-left
    
    final totalDuration = endTime.difference(startTime).inMinutes;
    if (totalDuration == 0) return;

    bool isFirst = true;
    // Filter and sort data to ensure correct drawing order
    final relevantData = cloudCoverData!.where((d) => 
        !d.time.isBefore(startTime.subtract(const Duration(hours: 1))) && 
        !d.time.isAfter(endTime.add(const Duration(hours: 1)))
    ).toList()..sort((a, b) => a.time.compareTo(b.time));

    if (relevantData.isEmpty) return;

    if (relevantData.isEmpty) return;

    final points = <Offset>[];
    for (final point in relevantData) {
      final minutesFromStart = point.time.difference(startTime).inMinutes;
      final x = (minutesFromStart / totalDuration) * width;
      final y = height - (point.cloudCover / 100 * height);
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    path.moveTo(points.first.dx, height); // Start at bottom-left of first point
    path.lineTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[max(0, i - 1)];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[min(points.length - 1, i + 2)];

      final cp1 = p1 + (p2 - p0) * 0.2; // Tension 0.2
      final cp2 = p2 - (p3 - p1) * 0.2;

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    // Close the path
    path.lineTo(points.last.dx, height);
    path.lineTo(width, height); // Extend to right edge if needed
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
      ..color = const Color(0xFF312E81).withValues(alpha: 0.5) // Indigo-900/50
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.3) // Indigo-500/30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), borderPaint);

    textPainter.paint(canvas, Offset(x + padding, y + padding / 2));
  }

  void _drawPrimeViewBadge(Canvas canvas, double centerX, double bottomY) {
    const paddingHorizontal = 10.0;
    const paddingVertical = 4.0;
    
    final textSpan = TextSpan(
      children: [
        TextSpan(
          text: String.fromCharCode(Icons.auto_awesome.codePoint),
          style: TextStyle(
            color: const Color(0xFF34D399), // Emerald-400
            fontSize: 12,
            fontFamily: Icons.auto_awesome.fontFamily,
            package: Icons.auto_awesome.fontPackage,
          ),
        ),
        const TextSpan(text: ' '),
        const TextSpan(
          text: 'PRIME VIEW',
          style: TextStyle(
            color: Color(0xFF6EE7B7), // Emerald-300
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final badgeWidth = textPainter.width + (paddingHorizontal * 2);
    final badgeHeight = textPainter.height + (paddingVertical * 2);
    
    final badgeRect = Rect.fromCenter(
      center: Offset(centerX, bottomY - badgeHeight / 2),
      width: badgeWidth,
      height: badgeHeight,
    );

    final bgPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final shadowPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(20)), shadowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(20)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(20)), borderPaint);

    textPainter.paint(canvas, Offset(badgeRect.left + paddingHorizontal, badgeRect.top + paddingVertical));
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
      ..color = const Color(0xFFF97316).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFF97316).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), borderPaint);

    textPainter.paint(canvas, Offset(x + 6 + padding, y + padding / 2));
    
    // Dot at the top of the line (next to label)
    canvas.drawCircle(Offset(x, y), 3, Paint()..color = const Color(0xFFFB923C));
  }

  void _drawGrid(Canvas canvas, double width, double height) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (int i = 1; i < 5; i++) {
      final x = width * (i / 4);
      canvas.drawLine(Offset(x, 0), Offset(x, height), paint);
    }

    for (int i = 1; i < 4; i++) {
      final y = height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
