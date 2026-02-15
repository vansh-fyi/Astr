import 'package:astr/features/profile/domain/entities/user_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserLocation', () {
    final testTimestamp = DateTime(2024, 1, 15, 10, 30);
    final testCreatedAt = DateTime(2024, 1, 10, 8, 0);

    late UserLocation testLocation;

    setUp(() {
      testLocation = UserLocation(
        id: 'loc_001',
        name: 'Dark Sky Site',
        latitude: 37.7749,
        longitude: -122.4194,
        h3Index: '882a107283fffff',
        lastViewedTimestamp: testTimestamp,
        isPinned: false,
        createdAt: testCreatedAt,
      );
    });

    group('constructor', () {
      test('creates instance with all required fields', () {
        expect(testLocation.id, 'loc_001');
        expect(testLocation.name, 'Dark Sky Site');
        expect(testLocation.latitude, 37.7749);
        expect(testLocation.longitude, -122.4194);
        expect(testLocation.h3Index, '882a107283fffff');
        expect(testLocation.lastViewedTimestamp, testTimestamp);
        expect(testLocation.isPinned, false);
        expect(testLocation.createdAt, testCreatedAt);
      });

      test('creates pinned location', () {
        final pinnedLocation = UserLocation(
          id: 'loc_002',
          name: 'Favorite Spot',
          latitude: 40.7128,
          longitude: -74.0060,
          h3Index: '882a100d63fffff',
          lastViewedTimestamp: testTimestamp,
          isPinned: true,
          createdAt: testCreatedAt,
        );

        expect(pinnedLocation.isPinned, true);
      });

      test('rejects invalid latitude > 90', () {
        expect(
          () => UserLocation(
            id: 'invalid',
            name: 'Invalid',
            latitude: 95.0,
            longitude: 0.0,
            h3Index: 'test',
            lastViewedTimestamp: testTimestamp,
            isPinned: false,
            createdAt: testCreatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('rejects invalid latitude < -90', () {
        expect(
          () => UserLocation(
            id: 'invalid',
            name: 'Invalid',
            latitude: -95.0,
            longitude: 0.0,
            h3Index: 'test',
            lastViewedTimestamp: testTimestamp,
            isPinned: false,
            createdAt: testCreatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('rejects invalid longitude > 180', () {
        expect(
          () => UserLocation(
            id: 'invalid',
            name: 'Invalid',
            latitude: 0.0,
            longitude: 185.0,
            h3Index: 'test',
            lastViewedTimestamp: testTimestamp,
            isPinned: false,
            createdAt: testCreatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('rejects invalid longitude < -180', () {
        expect(
          () => UserLocation(
            id: 'invalid',
            name: 'Invalid',
            latitude: 0.0,
            longitude: -185.0,
            h3Index: 'test',
            lastViewedTimestamp: testTimestamp,
            isPinned: false,
            createdAt: testCreatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('accepts boundary values for coordinates', () {
        // Latitude boundaries
        final north = UserLocation(
          id: 'north',
          name: 'North Pole',
          latitude: 90.0,
          longitude: 0.0,
          h3Index: 'test',
          lastViewedTimestamp: testTimestamp,
          isPinned: false,
          createdAt: testCreatedAt,
        );
        expect(north.latitude, 90.0);

        final south = UserLocation(
          id: 'south',
          name: 'South Pole',
          latitude: -90.0,
          longitude: 0.0,
          h3Index: 'test',
          lastViewedTimestamp: testTimestamp,
          isPinned: false,
          createdAt: testCreatedAt,
        );
        expect(south.latitude, -90.0);

        // Longitude boundaries
        final east = UserLocation(
          id: 'east',
          name: 'Date Line East',
          latitude: 0.0,
          longitude: 180.0,
          h3Index: 'test',
          lastViewedTimestamp: testTimestamp,
          isPinned: false,
          createdAt: testCreatedAt,
        );
        expect(east.longitude, 180.0);

        final west = UserLocation(
          id: 'west',
          name: 'Date Line West',
          latitude: 0.0,
          longitude: -180.0,
          h3Index: 'test',
          lastViewedTimestamp: testTimestamp,
          isPinned: false,
          createdAt: testCreatedAt,
        );
        expect(west.longitude, -180.0);
      });
    });

    group('copyWith', () {
      test('returns copy with updated name', () {
        final updated = testLocation.copyWith(name: 'New Name');

        expect(updated.id, testLocation.id);
        expect(updated.name, 'New Name');
        expect(updated.latitude, testLocation.latitude);
        expect(updated.longitude, testLocation.longitude);
        expect(updated.h3Index, testLocation.h3Index);
        expect(updated.lastViewedTimestamp, testLocation.lastViewedTimestamp);
        expect(updated.isPinned, testLocation.isPinned);
        expect(updated.createdAt, testLocation.createdAt);
      });

      test('returns copy with updated isPinned', () {
        final updated = testLocation.copyWith(isPinned: true);

        expect(updated.isPinned, true);
        expect(updated.id, testLocation.id);
        expect(updated.name, testLocation.name);
      });

      test('returns copy with updated timestamp', () {
        final newTimestamp = DateTime(2024, 2, 20, 15, 45);
        final updated = testLocation.copyWith(lastViewedTimestamp: newTimestamp);

        expect(updated.lastViewedTimestamp, newTimestamp);
      });

      test('returns copy with updated coordinates', () {
        final updated = testLocation.copyWith(
          latitude: 35.6762,
          longitude: 139.6503,
          h3Index: '882a300000fffff',
        );

        expect(updated.latitude, 35.6762);
        expect(updated.longitude, 139.6503);
        expect(updated.h3Index, '882a300000fffff');
      });

      test('returns unchanged copy when no arguments provided', () {
        final unchanged = testLocation.copyWith();

        expect(unchanged.id, testLocation.id);
        expect(unchanged.name, testLocation.name);
        expect(unchanged.latitude, testLocation.latitude);
        expect(unchanged.longitude, testLocation.longitude);
        expect(unchanged.h3Index, testLocation.h3Index);
        expect(unchanged.lastViewedTimestamp, testLocation.lastViewedTimestamp);
        expect(unchanged.isPinned, testLocation.isPinned);
        expect(unchanged.createdAt, testLocation.createdAt);
      });
    });

    group('toMap', () {
      test('converts entity to map with correct types', () {
        final map = testLocation.toMap();

        expect(map['id'], 'loc_001');
        expect(map['name'], 'Dark Sky Site');
        expect(map['latitude'], 37.7749);
        expect(map['longitude'], -122.4194);
        expect(map['h3Index'], '882a107283fffff');
        expect(map['lastViewedTimestamp'], testTimestamp.millisecondsSinceEpoch);
        expect(map['isPinned'], 0); // SQLite stores bool as int
        expect(map['createdAt'], testCreatedAt.millisecondsSinceEpoch);
      });

      test('converts isPinned true to 1', () {
        final pinnedLocation = testLocation.copyWith(isPinned: true);
        final map = pinnedLocation.toMap();

        expect(map['isPinned'], 1);
      });
    });

    group('fromMap', () {
      test('creates entity from valid map', () {
        final map = {
          'id': 'loc_003',
          'name': 'Mountain Peak',
          'latitude': 39.7392,
          'longitude': -104.9903,
          'h3Index': '882a107283fffff',
          'lastViewedTimestamp': testTimestamp.millisecondsSinceEpoch,
          'isPinned': 0,
          'createdAt': testCreatedAt.millisecondsSinceEpoch,
        };

        final location = UserLocation.fromMap(map);

        expect(location.id, 'loc_003');
        expect(location.name, 'Mountain Peak');
        expect(location.latitude, 39.7392);
        expect(location.longitude, -104.9903);
        expect(location.h3Index, '882a107283fffff');
        expect(location.lastViewedTimestamp.millisecondsSinceEpoch, 
               testTimestamp.millisecondsSinceEpoch);
        expect(location.isPinned, false);
        expect(location.createdAt.millisecondsSinceEpoch, 
               testCreatedAt.millisecondsSinceEpoch);
      });

      test('parses isPinned 1 as true', () {
        final map = {
          'id': 'loc_004',
          'name': 'Pinned Location',
          'latitude': 45.5231,
          'longitude': -122.6765,
          'h3Index': '882a107283fffff',
          'lastViewedTimestamp': testTimestamp.millisecondsSinceEpoch,
          'isPinned': 1,
          'createdAt': testCreatedAt.millisecondsSinceEpoch,
        };

        final location = UserLocation.fromMap(map);

        expect(location.isPinned, true);
      });

      test('handles integer coordinates from SQLite', () {
        final map = {
          'id': 'loc_005',
          'name': 'Integer Coords',
          'latitude': 40, // SQLite might return int
          'longitude': -74,
          'h3Index': '882a107283fffff',
          'lastViewedTimestamp': testTimestamp.millisecondsSinceEpoch,
          'isPinned': 0,
          'createdAt': testCreatedAt.millisecondsSinceEpoch,
        };

        final location = UserLocation.fromMap(map);

        expect(location.latitude, 40.0);
        expect(location.longitude, -74.0);
      });
    });

    group('roundtrip serialization', () {
      test('toMap -> fromMap preserves all data', () {
        final map = testLocation.toMap();
        final restored = UserLocation.fromMap(map);

        expect(restored.id, testLocation.id);
        expect(restored.name, testLocation.name);
        expect(restored.latitude, testLocation.latitude);
        expect(restored.longitude, testLocation.longitude);
        expect(restored.h3Index, testLocation.h3Index);
        expect(restored.lastViewedTimestamp.millisecondsSinceEpoch,
               testLocation.lastViewedTimestamp.millisecondsSinceEpoch);
        expect(restored.isPinned, testLocation.isPinned);
        expect(restored.createdAt.millisecondsSinceEpoch,
               testLocation.createdAt.millisecondsSinceEpoch);
      });

      test('roundtrip with pinned location', () {
        final pinned = testLocation.copyWith(isPinned: true);
        final map = pinned.toMap();
        final restored = UserLocation.fromMap(map);

        expect(restored.isPinned, true);
      });
    });

    group('equality', () {
      test('equal locations with same values', () {
        final location1 = UserLocation(
          id: 'loc_eq',
          name: 'Test',
          latitude: 37.0,
          longitude: -122.0,
          h3Index: '882a107283fffff',
          lastViewedTimestamp: testTimestamp,
          isPinned: false,
          createdAt: testCreatedAt,
        );

        final location2 = UserLocation(
          id: 'loc_eq',
          name: 'Test',
          latitude: 37.0,
          longitude: -122.0,
          h3Index: '882a107283fffff',
          lastViewedTimestamp: testTimestamp,
          isPinned: false,
          createdAt: testCreatedAt,
        );

        expect(location1, equals(location2));
        expect(location1.hashCode, equals(location2.hashCode));
      });

      test('different locations are not equal', () {
        final location1 = testLocation;
        final location2 = testLocation.copyWith(id: 'different_id');

        expect(location1, isNot(equals(location2)));
      });
    });
  });
}
