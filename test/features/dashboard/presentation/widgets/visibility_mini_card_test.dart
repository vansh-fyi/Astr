import 'package:astr/features/dashboard/domain/entities/light_pollution.dart';
import 'package:astr/features/dashboard/presentation/widgets/visibility_mini_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VisibilityMiniCard renders correct details', (WidgetTester tester) async {
    const lightPollution = LightPollution(
      visibilityIndex: 3, // Rural Sky
      brightnessRatio: 0.5,
      mpsas: 21.2,
      source: LightPollutionSource.precise,
      zone: '3',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VisibilityMiniCard(lightPollution: lightPollution),
        ),
      ),
    );

    expect(find.text('VISIBILITY'), findsOneWidget);
    expect(find.text('Zone 3'), findsOneWidget);
    expect(find.text('Rural Sky'), findsOneWidget);
    expect(find.text('21.20 MPSAS'), findsOneWidget);
  });
}
