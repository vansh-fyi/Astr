import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:astr/features/data_layer/models/zone_data.dart';
import 'package:astr/features/data_layer/services/binary_reader_service.dart';
import 'package:astr/features/data_layer/services/zone_data_service.dart';

void main() {
  late Directory tempDir;
  late String testDbPath;
  late BinaryReaderService binaryReaderService;

  setUpAll(() async {
    // Create temp directory for test files
    tempDir = await Directory.systemTemp.createTemp('zone_data_service_test_');
    testDbPath = p.join(tempDir.path, 'test_zones.db');

    // Create test database file with proper header + sorted records
    // Format: [Header: 16 bytes][Records: 3 × 20 bytes]
    //
    // Header:
    //   Magic: "ASTR" (4 bytes)
    //   Version: 1 (4 bytes, uint32)
    //   Record Count: 3 (8 bytes, uint64)
    //
    // Records (sorted by h3_index):
    //   Record 0: h3=100, Bortle=5, Ratio=0.5, SQM=20.0
    //   Record 1: h3=500, Bortle=3, Ratio=0.2, SQM=21.5
    //   Record 2: h3=1000, Bortle=8, Ratio=3.0, SQM=16.0
    final testFile = File(testDbPath);
    final totalSize = 16 + (3 * 20); // Header + 3 records
    final data = Uint8List(totalSize);
    final buffer = data.buffer.asByteData();

    // Write header
    data.setAll(0, 'ASTR'.codeUnits); // Magic
    buffer.setUint32(4, 1, Endian.little); // Version
    buffer.setUint64(8, 3, Endian.little); // Record count

    // Write Record 0 at offset 16 (h3=100)
    buffer.setUint64(16, 100, Endian.little); // h3_index
    data[24] = 5; // Bortle
    buffer.setFloat32(25, 0.5, Endian.little); // Ratio
    buffer.setFloat32(29, 20.0, Endian.little); // SQM
    // Reserved bytes 33-35 are zeros

    // Write Record 1 at offset 36 (h3=500)
    buffer.setUint64(36, 500, Endian.little);
    data[44] = 3;
    buffer.setFloat32(45, 0.2, Endian.little);
    buffer.setFloat32(49, 21.5, Endian.little);

    // Write Record 2 at offset 56 (h3=1000)
    buffer.setUint64(56, 1000, Endian.little);
    data[64] = 8;
    buffer.setFloat32(65, 3.0, Endian.little);
    buffer.setFloat32(69, 16.0, Endian.little);

    await testFile.writeAsBytes(data);

    binaryReaderService = BinaryReaderService(dbPath: testDbPath);
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  group('ZoneDataService', () {
    group('getZoneData - Binary Search', () {
      test('retrieves correct data for H3 index 100 (first record)', () async {
        final service = ZoneDataService(binaryReader: binaryReaderService);
        final data = await service.getZoneData(BigInt.from(100));

        expect(data.bortleClass, equals(5));
        expect(data.ratio, closeTo(0.5, 0.001));
        expect(data.sqm, closeTo(20.0, 0.001));
      });

      test('retrieves correct data for H3 index 500 (middle record)', () async {
        final service = ZoneDataService(binaryReader: binaryReaderService);
        final data = await service.getZoneData(BigInt.from(500));

        expect(data.bortleClass, equals(3));
        expect(data.ratio, closeTo(0.2, 0.001));
        expect(data.sqm, closeTo(21.5, 0.001));
      });

      test('retrieves correct data for H3 index 1000 (last record)', () async {
        final service = ZoneDataService(binaryReader: binaryReaderService);
        final data = await service.getZoneData(BigInt.from(1000));

        expect(data.bortleClass, equals(8));
        expect(data.ratio, closeTo(3.0, 0.001));
        expect(data.sqm, closeTo(16.0, 0.001));
      });

      test('throws ArgumentError for negative H3 index', () async {
        final service = ZoneDataService(binaryReader: binaryReaderService);

        expect(
          () => service.getZoneData(BigInt.from(-1)),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('H3 index must be non-negative'),
          )),
        );
      });

      test('throws RangeError for H3 index not in database', () async {
        final service = ZoneDataService(binaryReader: binaryReaderService);

        // File has indices 100, 500, 1000. Index 250 is not present.
        expect(
          () => service.getZoneData(BigInt.from(250)),
          throwsA(isA<RangeError>()),
        );
      });
    });

    group('Header Validation', () {
      test('throws FormatException for invalid magic', () async {
        final badDbPath = p.join(tempDir.path, 'bad_magic.db');
        final badFile = File(badDbPath);
        final data = Uint8List(76); // Header + 3 records
        data.setAll(0, 'XXXX'.codeUnits); // Wrong magic
        data.buffer.asByteData().setUint32(4, 1, Endian.little);
        data.buffer.asByteData().setUint64(8, 3, Endian.little);
        await badFile.writeAsBytes(data);

        final badReader = BinaryReaderService(dbPath: badDbPath);
        final service = ZoneDataService(binaryReader: badReader);

        expect(
          () => service.getZoneData(BigInt.from(100)),
          throwsA(isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Invalid zones.db magic'),
          )),
        );
      });

      test('throws FormatException for unsupported version', () async {
        final badDbPath = p.join(tempDir.path, 'bad_version.db');
        final badFile = File(badDbPath);
        final data = Uint8List(76);
        data.setAll(0, 'ASTR'.codeUnits);
        data.buffer.asByteData().setUint32(4, 99, Endian.little); // Wrong version
        data.buffer.asByteData().setUint64(8, 3, Endian.little);
        await badFile.writeAsBytes(data);

        final badReader = BinaryReaderService(dbPath: badDbPath);
        final service = ZoneDataService(binaryReader: badReader);

        expect(
          () => service.getZoneData(BigInt.from(100)),
          throwsA(isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Unsupported zones.db version'),
          )),
        );
      });
    });

    group('performance', () {
      test('binary search lookup completes in < 100ms (NFR-01)', () async {
        final service = ZoneDataService(binaryReader: binaryReaderService);

        final stopwatch = Stopwatch()..start();
        await service.getZoneData(BigInt.from(500)); // Middle record
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: 'NFR-01 requires < 100ms lookup time',
        );
      });

      test('multiple sequential lookups complete quickly', () async {
        final service = ZoneDataService(binaryReader: binaryReaderService);
        final indices = [100, 500, 1000]; // Our test indices

        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < 10; i++) {
          await service.getZoneData(BigInt.from(indices[i % 3]));
        }
        stopwatch.stop();

        // 10 lookups should complete in < 500ms
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('concurrent parallel lookups complete quickly and safely', () async {
        final service = ZoneDataService(binaryReader: binaryReaderService);
        final indices = [100, 500, 1000];

        final stopwatch = Stopwatch()..start();

        // Fire 10 concurrent lookups
        final futures = List.generate(
          10,
          (i) => service.getZoneData(BigInt.from(indices[i % 3])),
        );

        final results = await Future.wait(futures);
        stopwatch.stop();

        // All lookups should complete successfully
        expect(results.length, equals(10));

        // Verify data correctness (index 100, 500, 1000 repeat)
        for (var i = 0; i < results.length; i++) {
          final expected = i % 3;
          if (expected == 0) {
            expect(results[i].bortleClass, equals(5)); // h3=100
          } else if (expected == 1) {
            expect(results[i].bortleClass, equals(3)); // h3=500
          } else {
            expect(results[i].bortleClass, equals(8)); // h3=1000
          }
        }

        // Parallel access should not significantly degrade performance
        // 10 concurrent lookups should still complete in < 1000ms
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('getZoneDataSync', () {
      test('retrieves correct data synchronously', () {
        final service = ZoneDataService(binaryReader: binaryReaderService);
        final data = service.getZoneDataSync(BigInt.from(500));

        expect(data.bortleClass, equals(3));
        expect(data.ratio, closeTo(0.2, 0.001));
        expect(data.sqm, closeTo(21.5, 0.001));
      });

      test('throws ArgumentError for negative H3 index', () {
        final service = ZoneDataService(binaryReader: binaryReaderService);

        expect(
          () => service.getZoneDataSync(BigInt.from(-1)),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
