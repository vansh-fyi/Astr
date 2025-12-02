import 'dart:async';
import 'package:astr/features/context/domain/entities/astr_context.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:astr/features/planner/domain/entities/daily_forecast.dart';
import 'package:astr/features/planner/presentation/pages/forecast_screen.dart';
import 'package:astr/features/planner/presentation/providers/planner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

void main() {
  testWidgets('ForecastScreen displays loading indicator initially', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ForecastScreen(),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ForecastScreen displays list and handles tap', (tester) async {
    final tDate = DateTime.now();
    final tForecasts = [
      DailyForecast(
        date: tDate,
        cloudCoverAvg: 10.0,
        moonIllumination: 0.0,
        weatherCode: '0',
        starRating: 5,
      ),
      DailyForecast(
        date: tDate.add(const Duration(days: 1)),
        cloudCoverAvg: 90.0,
        moonIllumination: 0.5,
        weatherCode: '3',
        starRating: 1,
      ),
    ];

    final mockNotifier = MockAstrContextNotifier();

    final router = GoRouter(
      initialLocation: '/forecast',
      routes: [
        GoRoute(
          path: '/forecast',
          builder: (context, state) => const ForecastScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home Screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          plannerProvider.overrideWith(() => FakePlanner(tForecasts)),
          astrContextProvider.overrideWith(() => mockNotifier),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify list items
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);

    // Tap the second item (Tomorrow)
    await tester.tap(find.text('90%'));
    await tester.pumpAndSettle();

    // Verify updateDate was called with correct date
    expect(mockNotifier.updatedDate, tForecasts[1].date);

    // Verify navigation to Home
    expect(find.text('Home Screen'), findsOneWidget);
  });
}

class FakePlanner extends Planner {
  final List<DailyForecast> _data;
  FakePlanner(this._data);

  @override
  FutureOr<List<DailyForecast>> build() {
    return _data;
  }
}

class MockAstrContextNotifier extends AstrContextNotifier {
  DateTime? updatedDate;

  @override
  Future<AstrContext> build() async {
    return AstrContext(
      selectedDate: DateTime.now(),
      location: const GeoLocation(latitude: 0, longitude: 0, name: 'Test'),
      isCurrentLocation: true,
    );
  }

  @override
  void updateDate(DateTime date) {
    updatedDate = date;
    // We don't need to actually update state for this test, just verify the call
    // But if we wanted to:
    // state = AsyncValue.data(state.value!.copyWith(selectedDate: date));
  }
}
