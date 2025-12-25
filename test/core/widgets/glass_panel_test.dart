
import 'package:astr/core/widgets/glass_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GlassPanel renders BackdropFilter when specific enableBlur is true (default)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassPanel(
            child: Text('Blurry'),
          ),
        ),
      ),
    );

    // Should find BackdropFilter
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('Blurry'), findsOneWidget);
  });

  testWidgets('GlassPanel DOES NOT render BackdropFilter when enableBlur is false', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassPanel(
            enableBlur: false,
            child: Text('Clear'),
          ),
        ),
      ),
    );

    // Should NOT find BackdropFilter
    expect(find.byType(BackdropFilter), findsNothing);
    // Should still find content
    expect(find.text('Clear'), findsOneWidget);
  });
}
