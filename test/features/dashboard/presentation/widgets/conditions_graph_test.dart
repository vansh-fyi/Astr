import 'package:astr/features/catalog/domain/entities/graph_point.dart';
import 'package:astr/features/dashboard/domain/entities/hourly_forecast.dart';

import 'package:astr/features/dashboard/presentation/widgets/conditions_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ConditionsGraph renders cloud cover data', (tester) async {
    final now = DateTime.now();
    final startTime = now;
    final endTime = now.add(const Duration(hours: 12));

    final cloudCoverData = List.generate(13, (index) {
      return HourlyForecast(
        time: startTime.add(Duration(hours: index)),
        cloudCover: 50.0,
        temperatureC: 20,
        humidity: 50,
        windSpeedKph: 10,
        seeingScore: 5,
        seeingLabel: 'Good',
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            width: 400,
            child: ConditionsGraph(
              startTime: startTime,
              endTime: endTime,
              cloudCoverData: cloudCoverData,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ConditionsGraph), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
