import 'package:astr/core/widgets/red_mode_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RedModeOverlay applies ColorFiltered when enabled', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RedModeOverlay(
          enabled: true,
          child: Text('Content'),
        ),
      ),
    );

    expect(find.byType(ColorFiltered), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('RedModeOverlay does not apply ColorFiltered when disabled', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RedModeOverlay(
          enabled: false,
          child: Text('Content'),
        ),
      ),
    );

    expect(find.byType(ColorFiltered), findsNothing);
    expect(find.text('Content'), findsOneWidget);
  });
}
