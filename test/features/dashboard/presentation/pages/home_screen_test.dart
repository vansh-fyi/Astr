import 'package:astr/features/astronomy/domain/entities/astronomy_state.dart';
import 'package:astr/features/astronomy/domain/entities/moon_phase_info.dart';
import 'package:astr/features/astronomy/presentation/providers/astronomy_provider.dart';
import 'package:astr/features/context/domain/entities/astr_context.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:astr/features/dashboard/domain/entities/bortle_scale.dart';
import 'package:astr/features/dashboard/domain/entities/weather.dart';
import 'package:astr/features/dashboard/presentation/home_screen.dart';
import 'package:astr/features/dashboard/presentation/providers/bortle_provider.dart';
import 'package:astr/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

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
        overrides: <Override>[
          weatherProvider.overrideWith(FakeWeatherNotifier.new),
          astronomyProvider.overrideWith(FakeAstronomyNotifier.new),
          bortleProvider.overrideWithValue(BortleScale.class4),
          astrContextProvider.overrideWith(() => FakeAstrContextNotifier(futureDate)),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Use fixed duration pump to handle animations safely without timeout
    await tester.pump(const Duration(seconds: 2));

    // Verify Banner
    expect(find.text('Viewing Future Data'), findsOneWidget);
    
    // Verify Date Text (instead of "Tonight")
    expect(find.text(DateFormat('MMM d').format(futureDate)), findsOneWidget);
    expect(find.text('Tonight'), findsNothing);

    // Force disposal to clean up timers
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
        overrides: <Override>[
          weatherProvider.overrideWith(FakeWeatherNotifier.new),
          astronomyProvider.overrideWith(FakeAstronomyNotifier.new),
          bortleProvider.overrideWithValue(BortleScale.class4),
          astrContextProvider.overrideWith(() => FakeAstrContextNotifier(today)),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 2));

    // Verify Banner is absent
    expect(find.text('Viewing Future Data'), findsNothing);
    
    // Verify "Tonight" text
    expect(find.text('Tonight'), findsOneWidget);

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
    return const AstronomyState(
      moonPhaseInfo: MoonPhaseInfo(illumination: 0.5, phaseAngle: 0),
    );
  }
}
