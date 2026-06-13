# Testing Patterns

**Analysis Date:** 2026-06-13

## Test Framework

**Runner:**
- `flutter_test` (Flutter SDK) — primary test runner for all unit and widget tests
- Config: No explicit `flutter_test.yaml`; tests discovered via `flutter test`

**Assertion Library:**
- `flutter_test` built-in matchers (`expect`, `find`, `isA`, `closeTo`, `findsOneWidget`)

**Mocking Libraries:**
- `mockito ^5.4.6` — interface mocks via `@GenerateMocks` annotation
- `riverpod_test ^0.1.9` — Riverpod-specific test utilities
- `sqflite_common_ffi ^2.3.0` — in-process SQLite for database tests

**Run Commands:**
```bash
flutter test                          # Run all tests
flutter test test/path/to_test.dart   # Run a specific file
flutter test --coverage               # Run with coverage output
flutter test --reporter expanded      # Verbose output
```

## Test File Organization

**Location:**
- Tests live in `test/` directory, mirroring `lib/` structure
- Feature tests: `test/features/<feature>/...`
- Core tests: `test/core/...`
- App-level tests: `test/app/...`
- Shared helpers: `test/helpers/`

**Naming:**
- Test files: `<subject>_test.dart`
- Generated mock files: `<subject>_test.mocks.dart` (co-located with the test file)
- Helper files: `<subject>_test_helpers.dart` in `test/helpers/`

**Structure:**
```
test/
├── app/
│   └── theme/                        # App-level tests
├── astronomy/                        # Top-level astronomy tests (legacy)
├── core/
│   ├── engine/
│   │   ├── algorithms/               # Pure algorithm tests
│   │   └── database/                 # Database/repository tests
│   ├── services/                     # Service unit tests
│   └── widgets/                      # Core widget tests
├── features/
│   ├── catalog/
│   │   ├── data/repositories/
│   │   ├── data/services/
│   │   ├── domain/services/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   ├── context/
│   ├── dashboard/
│   │   ├── data/
│   │   ├── domain/logic/
│   │   └── presentation/
│   ├── planner/
│   └── profile/
├── helpers/
│   ├── coordinate_validation_test_helpers.dart
│   └── zone_data_test_helpers.dart
└── navigation/
```

## Test Structure

**Suite Organization:**
```dart
// Unit test pattern
void main() {
  late DarknessCalculator calculator;  // Declare late variables

  setUp(() {
    calculator = DarknessCalculator(); // Initialize before each test
  });

  group('DarknessCalculator', () {
    test('should return base MPSAS when moon is below horizon', () {
      // Arrange
      // Act
      final double result = calculator.calculateDarkness(
        baseMPSAS: 21.5,
        moonPhase: 1,
        moonAltitude: -10,
      );
      // Assert
      expect(result, 21.5);
    });
  });

  group('getDarknessLabel', () {
    test('should return Excellent for >= 21.5', () {
      expect(calculator.getDarknessLabel(21.5).$1, 'Excellent');
    });
  });
}
```

**Patterns:**
- `setUp` for fresh object creation before each test
- `setUpAll` for one-time setup (e.g., `provideDummy` for Mockito/Riverpod)
- `tearDown` for container disposal: `container.dispose()`
- Arrange / Act / Assert comments used consistently in provider and repository tests
- `late` keyword for variables initialized in `setUp`
- `const` used for test fixture data where possible: `const GeoLocation tLocation = ...`

## Mocking

**Framework:** `mockito ^5.4.6`

**Code generation setup:**
```dart
@GenerateMocks(<Type>[ILocationService])
void main() { ... }
```
Run `dart run build_runner build` to generate `.mocks.dart` files.

**Interface mock pattern:**
```dart
// Generated: MockILocationService extends Mock implements ILocationService

late MockILocationService mockLocationService;

setUp(() {
  provideDummy<Either<Failure, GeoLocation>>(
    const Right(GeoLocation(latitude: 0, longitude: 0, name: 'Dummy')),
  );
  mockLocationService = MockILocationService();
});

// Stub
when(mockLocationService.getCurrentLocation())
    .thenAnswer((_) async => const Right(location));

// Verify
verify(mockRepository.getObjectById('mars')).called(1);
```

**Fake implementation pattern (preferred for concrete classes):**
```dart
// Fakes extend or implement the real class without code generation
class FakeWeatherRepository implements IWeatherRepository {
  Weather? weatherToReturn;
  Failure? failureToReturn;
  int getWeatherCallCount = 0;

  @override
  Future<Either<Failure, Weather>> getWeather(GeoLocation location) async {
    getWeatherCallCount++;
    if (failureToReturn != null) return Left(failureToReturn!);
    return Right(weatherToReturn!);
  }
}
```

**Fakes over Mocks for concrete datasources:**
```dart
// Subclass the real service and override just the network call
class FakeOpenMeteoWeatherService extends OpenMeteoWeatherService {
  FakeOpenMeteoWeatherService({this.hourlyResponse, this.error}) : super(Dio());
  final Map<String, dynamic>? hourlyResponse;
  final Exception? error;

  @override
  Future<Map<String, dynamic>> getHourlyForecast(GeoLocation location) async {
    if (error != null) throw error!;
    return hourlyResponse!;
  }
}
```

