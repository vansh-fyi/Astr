import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:astr/features/data_layer/services/binary_reader_service.dart';

void main() {
  late Directory tempDir;
  late String testDbPath;

  setUpAll(() async {
    // Create temp directory for test files
    tempDir = await Directory.systemTemp.createTemp('binary_reader_test_');

    // Create a test binary file with known content
    testDbPath = p.join(tempDir.path, 'test_zones.db');
    final testFile = File(testDbPath);

    // Write 2KB of known binary data
    // Offset 0-1023: all 0x01
    // Offset 1024-2047: all 0x02
    final data = Uint8List(2048);
    for (var i = 0; i < 1024; i++) {
      data[i] = 0x01;
    }
    for (var i = 1024; i < 2048; i++) {
      data[i] = 0x02;
    }
    await testFile.writeAsBytes(data);
  });

  tearDownAll(() async {
    // Clean up temp directory
    await tempDir.delete(recursive: true);
  });

  group('BinaryReaderService', () {
    group('readBytes', () {
      test('reads correct bytes at offset 0', () async {
        final service = BinaryReaderService(dbPath: testDbPath);
        final bytes = await service.readBytes(offset: 0, length: 12);

        expect(bytes.length, equals(12));
        expect(bytes.every((b) => b == 0x01), isTrue);
      });

      test('reads correct bytes at offset 1024', () async {
        final service = BinaryReaderService(dbPath: testDbPath);
        final bytes = await service.readBytes(offset: 1024, length: 12);

        expect(bytes.length, equals(12));
        expect(bytes.every((b) => b == 0x02), isTrue);
      });

      test('reads bytes spanning boundary', () async {
        final service = BinaryReaderService(dbPath: testDbPath);
        final bytes = await service.readBytes(offset: 1020, length: 8);

        expect(bytes.length, equals(8));
        // First 4 bytes should be 0x01, last 4 should be 0x02
        expect(bytes.sublist(0, 4).every((b) => b == 0x01), isTrue);
        expect(bytes.sublist(4, 8).every((b) => b == 0x02), isTrue);
      });

      test('handles reading at end of file', () async {
        final service = BinaryReaderService(dbPath: testDbPath);
        final bytes = await service.readBytes(offset: 2040, length: 8);

        expect(bytes.length, equals(8));
        expect(bytes.every((b) => b == 0x02), isTrue);
      });

      test('returns empty list for zero length', () async {
        final service = BinaryReaderService(dbPath: testDbPath);
        final bytes = await service.readBytes(offset: 0, length: 0);

        expect(bytes, isEmpty);
      });

      test('throws for negative offset', () async {
        final service = BinaryReaderService(dbPath: testDbPath);

        expect(
          () => service.readBytes(offset: -1, length: 12),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws for negative length', () async {
        final service = BinaryReaderService(dbPath: testDbPath);

        expect(
          () => service.readBytes(offset: 0, length: -1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('handles reading beyond file end gracefully', () async {
        final service = BinaryReaderService(dbPath: testDbPath);
        // File is 2048 bytes, try to read 100 bytes starting at 2000
        // Should only return 48 bytes (what's available)
        final bytes = await service.readBytes(offset: 2000, length: 100);

        expect(bytes.length, equals(48));
        expect(bytes.every((b) => b == 0x02), isTrue);
      });
    });

    group('readBytesSync', () {
      test('reads correct bytes at offset 0', () {
        final service = BinaryReaderService(dbPath: testDbPath);
        final bytes = service.readBytesSync(offset: 0, length: 12);

        expect(bytes.length, equals(12));
        expect(bytes.every((b) => b == 0x01), isTrue);
      });

      test('reads correct bytes at offset 1024', () {
        final service = BinaryReaderService(dbPath: testDbPath);
        final bytes = service.readBytesSync(offset: 1024, length: 12);

        expect(bytes.length, equals(12));
        expect(bytes.every((b) => b == 0x02), isTrue);
      });

      test('reads bytes spanning boundary', () {
        final service = BinaryReaderService(dbPath: testDbPath);
        final bytes = service.readBytesSync(offset: 1020, length: 8);

        expect(bytes.length, equals(8));
        expect(bytes.sublist(0, 4).every((b) => b == 0x01), isTrue);
        expect(bytes.sublist(4, 8).every((b) => b == 0x02), isTrue);
      });

      test('returns empty list for zero length', () {
        final service = BinaryReaderService(dbPath: testDbPath);
        final bytes = service.readBytesSync(offset: 0, length: 0);

        expect(bytes, isEmpty);
      });

      test('throws for negative offset', () {
        final service = BinaryReaderService(dbPath: testDbPath);

        expect(
          () => service.readBytesSync(offset: -1, length: 12),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws for negative length', () {
        final service = BinaryReaderService(dbPath: testDbPath);

        expect(
          () => service.readBytesSync(offset: 0, length: -1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('handles reading beyond file end gracefully', () {
        final service = BinaryReaderService(dbPath: testDbPath);
        final bytes = service.readBytesSync(offset: 2000, length: 100);

        expect(bytes.length, equals(48));
        expect(bytes.every((b) => b == 0x02), isTrue);
      });
    });

    group('file not found', () {
      test('throws FileSystemException for non-existent file', () async {
        final service = BinaryReaderService(dbPath: '/nonexistent/path.db');

        expect(
          () => service.readBytes(offset: 0, length: 12),
          throwsA(isA<FileSystemException>()),
        );
      });

      test('sync version throws FileSystemException for non-existent file', () {
        final service = BinaryReaderService(dbPath: '/nonexistent/path.db');

        expect(
          () => service.readBytesSync(offset: 0, length: 12),
          throwsA(isA<FileSystemException>()),
        );
      });
    });
  });

  group('BinaryReaderService - Copy on Setup', () {
    late Directory appDocsDir;

    setUp(() async {
      // Create mock app documents directory
      appDocsDir = await Directory.systemTemp.createTemp('app_docs_');
    });

    tearDown(() async {
      await appDocsDir.delete(recursive: true);
    });

    test('copyAssetToPath copies source to destination', () async {
      // Create source file
      final srcPath = p.join(tempDir.path, 'source.db');
      final srcFile = File(srcPath);
      final sourceData = Uint8List.fromList([1, 2, 3, 4, 5]);
      await srcFile.writeAsBytes(sourceData);

      final destPath = p.join(appDocsDir.path, 'zones.db');

      // Copy using static method
      await BinaryReaderService.copyFile(srcPath, destPath);

      // Verify destination exists and has correct content
      final destFile = File(destPath);
      expect(await destFile.exists(), isTrue);
      final destData = await destFile.readAsBytes();
      expect(destData, equals(sourceData));
    });

    test('copyAssetToPath overwrites existing file', () async {
      // Create source file
      final srcPath = p.join(tempDir.path, 'source2.db');
      final srcFile = File(srcPath);
      final sourceData = Uint8List.fromList([10, 20, 30]);
      await srcFile.writeAsBytes(sourceData);

      final destPath = p.join(appDocsDir.path, 'zones2.db');

      // Create existing destination with different content
      final destFile = File(destPath);
      await destFile.writeAsBytes([99, 99, 99, 99, 99]);

      // Copy should overwrite
      await BinaryReaderService.copyFile(srcPath, destPath);

      final destData = await destFile.readAsBytes();
      expect(destData, equals(sourceData));
    });
  });

  group('BinaryReaderService - Integration Tests', () {
    test(
      'initialize() succeeds with valid asset',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();

        // This test requires the actual asset file to exist
        // It verifies the full initialization flow
        final service = await BinaryReaderService.initialize();

        expect(service, isNotNull);
        expect(service.dbPath, isNotEmpty);

        // Verify we can read from the initialized service
        final bytes = await service.readBytes(offset: 0, length: 12);
        expect(bytes, isNotEmpty);
      },
      skip: 'Requires platform plugin (path_provider) - run as widget test',
    );

    test(
      'initialize() uses existing file if already copied',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();

        // First initialization
        final service1 = await BinaryReaderService.initialize();
        final path1 = service1.dbPath;

        // Second initialization should reuse existing file
        final service2 = await BinaryReaderService.initialize();
        final path2 = service2.dbPath;

        expect(path1, equals(path2));
        expect(File(path1).existsSync(), isTrue);
      },
      skip: 'Requires platform plugin (path_provider) - run as widget test',
    );
  });

  group('BinaryReaderService - Error Handling', () {
    test('provides clear error for missing asset in bundle', () async {
      // This tests the error handling when asset is not in bundle
      // We can't easily simulate this in a test without mocking,
      // but we verify the exception types are correct
      expect(
        AssetNotFoundException('test').toString(),
        contains('AssetNotFoundException'),
      );
      expect(
        DataIntegrityException('test').toString(),
        contains('DataIntegrityException'),
      );
    });
  });
}
