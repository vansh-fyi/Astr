import 'package:astr/core/widgets/astr_rive_animation.dart';
import 'package:astr/features/dashboard/domain/entities/light_pollution.dart';
import 'package:astr/features/dashboard/presentation/widgets/bortle_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AstrRiveAnimation.testMode = true;
  });

  testWidgets('BortleBar displays correct text and Rive animation', (WidgetTester tester) async {
    // arrange
    const LightPollution tLightPollution = LightPollution(
      visibilityIndex: 4,
      zone: 'Rural/suburban transition',
      mpsas: 20.49,
      source: LightPollutionSource.estimated,
      brightnessRatio: 1, // Added required parameter
    );

    // act
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BortleBar(lightPollution: tLightPollution),
        ),
      ),
    );

    // assert
    expect(find.text('VISIBILITY'), findsOneWidget);
    expect(find.text('Zone Rural/suburban transition'), findsOneWidget);
    expect(find.text('Rural'), findsOneWidget);
    expect(find.text('20.49 MPSAS'), findsOneWidget);
  });
}
