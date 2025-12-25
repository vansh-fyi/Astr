import 'package:astr/features/dashboard/domain/entities/hourly_forecast.dart';

import 'package:astr/features/dashboard/presentation/widgets/conditions_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ConditionsGraph renders cloud cover data', (WidgetTester tester) async {
    final DateTime now = DateTime.now();
    final DateTime startTime = now;
    final DateTime endTime = now.add(const Duration(hours: 12));

    final List<HourlyForecast> cloudCoverData = List.generate(13, (int index) {
      return HourlyForecast(
        time: startTime.add(Duration(hours: index)),
        cloudCover: 50,
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
