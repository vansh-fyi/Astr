import 'package:astr/app/router/app_router.dart';
import 'package:astr/core/error/failure.dart';
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
import 'package:astr/features/planner/domain/entities/daily_forecast.dart';
import 'package:astr/features/planner/presentation/providers/planner_provider.dart';
import 'package:astr/features/profile/presentation/providers/settings_provider.dart';
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
}

class MockVisibilityNotifier extends StateNotifier<VisibilityState> implements VisibilityNotifier {
  MockVisibilityNotifier() : super(VisibilityState(lightPollution: LightPollution.unknown()));
  
  @override
  Future<void> refresh() async {}

  @override
  Future<void> fetchData(GeoLocation location) async {}
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
          weatherProvider.overrideWith(MockWeatherNotifier.new),
          astronomyProvider.overrideWith(MockAstronomyNotifier.new),
          astronomyServiceProvider.overrideWithValue(MockAstronomyService()),
          visibilityProvider.overrideWith((StateNotifierProviderRef<VisibilityNotifier, VisibilityState> ref) => MockVisibilityNotifier()),
          bortleProvider.overrideWithValue(BortleScale.class4),
          settingsNotifierProvider.overrideWith(MockSettingsNotifier.new),
          forecastListProvider.overrideWith((FutureProviderRef<List<DailyForecast>> ref) async => <DailyForecast>[
            DailyForecast(
              date: DateTime.now(),
              cloudCoverAvg: 10,
              moonIllumination: 0,
              weatherCode: 0,
              starRating: 5,
            ),
          ]),
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
    
    // Wait for async providers to load
    await tester.pump(const Duration(seconds: 3));

    // Verify Home Screen is displayed by default
    expect(find.text('Clear Skies'), findsOneWidget);
    
    // Verify BottomAppBar and FAB are present
    expect(find.byType(BottomAppBar), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsNothing); // We switched to Ionicons
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Catalog'), findsOneWidget);

    // Navigate to Catalog
    await tester.tap(find.text('Catalog'));
    await tester.pump(const Duration(seconds: 1));
    
    // Verify Catalog Screen is displayed
    expect(find.text('Celestial Catalog'), findsOneWidget);
    // Verify Navigation Bar is still present
    expect(find.byType(BottomAppBar), findsOneWidget);

    // Navigate to Forecast
    await tester.tap(find.text('Forecast'));
    await tester.pump(const Duration(seconds: 1));
    
    // Verify Forecast Screen is displayed (checking for "Today" which is present in the list)
    expect(find.text('Today'), findsOneWidget);

    // Navigate to Profile
    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(seconds: 1));
    
    // Verify Profile Screen is displayed (checking for AppBar title "Profile")
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Profile')), findsOneWidget);
    // Verify Red Mode toggle is present
    expect(find.text('Red Mode (Night Vision)'), findsOneWidget);
  });
}
