import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:astr/core/error/failure.dart';
import 'package:astr/features/dashboard/data/services/weather_background_sync_service.dart';
import 'package:astr/features/dashboard/domain/entities/daily_weather_data.dart';
import 'package:astr/features/dashboard/domain/entities/weather.dart';
import 'package:astr/features/dashboard/domain/repositories/i_weather_repository.dart';
import 'package:astr/features/profile/domain/entities/user_location.dart';
import 'package:astr/features/profile/domain/repositories/i_location_repository.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/dashboard/domain/entities/hourly_forecast.dart';
import 'package:astr/features/data_layer/repositories/cached_zone_repository.dart';
import 'package:astr/features/data_layer/services/h3_service.dart';

class MockCachedZoneRepository extends Mock implements CachedZoneRepository {}
class MockH3Service extends Mock implements H3Service {}

void main() {
  late WeatherBackgroundSyncService sut;
  late FakeLocationRepository fakeLocationRepo;
  late FakeWeatherRepository fakeWeatherRepo;
  late MockCachedZoneRepository mockZoneRepository;
  late MockH3Service mockH3Service;

  setUpAll(() {
    registerFallbackValue(BigInt.from(0));
  });

  setUp(() {
    fakeLocationRepo = FakeLocationRepository();
    fakeWeatherRepo = FakeWeatherRepository();
    mockZoneRepository = MockCachedZoneRepository();
    mockH3Service = MockH3Service();

    // Default stubs for zone data fetching in background sync
    when(() => mockH3Service.latLonToH3(any(), any(), any()))
        .thenReturn(BigInt.from(0));
    when(() => mockZoneRepository.getZoneData(any()))
        .thenAnswer((_) async => CachedZoneRepository.pristineDarkSky);

    sut = WeatherBackgroundSyncService(
      weatherRepository: fakeWeatherRepo,
      locationRepository: fakeLocationRepo,
      zoneRepository: mockZoneRepository,
      h3Service: mockH3Service,
    );
  });

  group('WeatherBackgroundSyncService', () {
    test('syncActiveLocations returns 0 for empty location list', () async {
      fakeLocationRepo.locations = <UserLocation>[];
      
      final int result = await sut.syncActiveLocations();
      
      expect(result, 0);
    });

    test('syncActiveLocations syncs all non-stale locations', () async {
      final now = DateTime.now();
      fakeLocationRepo.locations = <UserLocation>[
        _createLocation('loc1', isPinned: false, lastViewed: now), // Active
        _createLocation('loc2', isPinned: false, lastViewed: now.subtract(const Duration(days: 5))), // Active
      ];
      
      final int result = await sut.syncActiveLocations();
      
      expect(result, 2);
      expect(fakeWeatherRepo.getDailyForecastCallCount, 2);
    });

    test('syncActiveLocations skips stale locations', () async {
      final now = DateTime.now();
      fakeLocationRepo.locations = <UserLocation>[
        _createLocation('active', isPinned: false, lastViewed: now),
        _createLocation('stale', isPinned: false, lastViewed: now.subtract(const Duration(days: 15))), // Stale (>11 days)
      ];
      
      final int result = await sut.syncActiveLocations();
      
      expect(result, 1); // Only active synced
      expect(fakeWeatherRepo.getDailyForecastCallCount, 1);
    });

    test('syncActiveLocations syncs pinned locations even if stale', () async {
      final now = DateTime.now();
      fakeLocationRepo.locations = <UserLocation>[
        _createLocation('pinnedStale', isPinned: true, lastViewed: now.subtract(const Duration(days: 30))),
      ];
      
      final int result = await sut.syncActiveLocations();
      
      expect(result, 1); // Pinned bypasses staleness
      expect(fakeWeatherRepo.getDailyForecastCallCount, 1);
    });

    test('syncActiveLocations handles partial network failure', () async {
      final now = DateTime.now();
      fakeLocationRepo.locations = <UserLocation>[
        _createLocation('loc1', isPinned: false, lastViewed: now, latitude: 10.0),
        _createLocation('loc2', isPinned: false, lastViewed: now, latitude: 20.0),
        _createLocation('loc3', isPinned: false, lastViewed: now, latitude: 30.0),
      ];
      // Fail on second location
      fakeWeatherRepo.failOnCall = 2;

      // Stub H3 service to return different indexes for different coordinates
      when(() => mockH3Service.latLonToH3(10.0, any(), any())).thenReturn(BigInt.from(1));
      when(() => mockH3Service.latLonToH3(20.0, any(), any())).thenReturn(BigInt.from(2));
      when(() => mockH3Service.latLonToH3(30.0, any(), any())).thenReturn(BigInt.from(3));

      // Stub zone data repository to fail (throw) for loc2
      when(() => mockZoneRepository.getZoneData(BigInt.from(1)))
          .thenAnswer((_) async => CachedZoneRepository.pristineDarkSky);
      when(() => mockZoneRepository.getZoneData(BigInt.from(2)))
          .thenThrow(Exception('Zone fetch failed'));
      when(() => mockZoneRepository.getZoneData(BigInt.from(3)))
          .thenAnswer((_) async => CachedZoneRepository.pristineDarkSky);
      
      final int result = await sut.syncActiveLocations();
      
      expect(result, 2); // 1st and 3rd succeed
      expect(fakeWeatherRepo.getDailyForecastCallCount, 3);
    });

    test('syncActiveLocations returns 0 when location repo fails', () async {
      fakeLocationRepo.shouldFail = true;
      
      final int result = await sut.syncActiveLocations();
      
      expect(result, 0);
    });

    test('syncActiveLocations syncs pinned first', () async {
      final now = DateTime.now();
      fakeLocationRepo.locations = <UserLocation>[
        _createLocation('unpinned1', isPinned: false, lastViewed: now),
        _createLocation('pinned1', isPinned: true, lastViewed: now),
        _createLocation('unpinned2', isPinned: false, lastViewed: now),
      ];
      
      await sut.syncActiveLocations();
      
      // Pinned should be synced first
      expect(fakeWeatherRepo.syncedLocations.first, 'pinned1');
    });

    test('syncPinnedLocationsOnly syncs only pinned', () async {
      final now = DateTime.now();
      fakeLocationRepo.pinnedLocations = <UserLocation>[
        _createLocation('pinned1', isPinned: true, lastViewed: now),
        _createLocation('pinned2', isPinned: true, lastViewed: now),
      ];
      
      final int result = await sut.syncPinnedLocationsOnly();
      
      expect(result, 2);
      expect(fakeWeatherRepo.getDailyForecastCallCount, 2);
    });
  });
}

