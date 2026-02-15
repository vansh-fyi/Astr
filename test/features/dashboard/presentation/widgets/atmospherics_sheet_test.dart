import 'package:astr/core/widgets/glass_panel.dart';
import 'package:astr/features/astronomy/domain/entities/astronomy_state.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_body.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_position.dart';
import 'package:astr/features/astronomy/domain/entities/moon_phase_info.dart';
import 'package:astr/features/astronomy/presentation/providers/astronomy_provider.dart';
import 'package:astr/features/catalog/domain/entities/celestial_object.dart';
import 'package:astr/features/catalog/domain/entities/celestial_type.dart';
import 'package:astr/features/catalog/domain/repositories/i_catalog_repository.dart';
import 'package:astr/features/catalog/presentation/providers/object_detail_notifier.dart';
import 'package:astr/core/error/failure.dart';
import 'package:fpdart/fpdart.dart';
import 'package:astr/features/dashboard/domain/entities/hourly_forecast.dart';
import 'package:astr/features/dashboard/domain/entities/weather.dart';
import 'package:astr/features/dashboard/presentation/providers/darkness_provider.dart';
import 'package:astr/features/dashboard/presentation/providers/night_window_provider.dart';
import 'package:astr/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:astr/features/dashboard/presentation/widgets/atmospherics_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper to build shared provider overrides for AtmosphericsSheet tests.
List<Override> _buildOverrides(Weather weather) {
  return <Override>[
    weatherProvider.overrideWith(() => MockWeatherNotifier(weather)),
    darknessProvider.overrideWithValue(
      const AsyncValue<DarknessState>.data(
        DarknessState(mpsas: 20.0, label: 'Rural Sky', color: 0xFF4CAF50),
      ),
    ),
    nightWindowProvider.overrideWith((Ref ref) async {
      return <String, DateTime>{
        'start': DateTime(2025, 1, 1, 18, 0),
        'end': DateTime(2025, 1, 2, 6, 0),
      };
    }),
    hourlyForecastProvider.overrideWith((Ref ref) async => <HourlyForecast>[]),
    astronomyProvider.overrideWith(() => MockAstronomyNotifier()),
    objectDetailNotifierProvider.overrideWith(
      (Ref ref, String id) {
        return FakeObjectDetailNotifier();
      },
    ),
  ];
}

void main() {
  testWidgets('AtmosphericsSheet displays Seeing score and label correctly', (WidgetTester tester) async {
    // Set a large screen size to avoid overflow
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;

    // Arrange
    const Weather weather = Weather(
      cloudCover: 10,
      temperatureC: 15,
      humidity: 60,
      windSpeedKph: 5,
      seeingScore: 8,
      seeingLabel: 'Good',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _buildOverrides(weather),
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AtmosphericsSheet()),
          ),
        ),
      ),
    );

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('SEEING'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('15°C'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);

    // Reset view
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('AtmosphericsSheet displays correct color for Excellent Seeing', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;

    const Weather weather = Weather(
      cloudCover: 0,
      seeingScore: 9,
      seeingLabel: 'Excellent',
      temperatureC: 10,
      humidity: 50,
      windSpeedKph: 5,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _buildOverrides(weather),
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AtmosphericsSheet()),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final Finder seeingCardFinder = find.ancestor(
      of: find.text('SEEING'),
      matching: find.byType(GlassPanel),
    );
    final Finder labelFinder = find.descendant(
      of: seeingCardFinder,
      matching: find.text('Excellent'),
    );
    final Text textWidget = tester.widget<Text>(labelFinder);
    // Updated for Red Mode compatibility (Epic 5) - now uses Color(0xFF90EE90) instead of Colors.greenAccent
    expect(textWidget.style?.color, const Color(0xFF90EE90));

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('AtmosphericsSheet displays correct color for Poor Seeing', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;

    const Weather weather = Weather(
      cloudCover: 0,
      seeingScore: 3,
      seeingLabel: 'Poor',
      temperatureC: 10,
      humidity: 50,
      windSpeedKph: 5,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _buildOverrides(weather),
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AtmosphericsSheet()),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final Finder seeingCardFinder = find.ancestor(
      of: find.text('SEEING'),
      matching: find.byType(GlassPanel),
    );
    final Finder labelFinder = find.descendant(
      of: seeingCardFinder,
      matching: find.text('Poor'),
    );
    final Text textWidget = tester.widget<Text>(labelFinder);
    // Updated for Red Mode compatibility (Epic 5) - now uses white with alpha 0.6
    expect(textWidget.style?.color, Colors.white.withValues(alpha: 0.6));

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}

class MockWeatherNotifier extends AsyncNotifier<Weather> implements WeatherNotifier {

  MockWeatherNotifier(this._initialState);
  final Weather _initialState;

  @override
  Future<Weather> build() async {
    return _initialState;
  }

  @override
  Future<void> refresh() async {}
}

class MockAstronomyNotifier extends AsyncNotifier<AstronomyState>
    implements AstronomyNotifier {
  @override
  Future<AstronomyState> build() async {
    return AstronomyState(
      moonPhaseInfo: const MoonPhaseInfo(illumination: 0.5, phaseAngle: 0),
      positions: <CelestialPosition>[
        CelestialPosition(
          body: CelestialBody.moon,
          name: 'Moon',
          time: DateTime.now(),
          altitude: 30,
          azimuth: 180,
          distance: 1,
          magnitude: -12,
        ),
        CelestialPosition(
          body: CelestialBody.sun,
          name: 'Sun',
          time: DateTime.now(),
          altitude: -20,
          azimuth: 0,
          distance: 1,
          magnitude: -26,
        ),
      ],
    );
  }
}

/// Fake ObjectDetailNotifier that extends StateNotifier with
/// the correct type signature for family override.
class FakeObjectDetailNotifier extends ObjectDetailNotifier {
  FakeObjectDetailNotifier()
      : super(
          _FakeCatalogRepository(),
          _FakeRef(),
          '',
        );
}

// Minimal fake implementations to satisfy ObjectDetailNotifier constructor
class _FakeCatalogRepository implements ICatalogRepository {
  @override
  Future<Either<Failure, CelestialObject>> getObjectById(String id) async {
    return const Left(ServerFailure('fake'));
  }

  @override
  Future<Either<Failure, List<CelestialObject>>> getAllObjects() async {
    return const Right(<CelestialObject>[]);
  }

  @override
  Future<Either<Failure, List<CelestialObject>>> getObjectsByType(CelestialType type) async {
    return const Right(<CelestialObject>[]);
  }
}

class _FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
