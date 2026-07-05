import 'package:astr/features/astronomy/domain/entities/moon_phase_info.dart';
import 'package:astr/features/dashboard/presentation/widgets/moon_mini_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MoonMiniCard renders correct details', (WidgetTester tester) async {
    const moonPhaseInfo = MoonPhaseInfo(
      illumination: 0.5,
      phaseAngle: 90, // First Quarter
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MoonMiniCard(moonPhaseInfo: moonPhaseInfo),
        ),
      ),
    );

    expect(find.text('MOON'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('First Quarter'), findsOneWidget);
  });
}
