import 'package:astr/core/error/failure.dart';
import 'package:astr/features/astronomy/domain/entities/astronomy_state.dart';
import 'package:astr/features/astronomy/domain/entities/moon_phase_info.dart';
import 'package:astr/features/astronomy/presentation/providers/astronomy_provider.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_body.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_position.dart';
import 'package:astr/features/context/domain/entities/astr_context.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:astr/features/dashboard/domain/entities/bortle_scale.dart';
import 'package:astr/features/dashboard/domain/entities/light_pollution.dart';
import 'package:astr/features/dashboard/domain/entities/weather.dart';
import 'package:astr/features/dashboard/domain/repositories/i_light_pollution_service.dart';
import 'package:astr/features/dashboard/presentation/home_screen.dart';
import 'package:astr/features/dashboard/presentation/providers/bortle_provider.dart';
import 'package:astr/features/dashboard/presentation/providers/visibility_provider.dart';
import 'package:astr/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:astr/features/splash/domain/entities/launch_result.dart';
import 'package:astr/features/splash/presentation/providers/smart_launch_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';

/// Shared provider overrides for HomeScreen tests.
///
/// HomeScreen depends on several providers that require Hive or native FFI.
/// These overrides provide test-safe mocks:
/// - visibilityProvider: avoids Hive (CachedZoneRepository -> zoneCacheBoxProvider)
/// - launchResultProvider: avoids native FFI (SmartLaunchController -> H3Service)
List<Override> _homeScreenOverrides(DateTime date) => <Override>[
  weatherProvider.overrideWith(FakeWeatherNotifier.new),
  astronomyProvider.overrideWith(FakeAstronomyNotifier.new),
  bortleProvider.overrideWithValue(BortleScale.class4),
  astrContextProvider.overrideWith(() => FakeAstrContextNotifier(date)),
  visibilityProvider.overrideWith(
    (Ref ref) => FakeVisibilityNotifier(),
  ),
  launchResultProvider.overrideWith(
    (Ref ref) async => const LaunchTimeout(),
  ),
];

void main() {
  setUp(() {
    // Ignore overflow errors for these tests as we are verifying logic/presence, not layout
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception is FlutterError &&
          (details.exception as FlutterError).message.contains('overflowed')) {
        return;
      }
      FlutterError.presentError(details);
    };
  });

  testWidgets('HomeScreen shows banner for future date', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final DateTime futureDate = DateTime.now().add(const Duration(days: 3));

    await tester.pumpWidget(
      ProviderScope(
        overrides: _homeScreenOverrides(futureDate),
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Use fixed duration pump to handle animations safely without timeout
    await tester.pump(const Duration(seconds: 2));

    // Verify Banner
    expect(find.textContaining('Viewing Future Data'), findsOneWidget);

    // Verify Date Text (instead of "Tonight")
    expect(find.textContaining(DateFormat('MMM d').format(futureDate)), findsOneWidget);
    expect(find.text('Tonight'), findsNothing);

    // Drain the timer (3s total, we waited 2s, wait 2s more)
    await tester.pump(const Duration(seconds: 2));

    // Force disposal
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('HomeScreen does NOT show banner for today', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final DateTime today = DateTime.now();

    await tester.pumpWidget(
      ProviderScope(
        overrides: _homeScreenOverrides(today),
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 2));

    // Verify Banner is absent
    expect(find.text('Viewing Future Data'), findsNothing);

    // Drain any timers (flutter_animate uses zero-duration timers)
    await tester.pump(const Duration(seconds: 5));

    // Force disposal to clean up timers
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('HomeScreen uses pure OLED black background (Story 4.2 - NFR-09)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final DateTime today = DateTime.now();

    await tester.pumpWidget(
      ProviderScope(
        overrides: _homeScreenOverrides(today),
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 2));

    // Verify Scaffold uses pure OLED black (#000000) for battery savings
    final Scaffold scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, equals(const Color(0xFF000000)));
    expect(scaffold.backgroundColor!.red, equals(0));
    expect(scaffold.backgroundColor!.green, equals(0));
    expect(scaffold.backgroundColor!.blue, equals(0));

    // Drain any remaining timers (banner timer is 3s total)
    await tester.pump(const Duration(seconds: 2));

    // Force disposal to clean up timers
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}

class FakeAstrContextNotifier extends AstrContextNotifier {
  FakeAstrContextNotifier(this._date);
  final DateTime _date;

  @override
  Future<AstrContext> build() async {
    return AstrContext(
      selectedDate: _date,
      location: const GeoLocation(latitude: 0, longitude: 0, name: 'Test'),
    );
  }
}

class FakeWeatherNotifier extends WeatherNotifier {
  @override
  Future<Weather> build() async {
    return const Weather(cloudCover: 10);
  }
}

class FakeAstronomyNotifier extends AstronomyNotifier {
  @override
  Future<AstronomyState> build() async {
    return AstronomyState(
      moonPhaseInfo: const MoonPhaseInfo(illumination: 0.5, phaseAngle: 0),
      positions: <CelestialPosition>[
        CelestialPosition(
          body: CelestialBody.moon,
          name: 'Moon',
          time: DateTime.now(),
          altitude: 10,
          azimuth: 10,
          distance: 1,
          magnitude: -12,
        ),
      ],
    );
  }
}

class FakeVisibilityNotifier extends VisibilityNotifier {
  FakeVisibilityNotifier() : super(MockLightPollutionService());
}

class MockLightPollutionService implements ILightPollutionService {
  @override
  Future<Either<Failure, LightPollution>> getLightPollution(GeoLocation location) async {
    return Right(LightPollution.unknown());
  }
}
