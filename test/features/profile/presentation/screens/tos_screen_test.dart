import 'package:astr/features/profile/presentation/screens/tos_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ToSScreen renders correctly', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ToSScreen(),
        ),
      ),
    );

    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.textContaining('Astr is not liable'), findsOneWidget);
    expect(find.text('I Agree'), findsOneWidget);
  });
}
