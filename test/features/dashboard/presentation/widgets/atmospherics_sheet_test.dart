import 'package:astr/features/dashboard/domain/entities/weather.dart';
import 'package:astr/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:astr/features/dashboard/presentation/widgets/atmospherics_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ionicons/ionicons.dart';

void main() {
  testWidgets('AtmosphericsSheet displays Seeing score and label correctly', (WidgetTester tester) async {
    // Set a large screen size to avoid overflow
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;

    // Arrange
    const Weather weather = Weather(
      cloudCover: 10,
      temperatureC: 15,
      humidity: 60,
      windSpeedKph: 5,
      seeingScore: 8,
      seeingLabel: 'Good',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          weatherProvider.overrideWith(() => MockWeatherNotifier(weather)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AtmosphericsSheet()),
          ),
        ),
      ),
    );

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('SEEING'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('15°C'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);

    // Reset view
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('AtmosphericsSheet displays correct color for Excellent Seeing', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;

    const Weather weather = Weather(
      cloudCover: 0,
      seeingScore: 9,
      seeingLabel: 'Excellent',
      temperatureC: 10,
      humidity: 50,
      windSpeedKph: 5,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          weatherProvider.overrideWith(() => MockWeatherNotifier(weather)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AtmosphericsSheet()),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final Finder seeingCardFinder = find.ancestor(
      of: find.text('SEEING'),
      matching: find.byType(GlassPanel),
    );
    final Finder labelFinder = find.descendant(
      of: seeingCardFinder,
      matching: find.text('Excellent'),
    );
    final Text textWidget = tester.widget<Text>(labelFinder);
    expect(textWidget.style?.color, Colors.greenAccent);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('AtmosphericsSheet displays correct color for Poor Seeing', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;

    const Weather weather = Weather(
      cloudCover: 0,
      seeingScore: 3,
      seeingLabel: 'Poor',
      temperatureC: 10,
      humidity: 50,
      windSpeedKph: 5,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          weatherProvider.overrideWith(() => MockWeatherNotifier(weather)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AtmosphericsSheet()),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final Finder seeingCardFinder = find.ancestor(
      of: find.text('SEEING'),
      matching: find.byType(GlassPanel),
    );
    final Finder labelFinder = find.descendant(
      of: seeingCardFinder,
      matching: find.text('Poor'),
    );
    final Text textWidget = tester.widget<Text>(labelFinder);
    expect(textWidget.style?.color, Colors.redAccent);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}

class MockWeatherNotifier extends AsyncNotifier<Weather> implements WeatherNotifier {

  MockWeatherNotifier(this._initialState);
  final Weather _initialState;

  @override
  Future<Weather> build() async {
    return _initialState;
  }
  
  @override
  Future<void> refresh() async {}
}
