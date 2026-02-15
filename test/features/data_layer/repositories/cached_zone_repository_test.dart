import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;

import 'package:astr/features/data_layer/models/zone_cache_entry.dart';
import 'package:astr/features/data_layer/models/zone_data.dart';
import 'package:astr/features/data_layer/repositories/cached_zone_repository.dart';
import 'package:astr/features/data_layer/services/remote_zone_service.dart';

import 'cached_zone_repository_test.mocks.dart';

@GenerateMocks(<Type>[RemoteZoneService, Box])
void main() {
  late MockRemoteZoneService mockRemote;
  late MockBox<ZoneCacheEntry> mockCache;
  late Directory tempDir;
  late String testDbPath;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cached_zone_repo_test_');
    testDbPath = p.join(tempDir.path, 'test_zones.db');

    // Create a valid zones.db file for local fallback tests
    // Format: [Header: 16 bytes][Records: 2 × 20 bytes]
    final int totalSize = 16 + (2 * 20);
    final Uint8List data = Uint8List(totalSize);
    final ByteData buffer = data.buffer.asByteData();

    // Header
    data.setAll(0, 'ASTR'.codeUnits); // Magic
    buffer.setUint32(4, 1, Endian.little); // Version
    buffer.setUint64(8, 2, Endian.little); // Record count

    // Record 0: h3=100, Bortle=5, Ratio=0.5, SQM=20.0
    buffer.setUint64(16, 100, Endian.little);
    data[24] = 5;
    buffer.setFloat32(25, 0.5, Endian.little);
    buffer.setFloat32(29, 20.0, Endian.little);

    // Record 1: h3=500, Bortle=3, Ratio=0.2, SQM=21.5
    buffer.setUint64(36, 500, Endian.little);
    data[44] = 3;
    buffer.setFloat32(45, 0.2, Endian.little);
    buffer.setFloat32(49, 21.5, Endian.little);

    await File(testDbPath).writeAsBytes(data);
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

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
  // Local-first fallback (new feature)
  // ──────────────────────────────────────────────────────────────────────────

  group('local-first fallback', () {
    test('uses local zones.db when available and cache misses', () async {
      when(mockCache.get(any)).thenReturn(null);
      when(mockCache.put(any, any)).thenAnswer((_) async => <dynamic, dynamic>{});

      final CachedZoneRepository repo = CachedZoneRepository(
        remoteService: mockRemote,
        cacheBox: mockCache,
        localDbPath: testDbPath,
      );

      final ZoneData result = await repo.getZoneData(BigInt.from(100));

      expect(result.bortleClass, 5);
      expect(result.ratio, closeTo(0.5, 0.001));
      expect(result.sqm, closeTo(20.0, 0.001));
      // Should NOT call remote since local succeeded
      verifyNever(mockRemote.getZoneData(any));
    });

    test('returns pristine dark sky when h3 not in local db', () async {
      when(mockCache.get(any)).thenReturn(null);

      final CachedZoneRepository repo = CachedZoneRepository(
        remoteService: mockRemote,
        cacheBox: mockCache,
        localDbPath: testDbPath,
      );

      // h3=999 is NOT in our test db (only 100 and 500)
      final ZoneData result = await repo.getZoneData(BigInt.from(999));

      expect(result.bortleClass, 1); // pristine dark sky
      expect(result.ratio, 0.0);
      expect(result.sqm, 22.0);
      verifyNever(mockRemote.getZoneData(any));
    });

    test('falls back to remote when local db file does not exist', () async {
      when(mockCache.get(any)).thenReturn(null);
      when(mockRemote.getZoneData(any)).thenAnswer(
        (_) async => ZoneData(bortleClass: 4, ratio: 0.3, sqm: 20.5),
      );
      when(mockCache.put(any, any)).thenAnswer((_) async => <dynamic, dynamic>{});

      final CachedZoneRepository repo = CachedZoneRepository(
        remoteService: mockRemote,
        cacheBox: mockCache,
        localDbPath: '/nonexistent/path/zones.db',
      );

      final ZoneData result = await repo.getZoneData(BigInt.from(100));

      expect(result.bortleClass, 4);
      verify(mockRemote.getZoneData(any)).called(1);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Remote fallback (no local db path set)
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