**What to Mock:**
- Interfaces (`ILocationService`, `IWeatherRepository`, `ICatalogRepository`)
- Any dependency that crosses I/O boundaries (network, GPS, file system)

**What NOT to Mock:**
- Pure logic classes (`DarknessCalculator`, `StargazingLogic`, algorithm helpers)
- Domain entities and value objects

## Riverpod Testing

**Pattern: `ProviderContainer` with overrides**
```dart
late ProviderContainer container;

setUp(() {
  TestWidgetsFlutterBinding.ensureInitialized();
  container = ProviderContainer(overrides: <Override>[
    locationServiceProvider.overrideWithValue(mockLocationService),
  ]);
});

tearDown(() {
  container.dispose();
});

test('initial state loads current location', () async {
  // Arrange
  when(mockLocationService.getCurrentLocation())
      .thenAnswer((_) async => const Right(location));

  // Act — await the async provider future
  final AstrContext initialState = await container.read(astrContextProvider.future);

  // Assert
  expect(initialState.location, location);
});
```

**Async provider pattern:**
- Read `provider.future` to await async notifier build: `container.read(astrContextProvider.future)`
- Read `provider` for `AsyncValue<T>` state inspection after updates

## Widget Testing

**Pattern: `testWidgets` with `MaterialApp` wrapper**
```dart
testWidgets('BortleBar displays correct text', (WidgetTester tester) async {
  // arrange
  const LightPollution tLightPollution = LightPollution(...);

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
  expect(find.text('20.49 MPSAS'), findsOneWidget);
});
```

**Test mode flags:**
- Animated/Rive widgets expose a `testMode` flag to disable animations:
  ```dart
  setUp(() {
    AstrRiveAnimation.testMode = true;
  });
  ```

**Flutter binding:**
- `TestWidgetsFlutterBinding.ensureInitialized()` in `setUp` when platform channels are involved
- Platform channel mocking for `path_provider` and similar plugins:
  ```dart
  const MethodChannel('plugins.flutter.io/path_provider')
      .setMockMethodCallHandler((MethodCall methodCall) async => '.');
  ```

## Fixtures and Factories

**Test Data:**
```dart
// Typed const fixtures with descriptive `t` prefix
const GeoLocation tLocation = GeoLocation(latitude: 0, longitude: 0);
const LightPollution tLightPollution = LightPollution(visibilityIndex: 4, ...);

// Mutable test data via factory helper
final testWeather = const Weather(cloudCover: 25.0, temperatureC: 18.5, ...);
```

**Binary fixture helper** (`test/helpers/zone_data_test_helpers.dart`):
```dart
Uint8List createTestZoneBytes({
  required int bortleClass,
  required double ratio,
  required double sqm,
}) { ... }
```

**Location:**
- Shared helpers: `test/helpers/`
- Feature-local fixtures: inline in the test file

## Coverage

**Requirements:** Not explicitly enforced (no coverage thresholds configured in pubspec or CI config found)

**View Coverage:**
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Types

**Unit Tests (majority of suite):**
- Pure logic: `DarknessCalculator`, `StargazingLogic`, algorithm classes
- Repositories with fake/mock dependencies
- Domain services and providers
- Located throughout `test/core/` and `test/features/`

**Widget Tests:**
- Widget rendering and finding text/widget types
- Interaction testing (tap, scroll) via `WidgetTester`
- Located in `test/features/.../presentation/widgets/` and `test/core/widgets/`

**Integration Tests:**
- `test/core/engine/database/integration_test.dart` — database layer integration
- Uses real `sqflite_common_ffi` in-process for SQLite

**Manual/Script Tests (non-`flutter test` runnable):**
- `test/manual_test_map.dart`, `test/verify_new_map.dart`, `test/check_palette.dart`
- These are standalone Dart scripts, not automated test suites

## Common Patterns

**Async Testing:**
```dart
test('async operation completes', () async {
  final Either<Failure, List<DailyWeatherData>> result =
      await repository.getDailyForecast(tLocation);
  expect(result, isA<Right<Failure, List<DailyWeatherData>>>());
  result.fold(
    (Failure l) => fail('Should not return failure'),
    (List<DailyWeatherData> r) => expect(r.length, 7),
  );
});
```

**Either Error Testing:**
```dart
test('should return ServerFailure on exception', () async {
  final FakeOpenMeteoWeatherService fakeService =
      FakeOpenMeteoWeatherService(error: Exception('API Error'));
  repository = WeatherRepositoryImpl(fakeService);

  final Either<Failure, List<DailyWeatherData>> result =
      await repository.getDailyForecast(tLocation);

  expect(result, isA<Left<Failure, List<DailyWeatherData>>>());
});
```

**Floating-point Assertions:**
```dart
expect(result, closeTo(18.0, 0.01));  // Use closeTo for doubles
```

**State verification after Riverpod update:**
```dart
container.read(astrContextProvider.notifier).updateDate(newDate);

final AsyncValue<AstrContext> state = container.read(astrContextProvider);
expect(state.value!.selectedDate, newDate);
```

---

*Testing analysis: 2026-06-13*
