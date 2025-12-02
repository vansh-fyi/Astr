import 'package:astr/features/catalog/domain/entities/graph_point.dart';
import 'package:astr/features/catalog/domain/entities/visibility_graph_data.dart';
import 'package:astr/features/catalog/presentation/providers/visibility_graph_notifier.dart';
import 'package:astr/features/catalog/presentation/widgets/visibility_graph_widget.dart';
import 'package:astr/features/dashboard/domain/entities/hourly_forecast.dart';

import 'package:astr/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VisibilityGraphWidget renders with cloud cover data', (tester) async {
    final now = DateTime.now();
    final startTime = now;
    final endTime = now.add(const Duration(hours: 12));

    final mockGraphData = VisibilityGraphData(
      objectCurve: List.generate(13, (i) => GraphPoint(time: startTime.add(Duration(hours: i)), value: 45.0)),
      moonCurve: [],
      optimalWindows: [],
    );

    final mockCloudCoverData = List.generate(13, (index) {
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
      ProviderScope(
        overrides: [
          visibilityGraphProvider('test-object').overrideWith((ref) => MockVisibilityGraphNotifier(mockGraphData)),
          hourlyForecastProvider.overrideWith((ref) async => mockCloudCoverData),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: VisibilityGraphWidget(objectId: 'test-object'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(VisibilityGraphWidget), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('CLOUD'), findsOneWidget); // Legend item
  });
}

class MockVisibilityGraphNotifier extends StateNotifier<VisibilityGraphState> implements VisibilityGraphNotifier {
  final VisibilityGraphData _data;

  MockVisibilityGraphNotifier(this._data) : super(VisibilityGraphState(graphData: _data));

  @override
  Future<void> calculateGraph() async {}
  
  @override
  Future<void> refresh() async {}
  
  @override
  // ignore: unused_element
  set state(VisibilityGraphState value) {
    super.state = value;
  }
  
  @override
  VisibilityGraphState get state => super.state;

  @override
  // ignore: unused_field
  final String objectId = 'test-object';
}