UserLocation _createLocation(
  String name, {
  required bool isPinned,
  required DateTime lastViewed,
  double latitude = 37.7749,
  double longitude = -122.4194,
}) {
  return UserLocation(
    id: name,
    name: name,
    latitude: latitude,
    longitude: longitude,
    h3Index: 'test_h3',
    lastViewedTimestamp: lastViewed,
    isPinned: isPinned,
    createdAt: DateTime.now(),
  );
}

class FakeLocationRepository implements ILocationRepository {
  List<UserLocation> locations = <UserLocation>[];
  List<UserLocation> pinnedLocations = <UserLocation>[];
  bool shouldFail = false;

  @override
  Future<Either<Failure, List<UserLocation>>> getAllLocations() async {
    if (shouldFail) return Left(ServerFailure('Test failure'));
    return Right(locations);
  }

  @override
  Future<Either<Failure, List<UserLocation>>> getPinnedLocations() async {
    if (shouldFail) return Left(ServerFailure('Test failure'));
    return Right(pinnedLocations);
  }

  @override
  Future<Either<Failure, void>> deleteLocation(String id) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserLocation>> getLocationById(String id) async {
    return Left(CacheFailure('Not implemented'));
  }

  @override
  Future<Either<Failure, List<UserLocation>>> getStaleLocations({int staleDays = 10}) async {
    return const Right(<UserLocation>[]);
  }

  @override
  Future<Either<Failure, void>> saveLocation(UserLocation location) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> togglePinned(String id) async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, void>> updateLastViewed(String id) async {
    return const Right(null);
  }
}

class FakeWeatherRepository implements IWeatherRepository {
  int getDailyForecastCallCount = 0;
  int? failOnCall;
  List<String> syncedLocations = <String>[];

  @override
  Future<Either<Failure, List<DailyWeatherData>>> getDailyForecast(GeoLocation location) async {
    getDailyForecastCallCount++;
    syncedLocations.add(location.name ?? 'unknown');
    
    if (failOnCall == getDailyForecastCallCount || location.name == 'loc2') {
      return Left(ServerFailure('Network failure'));
    }
    
    return Right(<DailyWeatherData>[
      DailyWeatherData(
        date: DateTime.now(),
        weatherCode: 0,
        weather: const Weather(cloudCover: 10.0),
      ),
    ]);
  }

  @override
  Future<Either<Failure, List<HourlyForecast>>> getHourlyForecast(GeoLocation location) async {
    if (location.name == 'loc2') {
      return Left(ServerFailure('Network failure'));
    }
    return const Right(<HourlyForecast>[]);
  }

  @override
  Future<Either<Failure, Weather>> getWeather(GeoLocation location) async {
    if (location.name == 'loc2') {
      return Left(ServerFailure('Network failure'));
    }
    return const Right(Weather(cloudCover: 10.0));
  }
}
