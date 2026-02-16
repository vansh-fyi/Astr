import 'package:flutter_test/flutter_test.dart';

import 'package:astr/features/data_layer/models/coordinate_validation_exception.dart';
import 'package:astr/features/data_layer/services/coordinate_validation_service.dart';
import 'package:astr/features/data_layer/services/h3_service.dart';

void main() {
  late CoordinateValidationService service;

  setUp(() {
    service = CoordinateValidationService();
  });

  group('CoordinateValidationService', () {
    group('validateLatitude', () {
      group('valid latitudes', () {
        test('accepts -90.0 (South Pole)', () {
          expect(() => service.validateLatitude(-90.0), returnsNormally);
        });

        test('accepts 0.0 (Equator)', () {
          expect(() => service.validateLatitude(0.0), returnsNormally);
        });

        test('accepts 90.0 (North Pole)', () {
          expect(() => service.validateLatitude(90.0), returnsNormally);
        });

        test('accepts 45.0 (mid-range)', () {
          expect(() => service.validateLatitude(45.0), returnsNormally);
        });

        test('accepts -45.0 (mid-range negative)', () {
          expect(() => service.validateLatitude(-45.0), returnsNormally);
        });

        test('accepts 40.7128 (NYC)', () {
          expect(() => service.validateLatitude(40.7128), returnsNormally);
        });
      });

      group('invalid latitudes', () {
        test('throws for 91.0', () {
          expect(
            () => service.validateLatitude(91.0),
            throwsA(isA<CoordinateValidationException>().having(
              (e) => e.message,
              'message',
              equals('Latitude must be between -90 and 90'),
            )),
          );
        });

        test('throws for 95.0 (AC-1 example)', () {
          expect(
            () => service.validateLatitude(95.0),
            throwsA(isA<CoordinateValidationException>().having(
              (e) => e.field,
              'field',
              equals('latitude'),
            )),
          );
        });

        test('throws for 100.0', () {
          expect(
            () => service.validateLatitude(100.0),
            throwsA(isA<CoordinateValidationException>()),
          );
        });

        test('throws for -91.0', () {
          expect(
            () => service.validateLatitude(-91.0),
            throwsA(isA<CoordinateValidationException>().having(
              (e) => e.value,
              'value',
              equals(-91.0),
            )),
          );
        });

        test('throws for -100.0', () {
          expect(
            () => service.validateLatitude(-100.0),
            throwsA(isA<CoordinateValidationException>()),
          );
        });

        test('throws for infinity', () {
          expect(
            () => service.validateLatitude(double.infinity),
            throwsA(isA<CoordinateValidationException>()),
          );
        });

        test('throws for -infinity', () {
          expect(
            () => service.validateLatitude(double.negativeInfinity),
            throwsA(isA<CoordinateValidationException>()),
          );
        });

        test('throws for NaN', () {
          expect(
            () => service.validateLatitude(double.nan),
            throwsA(isA<CoordinateValidationException>()),
          );
        });
      });
    });

    group('validateLongitude', () {
      group('valid longitudes', () {
        test('accepts -180.0 (International Date Line West)', () {
          expect(() => service.validateLongitude(-180.0), returnsNormally);
        });

        test('accepts 0.0 (Prime Meridian)', () {
          expect(() => service.validateLongitude(0.0), returnsNormally);
        });

        test('accepts 180.0 (International Date Line East)', () {
          expect(() => service.validateLongitude(180.0), returnsNormally);
        });

        test('accepts 90.0 (mid-range)', () {
          expect(() => service.validateLongitude(90.0), returnsNormally);
        });

        test('accepts -74.0060 (NYC)', () {
          expect(() => service.validateLongitude(-74.0060), returnsNormally);
        });
      });

      group('invalid longitudes', () {
        test('throws for 181.0', () {
          expect(
            () => service.validateLongitude(181.0),
            throwsA(isA<CoordinateValidationException>().having(
              (e) => e.message,
              'message',
              equals('Longitude must be between -180 and 180'),
            )),
          );
        });

        test('throws for 200.0 (AC-2 example)', () {
          expect(
            () => service.validateLongitude(200.0),
            throwsA(isA<CoordinateValidationException>().having(
              (e) => e.field,
              'field',
              equals('longitude'),
            )),
          );
        });

        test('throws for -181.0', () {
          expect(
            () => service.validateLongitude(-181.0),
            throwsA(isA<CoordinateValidationException>().having(
              (e) => e.value,
              'value',
              equals(-181.0),
            )),
          );
        });

        test('throws for -200.0', () {
          expect(
            () => service.validateLongitude(-200.0),
            throwsA(isA<CoordinateValidationException>()),
          );
        });

        test('throws for infinity', () {
          expect(
            () => service.validateLongitude(double.infinity),
            throwsA(isA<CoordinateValidationException>()),
          );
        });

        test('throws for -infinity', () {
          expect(
            () => service.validateLongitude(double.negativeInfinity),
            throwsA(isA<CoordinateValidationException>()),
          );
        });

        test('throws for NaN', () {
          expect(
            () => service.validateLongitude(double.nan),
            throwsA(isA<CoordinateValidationException>()),
          );
        });
      });
    });

    group('validateCoordinates', () {
      test('accepts valid coordinates (NYC: 40.7128, -74.0060)', () {
        expect(
          () => service.validateCoordinates(40.7128, -74.0060),
          returnsNormally,
        );
      });

      test('accepts boundary values (-90, -180)', () {
        expect(
          () => service.validateCoordinates(-90.0, -180.0),
          returnsNormally,
        );
      });

      test('accepts boundary values (90, 180)', () {
        expect(
          () => service.validateCoordinates(90.0, 180.0),
          returnsNormally,
        );
      });

      test('accepts origin (0, 0)', () {
        expect(
          () => service.validateCoordinates(0.0, 0.0),
          returnsNormally,
        );
      });

      test('throws for invalid latitude (valid longitude)', () {
        expect(
          () => service.validateCoordinates(95.0, 0.0),
          throwsA(isA<CoordinateValidationException>().having(
            (e) => e.field,
            'field',
            equals('latitude'),
          )),
        );
      });

      test('throws for invalid longitude (valid latitude)', () {
        expect(
          () => service.validateCoordinates(0.0, 200.0),
          throwsA(isA<CoordinateValidationException>().having(
            (e) => e.field,
            'field',
            equals('longitude'),
          )),
        );
      });

      test('throws for both invalid (reports latitude first)', () {
        expect(
          () => service.validateCoordinates(100.0, 200.0),
          throwsA(isA<CoordinateValidationException>().having(
            (e) => e.field,
            'field',
            equals('latitude'),
          )),
        );
      });
    });

    group('performance', () {
      test('1000 validations complete in < 100ms', () {
        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < 1000; i++) {
          service.validateCoordinates(40.7128, -74.0060);
        }
        stopwatch.stop();

        // 1000 validations should complete in < 100ms (0.1ms each avg)
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: 'Validation adds negligible overhead',
        );
      });

      test('concurrent validations are thread-safe', () async {
        // Test parallel validation calls (simulating concurrent UI validation)
        final futures = List.generate(10, (i) {
          return Future(() {
            // Validate 100 times per thread
            for (var j = 0; j < 100; j++) {
              service.validateCoordinates(40.7128 + i, -74.0060);
            }
            return i;
          });
        });

        // All should complete without error
        final results = await Future.wait(futures);
        expect(results, hasLength(10));
      });
    });
  });

  group('CoordinateValidationException', () {
    test('toString includes all fields', () {
      const exception = CoordinateValidationException(
        'Test error',
        field: 'latitude',
        value: 95.0,
      );

      final str = exception.toString();
      expect(str, contains('CoordinateValidationException'));
      expect(str, contains('Test error'));
      expect(str, contains('latitude'));
      expect(str, contains('95.0'));
    });

    test('error message matches AC-1 exactly', () {
      const exception = CoordinateValidationException(
        'Latitude must be between -90 and 90',
        field: 'latitude',
        value: 95.0,
      );

      expect(exception.message, equals('Latitude must be between -90 and 90'));
    });

    test('error message matches AC-2 exactly', () {
      const exception = CoordinateValidationException(
        'Longitude must be between -180 and 180',
        field: 'longitude',
        value: 200.0,
      );

      expect(exception.message, equals('Longitude must be between -180 and 180'));
    });
  });

  group('AC-3: Integration with H3 and ZoneData', () {
    test('valid coordinates proceed to H3 resolution and zone data retrieval',
        () async {
      // AC-3: Given valid coordinates, system accepts and proceeds to H3 resolution
      const lat = 40.7128; // NYC
      const lon = -74.0060;

      // Step 1: Validate coordinates (should not throw)
      expect(
        () => service.validateCoordinates(lat, lon),
        returnsNormally,
        reason: 'Valid coordinates should pass validation',
      );

      // Step 2: Proceed to H3 resolution (integration point)
      final h3Service = H3Service();
      final h3Index = h3Service.latLonToH3(lat, lon, 8);

      expect(h3Index, isA<BigInt>());
      expect(h3Index > BigInt.zero, isTrue);

      // Step 3: Zone data retrieval would use CachedZoneRepository (remote API)
      // which requires network access, so skipped in unit tests
    }, skip: 'Requires h3_flutter FFI and network access (platform-dependent)');

    test('invalid coordinates prevent H3 lookup attempt', () {
      // AC-3 negative case: Invalid coordinates should NOT reach H3Service
      const invalidLat = 95.0; // Invalid
      const validLon = 0.0;

      // Validation should throw before H3 lookup
      expect(
        () {
          service.validateCoordinates(invalidLat, validLon);
          // If we reach here, validation failed to catch invalid input
          fail('Validation should have thrown before H3 lookup');
        },
        throwsA(isA<CoordinateValidationException>()),
        reason: 'Invalid coordinates must be caught by validation',
      );

      // H3Service is never called - validation guards the boundary
    });

    test('UI layer pattern: validate before H3 operations', () {
      // Demonstrates the intended usage pattern from Task 3
      const lat = 0.0;
      const lon = 0.0;

      // UI layer should do this:
      try {
        // 1. Validate first (user-facing error messages)
        service.validateCoordinates(lat, lon);

        // 2. Then call H3 (internal validation as defense-in-depth)
        final h3Service = H3Service();
        final index = h3Service.latLonToH3(lat, lon, 8);

        expect(index, isA<BigInt>());
      } on CoordinateValidationException catch (e) {
        // User gets friendly error message
        expect(e.message, contains('must be between'));
        fail('Should not throw for valid coordinates');
      }
    }, skip: 'Requires h3_flutter FFI (platform-dependent)');
  });
}
