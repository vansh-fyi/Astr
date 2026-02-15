import 'package:astr/app/router/app_router.dart';
import 'package:astr/core/error/failure.dart';
import 'package:astr/features/context/domain/entities/astr_context.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:astr/core/services/i_location_service.dart';
import 'package:astr/core/services/location_service_provider.dart';
import 'package:astr/core/widgets/astr_rive_animation.dart';
import 'package:astr/features/astronomy/domain/entities/astronomy_state.dart';
import 'package:astr/features/astronomy/domain/entities/moon_phase_info.dart';
import 'package:astr/features/astronomy/domain/services/astronomy_service.dart';
import 'package:astr/features/astronomy/presentation/providers/astronomy_provider.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/dashboard/domain/entities/bortle_scale.dart';
import 'package:astr/features/dashboard/domain/entities/light_pollution.dart';
import 'package:astr/features/dashboard/domain/entities/weather.dart';
import 'package:astr/features/dashboard/presentation/providers/bortle_provider.dart';
import 'package:astr/features/dashboard/presentation/providers/visibility_provider.dart';
import 'package:astr/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:astr/features/dashboard/domain/repositories/i_light_pollution_service.dart';
import 'package:astr/features/planner/domain/entities/daily_forecast.dart';
import 'package:astr/features/planner/presentation/providers/planner_provider.dart';
import 'package:astr/features/profile/presentation/providers/settings_provider.dart';
import 'package:astr/features/profile/presentation/providers/tos_provider.dart';
import 'package:astr/features/splash/domain/entities/launch_result.dart';
import 'package:astr/features/splash/presentation/providers/initialization_provider.dart';
import 'package:astr/features/splash/presentation/providers/smart_launch_provider.dart';
import 'package:astr/features/catalog/domain/entities/graph_point.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/src/router.dart';
import 'package:sweph/sweph.dart';

class MockLocationService implements ILocationService {
  @override
  Future<Either<Failure, GeoLocation>> getCurrentLocation() async {
    return const Right(GeoLocation(latitude: 0, longitude: 0, name: 'Test Loc'));
  }
}

class MockWeatherNotifier extends WeatherNotifier {
  @override
  Future<Weather> build() async => const Weather(cloudCover: 10);
}

class MockAstronomyNotifier extends AstronomyNotifier {
  @override
  Future<AstronomyState> build() async => const AstronomyState(
    moonPhaseInfo: MoonPhaseInfo(illumination: 0.2, phaseAngle: 0),
  );
}

class MockSettingsNotifier extends SettingsNotifier {
  @override
  bool build() => false;
}

class MockAstronomyService implements AstronomyService {
  @override
  Future<void> init() async {}

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
  }) async {
    return List.generate(
      10,
      (int i) => GraphPoint(
        time: startTime.add(Duration(hours: i)),
        value: 45.0,
      ),
    );
  }

  @override
  Future<List<GraphPoint>> calculateFixedObjectTrajectory({
    required double ra,
    required double dec,
    required DateTime startTime,
    required double lat,
    required double long,
    Duration duration = const Duration(hours: 12),
  }) async {
    return List.generate(
      10,
      (int i) => GraphPoint(
        time: startTime.add(Duration(hours: i)),
        value: 30.0,
      ),
    );
  }

  @override
  Future<List<GraphPoint>> calculateMoonTrajectory({
    required DateTime startTime,
    required double lat,
    required double long,
    Duration duration = const Duration(hours: 12),
  }) async {
    return List.generate(
      10,
      (int i) => GraphPoint(
        time: startTime.add(Duration(hours: i)),
        value: 60.0,
      ),
    );
  }

  @override
  Future<void> checkInitialized() async {}

  @override
  Future<double> getMoonPhase(DateTime date) async {
    return 0.5;
  }

  @override
  Future<Map<String, DateTime>> getNightWindow({
    required DateTime date,
    required double lat,
    required double long,
  }) async {
    final DateTime sunset = date.copyWith(hour: 18, minute: 0);
    final DateTime sunrise = date.add(const Duration(days: 1)).copyWith(hour: 6, minute: 0);
    return <String, DateTime>{'start': sunset, 'end': sunrise};
  }
}

