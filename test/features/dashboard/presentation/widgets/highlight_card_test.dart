import 'package:astr/features/astronomy/domain/entities/celestial_body.dart';
import 'package:astr/features/dashboard/domain/entities/highlight_item.dart';
import 'package:astr/features/dashboard/presentation/widgets/highlight_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HighlightCard renders correctly', (WidgetTester tester) async {
    const HighlightItem item = HighlightItem(
      body: CelestialBody.jupiter,
      altitude: 45,
      magnitude: -2,
      isVisible: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HighlightCard(item: item),
        ),
      ),
    );

    expect(find.text('Jupiter'), findsOneWidget);
    expect(find.text('Visible Now'), findsOneWidget);
    // HighlightCard now uses Image.asset instead of Icon(Icons.public)
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('HighlightCard shows "Below Horizon" when not visible', (WidgetTester tester) async {
    const HighlightItem item = HighlightItem(
      body: CelestialBody.mars,
      altitude: -5,
      magnitude: 1,
      isVisible: false,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HighlightCard(item: item),
        ),
      ),
    );

    expect(find.text('Mars'), findsOneWidget);
    expect(find.text('Below Horizon'), findsOneWidget);
  });
}
