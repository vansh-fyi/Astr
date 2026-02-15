import 'package:astr/features/dashboard/presentation/widgets/data_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataCard Widget Tests (Story 4.3)', () {
    testWidgets('renders title in uppercase with icon', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataCard(
              title: 'Test Card',
              icon: Icons.star,
              child: Text('Content'),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('TEST CARD'), findsOneWidget); // Uppercase
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('has transparent background for OLED (NFR-09)', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Color(0xFF000000),
            body: DataCard(
              title: 'OLED Test',
              child: Text('Content'),
            ),
          ),
        ),
      );

      // Assert: Container should have transparent color (pixels off)
      final Container container = tester.widget<Container>(
        find.descendant(
          of: find.byType(DataCard),
          matching: find.byType(Container).first,
        ),
      );
      final BoxDecoration decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, equals(Colors.transparent));
    });

    testWidgets('renders without icon when not provided', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataCard(
              title: 'No Icon',
              child: Text('Content'),
            ),
          ),
        ),
      );

      // Assert: No icon present
      expect(find.byType(Icon), findsNothing);
    });
  });
}
