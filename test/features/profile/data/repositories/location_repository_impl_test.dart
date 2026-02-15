import 'package:astr/core/error/failure.dart';
import 'package:astr/core/engine/models/result.dart';
import 'package:astr/features/data_layer/services/h3_service.dart';
import 'package:astr/features/profile/data/datasources/location_database_service.dart';
import 'package:astr/features/profile/data/repositories/location_repository_impl.dart';
import 'package:astr/features/profile/domain/entities/user_location.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'location_repository_impl_test.mocks.dart';

@GenerateMocks([LocationDatabaseService, H3Service])
void main() {
  // Provide dummy values for Result types and BigInt that mockito can't generate
  setUpAll(() {
    provideDummy<Result<List<Map<String, dynamic>>>>(
      Result.success(<Map<String, dynamic>>[]),
    );
    provideDummy<Result<int>>(Result.success(0));
    provideDummy<Result<void>>(Result.success(null));
    provideDummy<BigInt>(BigInt.zero);
  });

  late LocationRepositoryImpl repository;
  late MockLocationDatabaseService mockDatabaseService;
  late MockH3Service mockH3Service;

  final testCreatedAt = DateTime(2024, 1, 10, 8, 0);
  final testViewed = DateTime(2024, 1, 15, 10, 30);

  UserLocation createTestLocation({
    String id = 'loc_001',
    String name = 'Test Location',
    double latitude = 37.7749,
    double longitude = -122.4194,
    String h3Index = '882a107283fffff',
    DateTime? lastViewedTimestamp,
    bool isPinned = false,
    DateTime? createdAt,
  }) {
    return UserLocation(
      id: id,
      name: name,
      latitude: latitude,
      longitude: longitude,
      h3Index: h3Index,
      lastViewedTimestamp: lastViewedTimestamp ?? testViewed,
      isPinned: isPinned,
      createdAt: createdAt ?? testCreatedAt,
    );
  }

  Map<String, dynamic> locationToDbMap(UserLocation location) {
    return {
      'id': location.id,
      'name': location.name,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'h3Index': location.h3Index,
      'lastViewedTimestamp': location.lastViewedTimestamp.millisecondsSinceEpoch,
      'isPinned': location.isPinned ? 1 : 0,
      'createdAt': location.createdAt.millisecondsSinceEpoch,
    };
  }

  setUp(() {
    mockDatabaseService = MockLocationDatabaseService();
    mockH3Service = MockH3Service();
    repository = LocationRepositoryImpl(mockDatabaseService, mockH3Service);
  });

  group('LocationRepositoryImpl', () {
    group('getAllLocations', () {
      test('returns list of locations on success', () async {
        final loc1 = createTestLocation(id: 'loc_001', name: 'First');
        final loc2 = createTestLocation(id: 'loc_002', name: 'Second');

        when(mockDatabaseService.query(
          orderBy: anyNamed('orderBy'),
        )).thenAnswer((_) async => Result.success([
              locationToDbMap(loc1),
              locationToDbMap(loc2),
            ]));

        final result = await repository.getAllLocations();

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (locations) {
            expect(locations.length, 2);
            expect(locations[0].id, 'loc_001');
            expect(locations[1].id, 'loc_002');
          },
        );
      });

      test('returns empty list when no locations exist', () async {
        when(mockDatabaseService.query(
          orderBy: anyNamed('orderBy'),
        )).thenAnswer((_) async => Result.success([]));

        final result = await repository.getAllLocations();

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (locations) => expect(locations, isEmpty),
        );
      });

      test('returns failure on database error', () async {
        when(mockDatabaseService.query(
          orderBy: anyNamed('orderBy'),
        )).thenAnswer((_) async => Result.failure(
              const DatabaseFailure('Query failed'),
            ));

        final result = await repository.getAllLocations();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('getLocationById', () {
      test('returns location when found', () async {
        final location = createTestLocation(id: 'loc_find_me');

        when(mockDatabaseService.query(
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => Result.success([locationToDbMap(location)]));

        final result = await repository.getLocationById('loc_find_me');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (found) => expect(found.id, 'loc_find_me'),
        );
      });

      test('returns failure when location not found', () async {
        when(mockDatabaseService.query(
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => Result.success([]));

        final result = await repository.getLocationById('non_existent');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure.message, contains('not found')),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('saveLocation', () {
      test('saves location with auto-computed H3 index', () async {
        final location = createTestLocation(
          latitude: 37.7749,
          longitude: -122.4194,
          h3Index: 'ignored_value', // Should be recomputed
        );

        // Mock H3Service to return a test H3 index
        final testH3Index = BigInt.parse('617700169958293503');
        when(mockH3Service.latLonToH3(37.7749, -122.4194, 8))
            .thenReturn(testH3Index);

        when(mockDatabaseService.insert(any))
            .thenAnswer((_) async => Result.success(null));

        final result = await repository.saveLocation(location);

        expect(result.isRight(), true);

        // Verify H3 service was called
        verify(mockH3Service.latLonToH3(37.7749, -122.4194, 8)).called(1);

        // Verify insert was called with computed H3 index (in hex format)
        final capturedMap = verify(mockDatabaseService.insert(captureAny))
            .captured
            .single as Map<String, dynamic>;

        expect(capturedMap['h3Index'], testH3Index.toRadixString(16));
        expect(capturedMap['latitude'], 37.7749);
        expect(capturedMap['longitude'], -122.4194);
      });

      // Note: Invalid coordinate test removed - entity constructor now validates
      // coordinates via assertions, preventing invalid UserLocation creation entirely.

      test('returns failure on insert error', () async {
        final location = createTestLocation();

        when(mockH3Service.latLonToH3(any, any, any))
            .thenReturn(BigInt.parse('123456789'));

        when(mockDatabaseService.insert(any)).thenAnswer(
            (_) async => Result.failure(const DatabaseFailure('Insert failed')));

        final result = await repository.saveLocation(location);

        expect(result.isLeft(), true);
      });
    });

    group('deleteLocation', () {
      test('deletes location successfully', () async {
        when(mockDatabaseService.delete(
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        )).thenAnswer((_) async => Result.success(1));

        final result = await repository.deleteLocation('loc_001');

        expect(result.isRight(), true);
        verify(mockDatabaseService.delete(
          where: '${LocationColumns.id} = ?',
          whereArgs: ['loc_001'],
        )).called(1);
      });

      test('succeeds even when location does not exist (idempotent)', () async {
        when(mockDatabaseService.delete(
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        )).thenAnswer((_) async => Result.success(0)); // 0 rows deleted

        final result = await repository.deleteLocation('non_existent');

        expect(result.isRight(), true);
      });
    });

    group('getPinnedLocations', () {
      test('returns only pinned locations', () async {
        final pinnedLoc = createTestLocation(id: 'pinned_1', isPinned: true);

        when(mockDatabaseService.query(
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
          orderBy: anyNamed('orderBy'),
        )).thenAnswer((_) async => Result.success([locationToDbMap(pinnedLoc)]));

        final result = await repository.getPinnedLocations();

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (locations) {
            expect(locations.length, 1);
            expect(locations[0].isPinned, true);
          },
        );

        verify(mockDatabaseService.query(
          where: '${LocationColumns.isPinned} = ?',
          whereArgs: [1],
          orderBy: anyNamed('orderBy'),
        )).called(1);
      });
    });

    group('getStaleLocations', () {
      test('returns locations older than staleDays that are not pinned', () async {
        final staleDate = DateTime.now().subtract(const Duration(days: 15));
        final staleLoc = createTestLocation(
          id: 'stale_1',
          lastViewedTimestamp: staleDate,
          isPinned: false,
        );

        when(mockDatabaseService.query(
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
          orderBy: anyNamed('orderBy'),
        )).thenAnswer((_) async => Result.success([locationToDbMap(staleLoc)]));

        final result = await repository.getStaleLocations(staleDays: 10);

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (locations) {
            expect(locations.length, 1);
            expect(locations[0].id, 'stale_1');
          },
        );

        // Verify correct WHERE clause structure
        verify(mockDatabaseService.query(
          where:
              '${LocationColumns.isPinned} = ? AND ${LocationColumns.lastViewedTimestamp} < ?',
          whereArgs: argThat(
            allOf(
              isA<List>(),
              hasLength(2),
              contains(0), // isPinned = 0 (false)
            ),
            named: 'whereArgs',
          ),
          orderBy: anyNamed('orderBy'),
        )).called(1);
      });

      test('returns empty list when no stale locations', () async {
        when(mockDatabaseService.query(
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
          orderBy: anyNamed('orderBy'),
        )).thenAnswer((_) async => Result.success([]));

        final result = await repository.getStaleLocations();

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (locations) => expect(locations, isEmpty),
        );
      });
    });

    group('updateLastViewed', () {
      test('updates timestamp for existing location', () async {
        when(mockDatabaseService.update(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        )).thenAnswer((_) async => Result.success(1));

        final result = await repository.updateLastViewed('loc_001');

        expect(result.isRight(), true);
        verify(mockDatabaseService.update(
          argThat(containsPair('lastViewedTimestamp', isA<int>())),
          where: '${LocationColumns.id} = ?',
          whereArgs: ['loc_001'],
        )).called(1);
      });

      test('returns failure when location not found', () async {
        when(mockDatabaseService.update(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        )).thenAnswer((_) async => Result.success(0)); // 0 rows updated

        final result = await repository.updateLastViewed('non_existent');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure.message, contains('not found')),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('togglePinned', () {
      test('toggles from unpinned to pinned', () async {
        final unpinnedLoc = createTestLocation(id: 'loc_toggle', isPinned: false);

        // First call: getLocationById
        when(mockDatabaseService.query(
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => Result.success([locationToDbMap(unpinnedLoc)]));

        // Second call: update
        when(mockDatabaseService.update(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        )).thenAnswer((_) async => Result.success(1));

        final result = await repository.togglePinned('loc_toggle');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (newPinnedState) => expect(newPinnedState, true),
        );

        verify(mockDatabaseService.update(
          {'isPinned': 1},
          where: '${LocationColumns.id} = ?',
          whereArgs: ['loc_toggle'],
        )).called(1);
      });

      test('toggles from pinned to unpinned', () async {
        final pinnedLoc = createTestLocation(id: 'loc_toggle', isPinned: true);

        when(mockDatabaseService.query(
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => Result.success([locationToDbMap(pinnedLoc)]));

        when(mockDatabaseService.update(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        )).thenAnswer((_) async => Result.success(1));

        final result = await repository.togglePinned('loc_toggle');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (newPinnedState) => expect(newPinnedState, false),
        );
      });

      test('returns failure when location not found', () async {
        when(mockDatabaseService.query(
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => Result.success([]));

        final result = await repository.togglePinned('non_existent');

        expect(result.isLeft(), true);
      });
    });
  });
}
