import 'package:astr/features/catalog/domain/entities/graph_point.dart';
import 'package:astr/features/catalog/domain/entities/time_range.dart';
import 'package:astr/features/catalog/domain/entities/visibility_graph_data.dart';
import 'package:astr/features/catalog/presentation/providers/visibility_graph_notifier.dart';
import 'package:astr/features/catalog/presentation/widgets/visibility_graph_widget.dart';
import 'package:astr/features/dashboard/domain/entities/hourly_forecast.dart';

import 'package:astr/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VisibilityGraphWidget renders with cloud cover data', (WidgetTester tester) async {
    final DateTime now = DateTime.now();
    final DateTime startTime = now;
    final DateTime endTime = now.add(const Duration(hours: 12));

    final VisibilityGraphData mockGraphData = VisibilityGraphData(
      objectCurve: List.generate(13, (int i) => GraphPoint(time: startTime.add(Duration(hours: i)), value: 45)),
      moonCurve: <GraphPoint>[],
      optimalWindows: <TimeRange>[],
    );

    final List<HourlyForecast> mockCloudCoverData = List.generate(13, (int index) {
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
      ProviderScope(
        overrides: <Override>[
          visibilityGraphProvider('test-object').overrideWith((StateNotifierProviderRef<VisibilityGraphNotifier, VisibilityGraphState> ref) => MockVisibilityGraphNotifier(mockGraphData)),
          hourlyForecastProvider.overrideWith((FutureProviderRef<List<HourlyForecast>> ref) async => mockCloudCoverData),
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

  MockVisibilityGraphNotifier(this._data) : super(VisibilityGraphState(graphData: _data));
  final VisibilityGraphData _data;

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