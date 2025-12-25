import 'package:astr/features/dashboard/domain/entities/stargazing_quality.dart';
import 'package:astr/features/dashboard/presentation/widgets/summary_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SummaryText', () {
    testWidgets('displays correct text for Excellent', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SummaryText(quality: StargazingQuality.excellent),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500)); // Allow animation to advance

      expect(find.text('Excellent'), findsOneWidget);
    });

    testWidgets('displays correct text for Poor', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SummaryText(quality: StargazingQuality.poor),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Poor'), findsOneWidget);
    });

    testWidgets('applies animation only for Excellent', (WidgetTester tester) async {
      // Excellent case
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SummaryText(quality: StargazingQuality.excellent),
          ),
        ),
      );
      
      // flutter_animate wraps the widget in Animate
      await tester.pump(); 
      await tester.pump(const Duration(milliseconds: 1000));
      // The custom builder uses DecoratedBox for the glow
      expect(find.byType(DecoratedBox), findsOneWidget);

      // Poor case
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SummaryText(quality: StargazingQuality.poor),
          ),
        ),
      );
      
      expect(find.byType(Animate), findsNothing);
    });
  });
}
