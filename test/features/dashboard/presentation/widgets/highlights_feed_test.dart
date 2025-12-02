import 'package:astr/features/astronomy/domain/entities/astronomy_state.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_body.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_position.dart';
import 'package:astr/features/astronomy/presentation/providers/astronomy_provider.dart';
import 'package:astr/features/dashboard/presentation/widgets/glass_panel.dart';
import 'package:astr/features/dashboard/presentation/widgets/highlights_feed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock AstronomyNotifier
class MockAstronomyNotifier extends AsyncNotifier<AstronomyState>
    implements AstronomyNotifier {
  @override
  Future<AstronomyState> build() async {
    return AstronomyState.initial();
  }
}

void main() {
  testWidgets('HighlightsFeed displays items when data is available', (tester) async {
    final now = DateTime.now();
    final positions = [
      CelestialPosition(
        body: CelestialBody.jupiter,
        time: now,
        altitude: 45.0,
        azimuth: 180.0,
        distance: 5.0,
        magnitude: -2.0,
      ),
      CelestialPosition(
        body: CelestialBody.venus,
        time: now,
        altitude: 30.0,
        azimuth: 90.0,
        distance: 0.7,
        magnitude: -4.0,
      ),
      CelestialPosition(
        body: CelestialBody.mars,
        time: now,
        altitude: 60.0,
        azimuth: 270.0,
        distance: 1.5,
        magnitude: 0.0,
      ),
    ];

    final state = AstronomyState(
      moonIllumination: 0.5,
      positions: positions,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          astronomyProvider.overrideWith(() => MockAstronomyNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HighlightsFeed(),
          ),
        ),
      ),
    );

    // Initial state is loading/empty
    await tester.pump();
    expect(find.byType(GlassPanel), findsNothing);

    // Update state
    final container = ProviderScope.containerOf(tester.element(find.byType(HighlightsFeed)));
    container.read(astronomyProvider.notifier).state = AsyncValue.data(state);
    
    await tester.pump();

    expect(find.text('TONIGHT\'S HIGHLIGHTS'), findsOneWidget);
    expect(find.byType(GlassPanel), findsNWidgets(3));
    expect(find.text('Venus'), findsOneWidget); // Brightest first
    expect(find.text('Jupiter'), findsOneWidget);
    expect(find.text('Mars'), findsOneWidget);
  });

  testWidgets('HighlightsFeed hides when no highlights available', (tester) async {
    final state = AstronomyState(
      moonIllumination: 0.5,
      positions: [], // No positions
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          astronomyProvider.overrideWith(() => MockAstronomyNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HighlightsFeed(),
          ),
        ),
      ),
    );

    final container = ProviderScope.containerOf(tester.element(find.byType(HighlightsFeed)));
    container.read(astronomyProvider.notifier).state = AsyncValue.data(state);
    
    await tester.pump();

    expect(find.text('TONIGHT\'S HIGHLIGHTS'), findsNothing);
    expect(find.byType(GlassPanel), findsNothing);
  });
}
