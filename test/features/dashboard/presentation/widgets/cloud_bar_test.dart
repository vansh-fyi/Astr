import 'package:astr/features/dashboard/presentation/widgets/cloud_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CloudBar displays percentage and handles loading state', (WidgetTester tester) async {
    // arrange
    const double tPercentage = 75;

    // act
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CloudBar(cloudCoverPercentage: tPercentage),
        ),
      ),
    );

    // assert
    expect(find.text('Cloud Cover'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);

    // Test Loading State
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CloudBar(cloudCoverPercentage: 0, isLoading: true),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Test Error State
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CloudBar(cloudCoverPercentage: 0, errorMessage: 'Error fetching weather'),
        ),
      ),
    );

    expect(find.text('Error fetching weather'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
