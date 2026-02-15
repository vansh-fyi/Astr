import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:astr/core/error/failure.dart';
import 'package:astr/features/dashboard/data/services/weather_background_sync_service.dart';
import 'package:astr/features/dashboard/domain/entities/daily_weather_data.dart';
import 'package:astr/features/dashboard/domain/entities/weather.dart';
import 'package:astr/features/dashboard/domain/repositories/i_weather_repository.dart';
import 'package:astr/features/profile/domain/entities/user_location.dart';
import 'package:astr/features/profile/domain/repositories/i_location_repository.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/dashboard/domain/entities/hourly_forecast.dart';

void main() {
  late WeatherBackgroundSyncService sut;
  late FakeLocationRepository fakeLocationRepo;
  late FakeWeatherRepository fakeWeatherRepo;

  setUp(() {
    fakeLocationRepo = FakeLocationRepository();
    fakeWeatherRepo = FakeWeatherRepository();
    sut = WeatherBackgroundSyncService(
      weatherRepository: fakeWeatherRepo,
      locationRepository: fakeLocationRepo,
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
        _createLocation('loc1', isPinned: false, lastViewed: now),
        _createLocation('loc2', isPinned: false, lastViewed: now),
        _createLocation('loc3', isPinned: false, lastViewed: now),
      ];
      // Fail on second location
      fakeWeatherRepo.failOnCall = 2;
      
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
}) {
  return UserLocation(
    id: name,
    name: name,
    latitude: 37.7749,
    longitude: -122.4194,
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
    
    if (failOnCall == getDailyForecastCallCount) {
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
    return const Right(<HourlyForecast>[]);
  }

  @override
  Future<Either<Failure, Weather>> getWeather(GeoLocation location) async {
    return const Right(Weather(cloudCover: 10.0));
  }
}
