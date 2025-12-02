import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:astr/features/planner/presentation/screens/forecast_screen.dart';
import 'package:astr/features/planner/presentation/providers/planner_provider.dart';
import 'package:astr/features/planner/domain/entities/daily_forecast.dart';
import 'package:astr/features/planner/presentation/widgets/forecast_list_item.dart';

void main() {
  testWidgets('ForecastScreen renders loading state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          forecastListProvider.overrideWith((ref) => Future.value([])), // Initial loading
        ],
        child: const MaterialApp(home: ForecastScreen()),
      ),
    );

    // Initial state of FutureProvider is loading if we don't await it, 
    // but here we are overriding with a Future.
    // To simulate loading, we can use a Completer or just check if it shows loading initially.
    // Actually, FutureProvider emits loading first.
    
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ForecastScreen renders list of forecasts', (tester) async {
    final forecasts = List.generate(7, (index) {
      return DailyForecast(
        date: DateTime(2025, 12, 1).add(Duration(days: index)),
        cloudCoverAvg: 10.0,
        moonIllumination: 0.5,
        weatherCode: 0,
        starRating: 4,
      );
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          forecastListProvider.overrideWith((ref) => forecasts),
        ],
        child: const MaterialApp(home: ForecastScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ForecastListItem), findsNWidgets(7));
    expect(find.text('Mon, Dec 1'), findsOneWidget);
    expect(find.text('10%'), findsWidgets);
  });

  testWidgets('ForecastScreen renders error state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          forecastListProvider.overrideWith((ref) => Future.error('API Error')),
        ],
        child: const MaterialApp(home: ForecastScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Error loading forecast'), findsOneWidget);
  });
}
