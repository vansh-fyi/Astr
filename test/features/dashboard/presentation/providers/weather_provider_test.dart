import 'package:astr/core/error/failure.dart';
import 'package:astr/features/context/domain/entities/astr_context.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:astr/features/dashboard/domain/entities/hourly_forecast.dart';
import 'package:astr/features/dashboard/domain/entities/weather.dart';
import 'package:astr/features/dashboard/domain/repositories/i_weather_repository.dart';
import 'package:astr/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:astr/features/planner/domain/entities/daily_forecast.dart';
import 'package:astr/features/planner/presentation/providers/planner_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'weather_provider_test.mocks.dart';

@GenerateNiceMocks(<MockSpec>[
  MockSpec<IWeatherRepository>(),
])
void main() {
  late MockIWeatherRepository mockWeatherRepository;
  late ProviderContainer container;

  setUp(() {
    provideDummy<Either<Failure, List<HourlyForecast>>>(const Right(<HourlyForecast>[]));
    mockWeatherRepository = MockIWeatherRepository();
    // Provide dummy value for Either<Failure, Weather>
    provideDummy<Either<Failure, Weather>>(const Right(Weather(cloudCover: 0)));
  });

  test('WeatherNotifier fetches current weather when selected date is today', () async {
    // Arrange
    final DateTime today = DateTime.now();
    const GeoLocation location = GeoLocation(latitude: 0, longitude: 0);
    final AstrContext astrContext = AstrContext(selectedDate: today, location: location);
    
    container = ProviderContainer(
      overrides: <Override>[
        astrContextProvider.overrideWith(() => FakeAstrContextNotifier(astrContext)),
        weatherRepositoryProvider.overrideWithValue(mockWeatherRepository),
        // We don't need to override plannerProvider for this test as it shouldn't be used
        // But to be safe, we can override it with a dummy
        forecastListProvider.overrideWith((FutureProviderRef<List<DailyForecast>> ref) async => <DailyForecast>[]),
      ],
    );

    when(mockWeatherRepository.getWeather(any)).thenAnswer((_) async => const Right(Weather(cloudCover: 10)));

    // Act
    // Wait for the dependencies to initialize
    await container.read(astrContextProvider.future);
    // Wait for the provider to initialize
    final Weather weather = await container.read(weatherProvider.future);
    final AsyncValue<Weather> weatherState = container.read(weatherProvider);
    
    // Assert
    expect(weatherState, isA<AsyncData<Weather>>());
    expect(weather.cloudCover, 10);
    verify(mockWeatherRepository.getWeather(location)).called(1);
  });

  test('WeatherNotifier uses planner data when selected date is in future', () async {
    // Arrange
    final DateTime today = DateTime.now();
    final DateTime futureDate = today.add(const Duration(days: 3));
    const GeoLocation location = GeoLocation(latitude: 0, longitude: 0);
    final AstrContext astrContext = AstrContext(selectedDate: futureDate, location: location);

    final DailyForecast forecast = DailyForecast(
      date: futureDate,
      weatherCode: 0,
      cloudCoverAvg: 50,
      moonIllumination: 0,
      starRating: 5,
    );

    container = ProviderContainer(
      overrides: <Override>[
        astrContextProvider.overrideWith(() => FakeAstrContextNotifier(astrContext)),
        forecastListProvider.overrideWith((FutureProviderRef<List<DailyForecast>> ref) async => <DailyForecast>[forecast]),
        weatherRepositoryProvider.overrideWithValue(mockWeatherRepository),
      ],
    );
    
    // Act
    // Wait for the dependencies to initialize
    await container.read(astrContextProvider.future);
    await container.read(forecastListProvider.future);
    
    // Wait for the provider to initialize
    final Weather weather = await container.read(weatherProvider.future);
    final AsyncValue<Weather> weatherState = container.read(weatherProvider);
    
    // Assert
    expect(weatherState, isA<AsyncData<Weather>>());
    expect(weather.cloudCover, 50);
    // Verify we DID NOT call the repository
    verifyNever(mockWeatherRepository.getWeather(any));
  });
}

class FakeAstrContextNotifier extends AsyncNotifier<AstrContext> implements AstrContextNotifier {

  FakeAstrContextNotifier(this.initialContext);
  final AstrContext initialContext;

  @override
  Future<AstrContext> build() async {
    return initialContext;
  }
  
  @override
  Future<void> refreshLocation() async {}
  
  @override
  Future<void> updateLocation(GeoLocation location) async {}
  
  @override
  void updateDate(DateTime date) {}
  
  @override
  Future<AstrContext> _loadInitialContext() async => initialContext;
}


