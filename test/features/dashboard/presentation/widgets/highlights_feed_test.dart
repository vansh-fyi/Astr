import 'package:astr/core/widgets/glass_panel.dart';
import 'package:astr/features/astronomy/domain/entities/astronomy_state.dart';
import 'package:astr/features/astronomy/domain/entities/moon_phase_info.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_body.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_position.dart';
import 'package:astr/features/astronomy/domain/services/astronomy_service.dart';
import 'package:astr/features/astronomy/presentation/providers/astronomy_provider.dart';
import 'package:astr/features/catalog/domain/entities/graph_point.dart';
import 'package:astr/features/context/domain/entities/astr_context.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:astr/features/dashboard/presentation/widgets/highlights_feed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweph/sweph.dart';

/// Fake that returns the provided [AstronomyState] from build().
class FakeAstronomyNotifierWith extends AstronomyNotifier {
  FakeAstronomyNotifierWith(this._state);
  final AstronomyState _state;

  @override
  Future<AstronomyState> build() async => _state;
}

/// Fake that returns initial (empty) state.
class FakeAstronomyNotifierEmpty extends AstronomyNotifier {
  @override
  Future<AstronomyState> build() async => AstronomyState.initial();
}

class FakeAstrContextNotifier extends AstrContextNotifier {
  @override
  Future<AstrContext> build() async {
    return AstrContext(
      selectedDate: DateTime.now(),
      location: const GeoLocation(latitude: 0, longitude: 0, name: 'Test'),
    );
  }
}

/// Mock AstronomyService that avoids native FFI (sweph).
class MockAstronomyService implements AstronomyService {
  @override
  Future<void> init() async {}

  @override
  Future<void> checkInitialized() async {}

  @override
  Future<Map<String, DateTime?>> calculateRiseSetTransit({
    required HeavenlyBody body,
    required DateTime date,
    required double lat,
    required double long,
    String? starName,
  }) async {
    return <String, DateTime?>{
      'rise': date.add(const Duration(hours: 6)),
      'set': date.add(const Duration(hours: 18)),
      'transit': date.add(const Duration(hours: 12)),
    };
  }

  @override
  Future<List<GraphPoint>> calculateAltitudeTrajectory({
    required HeavenlyBody body,
    required DateTime startTime,
    required double lat,
    required double long,
    Duration duration = const Duration(hours: 12),
  }) async => <GraphPoint>[];

  @override
  Future<List<GraphPoint>> calculateFixedObjectTrajectory({
    required double ra,
    required double dec,
    required DateTime startTime,
    required double lat,
    required double long,
    Duration duration = const Duration(hours: 12),
  }) async => <GraphPoint>[];

  @override
  Future<List<GraphPoint>> calculateMoonTrajectory({
    required DateTime startTime,
    required double lat,
    required double long,
    Duration duration = const Duration(hours: 12),
  }) async => <GraphPoint>[];

  @override
  Future<double> getMoonPhase(DateTime date) async => 0.5;

  @override
  Future<Map<String, DateTime>> getNightWindow({
    required DateTime date,
    required double lat,
    required double long,
  }) async {
    return <String, DateTime>{
      'start': date.copyWith(hour: 18),
      'end': date.add(const Duration(days: 1)).copyWith(hour: 6),
    };
  }
}

void main() {
  testWidgets('HighlightsFeed displays items when data is available', (WidgetTester tester) async {
    final DateTime now = DateTime.now();
    final List<CelestialPosition> positions = <CelestialPosition>[
      CelestialPosition(
        body: CelestialBody.jupiter,
        name: 'Jupiter',
        time: now,
        altitude: 45,
        azimuth: 180,
        distance: 5,
        magnitude: -2,
      ),
      CelestialPosition(
        body: CelestialBody.venus,
        name: 'Venus',
        time: now,
        altitude: 30,
        azimuth: 90,
        distance: 0.7,
        magnitude: -4,
      ),
      CelestialPosition(
        body: CelestialBody.mars,
        name: 'Mars',
        time: now,
        altitude: 60,
        azimuth: 270,
        distance: 1.5,
        magnitude: 0,
      ),
    ];

    final AstronomyState state = AstronomyState(
      moonPhaseInfo: const MoonPhaseInfo(illumination: 0.5, phaseAngle: 0),
      positions: positions,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          astronomyProvider.overrideWith(() => FakeAstronomyNotifierWith(state)),
          astronomyServiceProvider.overrideWithValue(MockAstronomyService()),
          astrContextProvider.overrideWith(FakeAstrContextNotifier.new),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HighlightsFeed(),
            ),
          ),
        ),
      ),
    );

    // Let the async providers resolve
    await tester.pump();
    await tester.pump();

    expect(find.text("TONIGHT'S HIGHLIGHTS"), findsOneWidget);
    expect(find.byType(GlassPanel), findsNWidgets(3));
    expect(find.text('Venus'), findsOneWidget); // Brightest first
    expect(find.text('Jupiter'), findsOneWidget);
    expect(find.text('Mars'), findsOneWidget);

    // Drain any pending timers
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('HighlightsFeed hides when no highlights available', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          astronomyProvider.overrideWith(FakeAstronomyNotifierEmpty.new),
          astronomyServiceProvider.overrideWithValue(MockAstronomyService()),
          astrContextProvider.overrideWith(FakeAstrContextNotifier.new),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HighlightsFeed(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text("TONIGHT'S HIGHLIGHTS"), findsNothing);
    expect(find.byType(GlassPanel), findsNothing);
  });
}