class MockVisibilityNotifier extends VisibilityNotifier {
  MockVisibilityNotifier() : super(_MockLPService());
}

class _MockLPService implements ILightPollutionService {
  @override
  Future<Either<Failure, LightPollution>> getLightPollution(GeoLocation location) async {
    return Right(LightPollution.unknown());
  }
}

class MockTosNotifier extends TosNotifier {
  @override
  bool build() => true; // ToS accepted
}

class MockInitializationNotifier extends InitializationNotifier {
  @override
  bool build() => true; // Already initialized
}

void main() {
  setUp(() {
    AstrRiveAnimation.testMode = true;
  });

  tearDown(() {
    AstrRiveAnimation.testMode = false;
  });

  testWidgets('Navigation Shell Test', (WidgetTester tester) async {
    // Build the app with the router
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          locationServiceProvider.overrideWithValue(MockLocationService()),
          astrContextProvider.overrideWith(FakeAstrContextNotifier.new),
          weatherProvider.overrideWith(MockWeatherNotifier.new),
          astronomyProvider.overrideWith(MockAstronomyNotifier.new),
          astronomyServiceProvider.overrideWithValue(MockAstronomyService()),
          visibilityProvider.overrideWith((Ref ref) => MockVisibilityNotifier()),
          bortleProvider.overrideWithValue(BortleScale.class4),
          settingsNotifierProvider.overrideWith(MockSettingsNotifier.new),
          tosNotifierProvider.overrideWith(MockTosNotifier.new),
          initializationNotifierProvider.overrideWith(MockInitializationNotifier.new),
          forecastListProvider.overrideWith((Ref ref) async => <DailyForecast>[
            DailyForecast(
              date: DateTime.now(),
              cloudCoverAvg: 10,
              moonIllumination: 0,
              weatherCode: 0,
              starRating: 5,
            ),
          ]),
          launchResultProvider.overrideWith((Ref ref) async => const LaunchTimeout()),
        ],
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            final GoRouter router = ref.watch(goRouterProvider);
            return MaterialApp.router(
              routerConfig: router,
            );
          },
        ),
      ),
    );

    // Wait for async providers to resolve through multiple pump cycles
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));

    // Verify Home Screen is displayed by default
    expect(find.text('Home'), findsOneWidget);

    // Verify custom nav bar elements are present (app uses custom nav, not BottomAppBar)
    expect(find.byType(FloatingActionButton), findsOneWidget);
    // Nav bar labels from ScaffoldWithNavBar
    expect(find.text('Objects'), findsOneWidget);
    expect(find.text('Forecast'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Navigate to Catalog (label is "Objects" in nav bar)
    await tester.tap(find.text('Objects'));
    await tester.pump(const Duration(seconds: 1));

    // Verify Catalog Screen is displayed
    expect(find.text('Celestial Objects'), findsOneWidget);

    // Navigate to Forecast
    await tester.tap(find.text('Forecast').first);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // Verify Forecast Screen is displayed
    // The header shows 'Forecast' and '7-Day Outlook'
    expect(find.text('7-Day Outlook'), findsOneWidget);

    // Navigate to Settings (label is "Settings" in nav bar)
    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(seconds: 1));

    // Verify Profile Screen is displayed
    expect(find.text('Red Mode'), findsOneWidget);

    // Drain any remaining timers
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}

class FakeAstrContextNotifier extends AstrContextNotifier {
  @override
  Future<AstrContext> build() async {
    return AstrContext(
      selectedDate: DateTime.now(),
      location: const GeoLocation(latitude: 0, longitude: 0, name: 'Tests'),
      isCurrentLocation: true,
    );
  }
}
