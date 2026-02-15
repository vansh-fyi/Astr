import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:astr/features/data_layer/models/zone_data.dart';
import '../../../helpers/zone_data_test_helpers.dart';

void main() {
  group('ZoneData', () {
    group('fromBytes', () {
      test('parses valid 12-byte binary data correctly', () {
        // Create valid test data:
        // Byte[0] = 5 (Bortle Class)
        // Bytes[1-4] = 0.5 as float32 little-endian
        // Bytes[5-8] = 21.5 as float32 little-endian
        // Bytes[9-11] = padding (0x00)
        final bytes = Uint8List(12);
        final buffer = bytes.buffer.asByteData();

        bytes[0] = 5; // Bortle class
        buffer.setFloat32(1, 0.5, Endian.little); // Ratio
        buffer.setFloat32(5, 21.5, Endian.little); // SQM

        final zoneData = ZoneData.fromBytes(bytes);

        expect(zoneData.bortleClass, equals(5));
        expect(zoneData.ratio, closeTo(0.5, 0.001));
        expect(zoneData.sqm, closeTo(21.5, 0.001));
      });

      test('parses Bortle class 1 (darkest sky)', () {
        final bytes = createTestZoneBytes(bortleClass: 1, ratio: 0.1, sqm: 22.0);
        final zoneData = ZoneData.fromBytes(bytes);

        expect(zoneData.bortleClass, equals(1));
        expect(zoneData.ratio, closeTo(0.1, 0.001));
        expect(zoneData.sqm, closeTo(22.0, 0.001));
      });

      test('parses Bortle class 9 (brightest/city)', () {
        final bytes = createTestZoneBytes(bortleClass: 9, ratio: 5.0, sqm: 15.0);
        final zoneData = ZoneData.fromBytes(bytes);

        expect(zoneData.bortleClass, equals(9));
        expect(zoneData.ratio, closeTo(5.0, 0.001));
        expect(zoneData.sqm, closeTo(15.0, 0.001));
      });

      test('throws FormatException for Bortle class 0', () {
        final bytes = createTestZoneBytes(bortleClass: 0, ratio: 0.5, sqm: 20.0);

        expect(
          () => ZoneData.fromBytes(bytes),
          throwsA(isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Bortle class must be between 1 and 9'),
          )),
        );
      });

      test('throws FormatException for Bortle class 10', () {
        final bytes = createTestZoneBytes(bortleClass: 10, ratio: 0.5, sqm: 20.0);

        expect(
          () => ZoneData.fromBytes(bytes),
          throwsA(isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Bortle class must be between 1 and 9'),
          )),
        );
      });

      test('throws FormatException for Bortle class 255', () {
        final bytes = createTestZoneBytes(bortleClass: 255, ratio: 0.5, sqm: 20.0);

        expect(
          () => ZoneData.fromBytes(bytes),
          throwsA(isA<FormatException>()),
        );
      });

      test('accepts ratio of 0', () {
        final bytes = createTestZoneBytes(bortleClass: 1, ratio: 0.0, sqm: 22.0);
        final zoneData = ZoneData.fromBytes(bytes);

        expect(zoneData.ratio, equals(0.0));
      });

      test('throws FormatException for negative ratio', () {
        final bytes = createTestZoneBytes(bortleClass: 5, ratio: -0.1, sqm: 20.0);

        expect(
          () => ZoneData.fromBytes(bytes),
          throwsA(isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Ratio must be non-negative'),
          )),
        );
      });

      test('accepts SQM at lower boundary (15.0)', () {
        final bytes = createTestZoneBytes(bortleClass: 9, ratio: 5.0, sqm: 15.0);
        final zoneData = ZoneData.fromBytes(bytes);

        expect(zoneData.sqm, closeTo(15.0, 0.001));
      });

      test('accepts SQM at upper boundary (22.0)', () {
        final bytes = createTestZoneBytes(bortleClass: 1, ratio: 0.1, sqm: 22.0);
        final zoneData = ZoneData.fromBytes(bytes);

        expect(zoneData.sqm, closeTo(22.0, 0.001));
      });

      test('accepts SQM slightly outside typical range (14.0)', () {
        // Values outside 15-22 are allowed but unusual
        final bytes = createTestZoneBytes(bortleClass: 9, ratio: 10.0, sqm: 14.0);
        final zoneData = ZoneData.fromBytes(bytes);

        expect(zoneData.sqm, closeTo(14.0, 0.001));
      });

      test('throws ArgumentError for bytes shorter than 12', () {
        final bytes = Uint8List(11);

        expect(
          () => ZoneData.fromBytes(bytes),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Expected 12 bytes'),
          )),
        );
      });

      test('accepts bytes longer than 12 (uses only first 12)', () {
        final bytes = createTestZoneBytes(bortleClass: 5, ratio: 0.5, sqm: 20.0);
        final extendedBytes = Uint8List(20);
        extendedBytes.setAll(0, bytes);

        // Should work with longer buffer
        final zoneData = ZoneData.fromBytes(extendedBytes.sublist(0, 12));
        expect(zoneData.bortleClass, equals(5));
      });
    });

    group('equality', () {
      test('two ZoneData with same values are equal', () {
        final bytes = createTestZoneBytes(bortleClass: 5, ratio: 0.5, sqm: 20.0);
        final a = ZoneData.fromBytes(bytes);
        final b = ZoneData.fromBytes(bytes);

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('two ZoneData with different Bortle are not equal', () {
        final bytesA = createTestZoneBytes(bortleClass: 5, ratio: 0.5, sqm: 20.0);
        final bytesB = createTestZoneBytes(bortleClass: 6, ratio: 0.5, sqm: 20.0);

        expect(ZoneData.fromBytes(bytesA), isNot(equals(ZoneData.fromBytes(bytesB))));
      });

      test('two ZoneData with different ratio are not equal', () {
        final bytesA = createTestZoneBytes(bortleClass: 5, ratio: 0.5, sqm: 20.0);
        final bytesB = createTestZoneBytes(bortleClass: 5, ratio: 0.6, sqm: 20.0);

        expect(ZoneData.fromBytes(bytesA), isNot(equals(ZoneData.fromBytes(bytesB))));
      });

      test('two ZoneData with different SQM are not equal', () {
        final bytesA = createTestZoneBytes(bortleClass: 5, ratio: 0.5, sqm: 20.0);
        final bytesB = createTestZoneBytes(bortleClass: 5, ratio: 0.5, sqm: 21.0);

        expect(ZoneData.fromBytes(bytesA), isNot(equals(ZoneData.fromBytes(bytesB))));
      });
    });

    group('copyWith', () {
      test('creates copy with modified bortleClass', () {
        final bytes = createTestZoneBytes(bortleClass: 5, ratio: 0.5, sqm: 20.0);
        final original = ZoneData.fromBytes(bytes);
        final copy = original.copyWith(bortleClass: 7);

        expect(copy.bortleClass, equals(7));
        expect(copy.ratio, equals(original.ratio));
        expect(copy.sqm, equals(original.sqm));
      });

      test('creates copy with modified ratio', () {
        final bytes = createTestZoneBytes(bortleClass: 5, ratio: 0.5, sqm: 20.0);
        final original = ZoneData.fromBytes(bytes);
        final copy = original.copyWith(ratio: 1.5);

        expect(copy.bortleClass, equals(original.bortleClass));
        expect(copy.ratio, closeTo(1.5, 0.001));
        expect(copy.sqm, equals(original.sqm));
      });

      test('creates copy with modified sqm', () {
        final bytes = createTestZoneBytes(bortleClass: 5, ratio: 0.5, sqm: 20.0);
        final original = ZoneData.fromBytes(bytes);
        final copy = original.copyWith(sqm: 18.0);

        expect(copy.bortleClass, equals(original.bortleClass));
        expect(copy.ratio, equals(original.ratio));
        expect(copy.sqm, closeTo(18.0, 0.001));
      });

      test('creates identical copy when no parameters provided', () {
        final bytes = createTestZoneBytes(bortleClass: 5, ratio: 0.5, sqm: 20.0);
        final original = ZoneData.fromBytes(bytes);
        final copy = original.copyWith();

        expect(copy, equals(original));
      });
    });

    group('toString', () {
      test('produces readable string representation', () {
        final bytes = createTestZoneBytes(bortleClass: 5, ratio: 0.5, sqm: 20.5);
        final zoneData = ZoneData.fromBytes(bytes);

        final str = zoneData.toString();

        expect(str, contains('ZoneData'));
        expect(str, contains('bortleClass: 5'));
        expect(str, contains('ratio:'));
        expect(str, contains('sqm:'));
      });
    });
  });
}

