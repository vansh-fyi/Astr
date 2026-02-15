import 'package:astr/core/services/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToastService', () {
    testWidgets('showGPSTimeout should display correct message (NFR-10)', (WidgetTester tester) async {
      // Arrange: Build a widget tree with Scaffold
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => ToastService.showGPSTimeout(context),
                  child: const Text('Show Toast'),
                );
              },
            ),
          ),
        ),
      );

      // Act: Tap button to trigger toast
      await tester.tap(find.text('Show Toast'));
      await tester.pump(); // Start the SnackBar animation
      await tester.pump(const Duration(milliseconds: 100)); // Let animation progress

      // Assert: Verify NFR-10 message is displayed
      expect(
        find.text('GPS Unavailable. Restart or hit Refresh.'),
        findsOneWidget,
      );

      // Verify DISMISS action is present
      expect(find.text('DISMISS'), findsOneWidget);
    });

    testWidgets('showError should display error toast with dismiss action', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => ToastService.showError(context, 'Test error message'),
                  child: const Text('Show Error'),
                );
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show Error'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert
      expect(find.text('Test error message'), findsOneWidget);
      expect(find.text('DISMISS'), findsOneWidget);
    });

    testWidgets('showSuccess should display success toast', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => ToastService.showSuccess(context, 'Success!'),
                  child: const Text('Show Success'),
                );
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show Success'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert
      expect(find.text('Success!'), findsOneWidget);
    });

    testWidgets('showInfo should display info toast', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => ToastService.showInfo(context, 'Info message'),
                  child: const Text('Show Info'),
                );
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show Info'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert
      expect(find.text('Info message'), findsOneWidget);
    });

    testWidgets('DISMISS action should hide SnackBar', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => ToastService.showGPSTimeout(context),
                  child: const Text('Show Toast'),
                );
              },
            ),
          ),
        ),
      );

      // Act: Show toast
      await tester.tap(find.text('Show Toast'));
      await tester.pumpAndSettle(); // Wait for animations to complete

      // Verify toast is visible
      expect(find.text('GPS Unavailable. Restart or hit Refresh.'), findsOneWidget);

      // Tap DISMISS (use warnIfMissed: false to suppress warning)
      await tester.tap(find.text('DISMISS'), warnIfMissed: false);
      await tester.pumpAndSettle(); // Wait for dismiss animation

      // Assert: Toast should be dismissed
      expect(find.text('GPS Unavailable. Restart or hit Refresh.'), findsNothing);
    });

    testWidgets('SnackBar should use floating behavior (non-blocking)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return Column(
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () => ToastService.showGPSTimeout(context),
                      child: const Text('Show Toast'),
                    ),
                    const Text('Content below toast'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Content below should still be findable (non-blocking)
      expect(find.text('Content below toast'), findsOneWidget);
      expect(find.text('GPS Unavailable. Restart or hit Refresh.'), findsOneWidget);
    });
  });
}
