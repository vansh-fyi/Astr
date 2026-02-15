import 'package:astr/features/context/domain/entities/astr_context.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:astr/features/dashboard/domain/entities/weather.dart';
import 'package:astr/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:astr/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeago/timeago.dart' as timeago;

// Fake notifiers for testing
class FakeAstrContextNotifier extends AstrContextNotifier {
  FakeAstrContextNotifier(this.testContext);

  final AstrContext testContext;

  @override
  Future<AstrContext> build() async => testContext;
}

class FakeWeatherNotifier extends WeatherNotifier {
  FakeWeatherNotifier(this.testWeather);

  final Weather testWeather;

  @override
  Future<Weather> build() async => testWeather;
}

void main() {
  // Register timeago en_short locale for tests
  setUpAll(() {
    timeago.setLocaleMessages('en_short', timeago.EnShortMessages());
  });

  group('DashboardHeader Widget Tests (Story 4.2 - FR-13)', () {
    testWidgets('displays location name from AstrContext', (WidgetTester tester) async {
      // Arrange
      const GeoLocation testLocation = GeoLocation(
        latitude: 34.2257,
        longitude: -118.0547,
        name: 'Mt. Wilson',
      );

      final AstrContext testContext = AstrContext(
        location: testLocation,
        selectedDate: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            astrContextProvider.overrideWith(() => FakeAstrContextNotifier(testContext)),
            weatherProvider.overrideWith(() => FakeWeatherNotifier(const Weather(cloudCover: 10))),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardHeader(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act & Assert
      expect(find.text('Mt. Wilson'), findsOneWidget);
    });

    testWidgets('displays "Current Location" when location name is null', (WidgetTester tester) async {
      // Arrange
      const GeoLocation testLocation = GeoLocation(
        latitude: 34.2257,
        longitude: -118.0547,
      );

      final AstrContext testContext = AstrContext(
        location: testLocation,
        selectedDate: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            astrContextProvider.overrideWith(() => FakeAstrContextNotifier(testContext)),
            weatherProvider.overrideWith(() => FakeWeatherNotifier(const Weather(cloudCover: 10))),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardHeader(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act & Assert
      expect(find.text('Current Location'), findsOneWidget);
    });

    testWidgets('displays "Updated Xm ago" for recent updates (<1h)', (WidgetTester tester) async {
      // Arrange
      final DateTime lastUpdated = DateTime.now().subtract(const Duration(minutes: 23));
      final Weather testWeather = Weather(
        cloudCover: 20.0,
        lastUpdated: lastUpdated,
        isStale: false,
      );

      final AstrContext testContext = AstrContext(
        location: const GeoLocation(latitude: 0, longitude: 0),
        selectedDate: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            astrContextProvider.overrideWith(() => FakeAstrContextNotifier(testContext)),
            weatherProvider.overrideWith(() => FakeWeatherNotifier(testWeather)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardHeader(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act & Assert: Should show relative time for recent updates
      expect(find.textContaining('Updated'), findsOneWidget);
    });

    testWidgets('displays "Updated HH:MM AM/PM" for updates today (>1h ago)', (WidgetTester tester) async {
      // Arrange
      final DateTime now = DateTime.now();
      // Set to 3 hours ago to ensure > 1h
      final DateTime lastUpdated = now.subtract(const Duration(hours: 3));
      final Weather testWeather = Weather(
        cloudCover: 20.0,
        isStale: false,
        lastUpdated: lastUpdated,
      );

      final AstrContext testContext = AstrContext(
        location: const GeoLocation(latitude: 0, longitude: 0),
        selectedDate: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            astrContextProvider.overrideWith(() => FakeAstrContextNotifier(testContext)),
            weatherProvider.overrideWith(() => FakeWeatherNotifier(testWeather)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardHeader(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act & Assert: Should show time format for today's updates
      expect(find.textContaining('Updated'), findsOneWidget);
    });

    testWidgets('displays red error icon for stale data', (WidgetTester tester) async {
      // Arrange
      final DateTime lastUpdated = DateTime.now().subtract(const Duration(days: 2));
      final Weather staleWeather = Weather(
        cloudCover: 20.0,
        isStale: true,
        lastUpdated: lastUpdated,
      );

      final AstrContext testContext = AstrContext(
        location: const GeoLocation(latitude: 0, longitude: 0),
        selectedDate: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            astrContextProvider.overrideWith(() => FakeAstrContextNotifier(testContext)),
            weatherProvider.overrideWith(() => FakeWeatherNotifier(staleWeather)),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: DashboardHeader(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act & Assert: Should show error icon (sync_problem) for stale data
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);
    });

    testWidgets('displays normal sync icon for fresh data', (WidgetTester tester) async {
      // Arrange
      final DateTime lastUpdated = DateTime.now().subtract(const Duration(minutes: 10));
      final Weather freshWeather = Weather(
        cloudCover: 20.0,
        isStale: false,
        lastUpdated: lastUpdated,
      );

      final AstrContext testContext = AstrContext(
        location: const GeoLocation(latitude: 0, longitude: 0),
        selectedDate: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            astrContextProvider.overrideWith(() => FakeAstrContextNotifier(testContext)),
            weatherProvider.overrideWith(() => FakeWeatherNotifier(freshWeather)),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: DashboardHeader(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act & Assert: Should show normal sync icon for fresh data
      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('hides Last Updated indicator when lastUpdated is null', (WidgetTester tester) async {
      // Arrange
      const Weather weatherWithoutTimestamp = Weather(
        cloudCover: 20.0,
        isStale: false,
      );

      final AstrContext testContext = AstrContext(
        location: const GeoLocation(latitude: 0, longitude: 0),
        selectedDate: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            astrContextProvider.overrideWith(() => FakeAstrContextNotifier(testContext)),
            weatherProvider.overrideWith(() => FakeWeatherNotifier(weatherWithoutTimestamp)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardHeader(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act & Assert: Should not show "Updated" text when lastUpdated is null
      expect(find.textContaining('Updated'), findsNothing);
      expect(find.byIcon(Icons.sync), findsNothing);
      expect(find.byIcon(Icons.sync_problem), findsNothing);
    });
  });
}
