import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:astr/features/data_layer/models/zone_cache_entry.dart';
import 'package:astr/features/data_layer/models/zone_data.dart';
import 'package:astr/features/data_layer/repositories/cached_zone_repository.dart';
import 'package:astr/features/data_layer/services/remote_zone_service.dart';

import 'cached_zone_repository_test.mocks.dart';

@GenerateMocks(<Type>[RemoteZoneService, Box])
void main() {
  late MockRemoteZoneService mockRemote;
  late MockBox<ZoneCacheEntry> mockCache;

  setUp(() {
    mockRemote = MockRemoteZoneService();
    mockCache = MockBox<ZoneCacheEntry>();
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Cache hit (no remote or local needed)
  // ──────────────────────────────────────────────────────────────────────────

  group('cache hit', () {
    test('returns cached data without calling remote', () async {
      final ZoneCacheEntry entry = ZoneCacheEntry(
        h3Index: '64',
        bortleClass: 5,
        ratio: 0.5,
        sqm: 20.0,
        fetchedAt: DateTime.now().toUtc(),
      );
      when(mockCache.get(any)).thenReturn(entry);

      final CachedZoneRepository repo = CachedZoneRepository(
        remoteService: mockRemote,
        cacheBox: mockCache,
      );

      final ZoneData result = await repo.getZoneData(BigInt.from(100));

      expect(result.bortleClass, 5);
      expect(result.ratio, closeTo(0.5, 0.001));
      expect(result.sqm, closeTo(20.0, 0.001));
      verifyNever(mockRemote.getZoneData(any));
    });

    test('skips expired cache and fetches from remote', () async {
      final ZoneCacheEntry expiredEntry = ZoneCacheEntry(
        h3Index: '64',
        bortleClass: 5,
        ratio: 0.5,
        sqm: 20.0,
        fetchedAt: DateTime(2020, 1, 1), // expired (>1 year ago)
      );
      when(mockCache.get(any)).thenReturn(expiredEntry);
      when(mockRemote.getZoneData(any)).thenAnswer(
        (_) async => ZoneData(bortleClass: 7, ratio: 1.5, sqm: 18.0),
      );
      when(mockCache.put(any, any)).thenAnswer((_) async => <dynamic, dynamic>{});

      final CachedZoneRepository repo = CachedZoneRepository(
        remoteService: mockRemote,
        cacheBox: mockCache,
      );

      final ZoneData result = await repo.getZoneData(BigInt.from(100));

      expect(result.bortleClass, 7);
      verify(mockRemote.getZoneData(any)).called(1);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Remote fallback (cache miss → remote API)
  // ──────────────────────────────────────────────────────────────────────────

  group('remote fallback', () {
    test('fetches from remote when no local db configured', () async {
      when(mockCache.get(any)).thenReturn(null);
      when(mockRemote.getZoneData(any)).thenAnswer(
        (_) async => ZoneData(bortleClass: 6, ratio: 1.0, sqm: 19.0),
      );
      when(mockCache.put(any, any)).thenAnswer((_) async => <dynamic, dynamic>{});

      final CachedZoneRepository repo = CachedZoneRepository(
        remoteService: mockRemote,
        cacheBox: mockCache,
      );

      final ZoneData result = await repo.getZoneData(BigInt.from(100));

      expect(result.bortleClass, 6);
      verify(mockRemote.getZoneData(any)).called(1);
    });

    test('returns pristine dark sky when remote returns null', () async {
      when(mockCache.get(any)).thenReturn(null);
      when(mockRemote.getZoneData(any)).thenAnswer((_) async => null);

      final CachedZoneRepository repo = CachedZoneRepository(
        remoteService: mockRemote,
        cacheBox: mockCache,
      );

      final ZoneData result = await repo.getZoneData(BigInt.from(100));

      expect(result.bortleClass, 1);
      expect(result.ratio, 0.0);
      expect(result.sqm, 22.0);
    });

    test('returns stale cache when remote fails and stale cache exists', () async {
      final ZoneCacheEntry staleEntry = ZoneCacheEntry(
        h3Index: '64',
        bortleClass: 4,
        ratio: 0.3,
        sqm: 20.5,
        fetchedAt: DateTime(2020, 1, 1), // expired
      );
      when(mockCache.get(any)).thenReturn(staleEntry);
      when(mockRemote.getZoneData(any)).thenAnswer((_) async => null);

      final CachedZoneRepository repo = CachedZoneRepository(
        remoteService: mockRemote,
        cacheBox: mockCache,
      );

      final ZoneData result = await repo.getZoneData(BigInt.from(100));

      // Should use stale cache since remote failed
      expect(result.bortleClass, 4);
      expect(result.ratio, closeTo(0.3, 0.001));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Sync lookup
  // ──────────────────────────────────────────────────────────────────────────

  group('getZoneDataSync', () {
    test('returns cached data when available', () {
      final ZoneCacheEntry entry = ZoneCacheEntry(
        h3Index: '64',
        bortleClass: 5,
        ratio: 0.5,
        sqm: 20.0,
        fetchedAt: DateTime.now().toUtc(),
      );
      when(mockCache.get(any)).thenReturn(entry);

      final CachedZoneRepository repo = CachedZoneRepository(
        remoteService: mockRemote,
        cacheBox: mockCache,
      );

      final ZoneData result = repo.getZoneDataSync(BigInt.from(100));

      expect(result.bortleClass, 5);
    });

    test('returns pristine dark sky when not in cache', () {
      when(mockCache.get(any)).thenReturn(null);

      final CachedZoneRepository repo = CachedZoneRepository(
        remoteService: mockRemote,
        cacheBox: mockCache,
      );

      final ZoneData result = repo.getZoneDataSync(BigInt.from(100));

      expect(result.bortleClass, 1);
      expect(result.sqm, 22.0);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Cache operations
  // ──────────────────────────────────────────────────────────────────────────

  group('cache operations', () {
    test('getCacheStats returns expected shape', () {
      when(mockCache.length).thenReturn(5);
      when(mockCache.keys).thenReturn(<String>['a', 'b', 'c', 'd', 'e']);

      final CachedZoneRepository repo = CachedZoneRepository(
        remoteService: mockRemote,
        cacheBox: mockCache,
      );

      final Map<String, dynamic> stats = repo.getCacheStats();

      expect(stats['totalEntries'], 5);
      expect(stats['keys'], hasLength(5));
    });

    test('clearCache clears the box', () async {
      when(mockCache.clear()).thenAnswer((_) async => 0);

      final CachedZoneRepository repo = CachedZoneRepository(
        remoteService: mockRemote,
        cacheBox: mockCache,
      );

      await repo.clearCache();

      verify(mockCache.clear()).called(1);
    });
  });
}
