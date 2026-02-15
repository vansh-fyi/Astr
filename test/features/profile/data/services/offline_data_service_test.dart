import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;

import 'package:astr/features/profile/data/services/offline_data_service.dart';

import 'offline_data_service_test.mocks.dart';

@GenerateMocks(<Type>[Dio])
void main() {
  late Directory tempDir;
  late String fakePath;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('offline_data_test_');
    fakePath = tempDir.path;

    // Mock path_provider's getApplicationDocumentsDirectory
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return fakePath;
        }
        return null;
      },
    );
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await tempDir.delete(recursive: true);
  });

  group('OfflineDataService', () {
    group('isDownloaded', () {
      test('returns false when file does not exist', () async {
        final OfflineDataService service = OfflineDataService(
          baseUrl: 'https://test.example.com',
        );

        final bool result = await service.isDownloaded;
        expect(result, isFalse);
      });

      test('returns true when file exists', () async {
        // Create the file
        final File zonesFile = File(p.join(fakePath, 'zones.db'));
        await zonesFile.writeAsString('test data');

        final OfflineDataService service = OfflineDataService(
          baseUrl: 'https://test.example.com',
        );

        final bool result = await service.isDownloaded;
        expect(result, isTrue);

        // Clean up
        await zonesFile.delete();
      });
    });

    group('getFileSize', () {
      test('returns null when file does not exist', () async {
        final OfflineDataService service = OfflineDataService(
          baseUrl: 'https://test.example.com',
        );

        final int? result = await service.getFileSize();
        expect(result, isNull);
      });

      test('returns file size when file exists', () async {
        final File zonesFile = File(p.join(fakePath, 'zones.db'));
        await zonesFile.writeAsString('test data 12345');

        final OfflineDataService service = OfflineDataService(
          baseUrl: 'https://test.example.com',
        );

        final int? result = await service.getFileSize();
        expect(result, greaterThan(0));

        await zonesFile.delete();
      });
    });

    group('getLocalDbPath', () {
      test('returns null when file does not exist', () async {
        final OfflineDataService service = OfflineDataService(
          baseUrl: 'https://test.example.com',
        );

        final String? result = await service.getLocalDbPath();
        expect(result, isNull);
      });

      test('returns path when file exists', () async {
        final File zonesFile = File(p.join(fakePath, 'zones.db'));
        await zonesFile.writeAsString('test');

        final OfflineDataService service = OfflineDataService(
          baseUrl: 'https://test.example.com',
        );

        final String? result = await service.getLocalDbPath();
        expect(result, isNotNull);
        expect(result, contains('zones.db'));

        await zonesFile.delete();
      });
    });

    group('download', () {
      test('calls Dio.download with correct URL and renames temp file', () async {
        final MockDio mockDio = MockDio();
        final String expectedTempPath = p.join(fakePath, 'zones.db.tmp');
        final String expectedFinalPath = p.join(fakePath, 'zones.db');

        when(mockDio.download(
          any,
          any,
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((Invocation invocation) async {
          // Simulate writing to the temp path
          final String destPath = invocation.positionalArguments[1] as String;
          await File(destPath).writeAsString('downloaded zone data');
          return Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
          );
        });

        final OfflineDataService service = OfflineDataService(
          baseUrl: 'https://test.example.com',
          dio: mockDio,
        );

        final List<double> progressValues = <double>[];
        final String path = await service.download(
          onProgress: (double p) => progressValues.add(p),
        );

        // Verify URL
        verify(mockDio.download(
          'https://test.example.com/download',
          expectedTempPath,
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).called(1);

        // Verify final file exists (temp was renamed)
        expect(path, expectedFinalPath);
        expect(File(expectedFinalPath).existsSync(), isTrue);

        // Clean up
        await File(expectedFinalPath).delete();
      });

      test('passes cancel token to Dio', () async {
        final MockDio mockDio = MockDio();
        final CancelToken token = CancelToken();

        when(mockDio.download(
          any,
          any,
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((Invocation invocation) async {
          final String destPath = invocation.positionalArguments[1] as String;
          await File(destPath).writeAsString('data');
          return Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
          );
        });

        final OfflineDataService service = OfflineDataService(
          baseUrl: 'https://test.example.com',
          dio: mockDio,
        );

        await service.download(
          onProgress: (double p) {},
          cancelToken: token,
        );

        verify(mockDio.download(
          any,
          any,
          cancelToken: token,
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).called(1);

        // Clean up
        final File finalFile = File(p.join(fakePath, 'zones.db'));
        if (finalFile.existsSync()) await finalFile.delete();
      });

      test('cleans up temp file on download failure', () async {
        final MockDio mockDio = MockDio();

        when(mockDio.download(
          any,
          any,
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((Invocation invocation) async {
          // Write temp file, then fail
          final String destPath = invocation.positionalArguments[1] as String;
          await File(destPath).writeAsString('partial data');
          throw DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionError,
          );
        });

        final OfflineDataService service = OfflineDataService(
          baseUrl: 'https://test.example.com',
          dio: mockDio,
        );

        expect(
          () => service.download(onProgress: (double p) {}),
          throwsA(isA<DioException>()),
        );

        // Temp file should be cleaned up
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(
          File(p.join(fakePath, 'zones.db.tmp')).existsSync(),
          isFalse,
        );
      });
    });

    group('delete', () {
      test('returns true when file exists and is deleted', () async {
        final File zonesFile = File(p.join(fakePath, 'zones.db'));
        await zonesFile.writeAsString('test');
        expect(zonesFile.existsSync(), isTrue);

        final OfflineDataService service = OfflineDataService(
          baseUrl: 'https://test.example.com',
        );

        final bool result = await service.delete();
        expect(result, isTrue);
        expect(zonesFile.existsSync(), isFalse);
      });

      test('returns false when file does not exist', () async {
        final OfflineDataService service = OfflineDataService(
          baseUrl: 'https://test.example.com',
        );

        final bool result = await service.delete();
        expect(result, isFalse);
      });
    });

    group('dispose', () {
      test('closes the Dio client', () {
        final MockDio mockDio = MockDio();
        final OfflineDataService service = OfflineDataService(
          baseUrl: 'https://test.example.com',
          dio: mockDio,
        );

        service.dispose();

        verify(mockDio.close()).called(1);
      });
    });
  });
}
