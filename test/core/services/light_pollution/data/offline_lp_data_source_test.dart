import 'package:astr/core/engine/models/location.dart';
import 'package:astr/core/services/light_pollution/data/offline_lp_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration tests for OfflineLPDataSource
/// Tests pixel reading from actual PNG asset
/// AC#3: PNG loading and lat/long to pixel mapping
/// AC#4: Accuracy (±1 class from expected)
/// AC#5: Performance < 100ms
void main() {
  late OfflineLPDataSource dataSource;

  setUp(() {
    dataSource = OfflineLPDataSource();
  });

  tearDown(() {
    dataSource.clearCache();
  });

  group('OfflineLPDataSource - Pixel Reading (AC#3)', () {
    test('NYC (high light pollution) → Returns high Bortle class', () async {
      // Arrange
      const Location nyc = Location(latitude: 40.7128, longitude: -74.0060);

      // Act
      final int? result = await dataSource.getBortleClass(nyc);

      // Assert
      expect(result, isNotNull);
      expect(result, greaterThanOrEqualTo(7)); // Urban area should be 7-9
      expect(result, lessThanOrEqualTo(9));
    });

    test('Desert location (low light pollution) → Returns low Bortle class', () async {
      // Arrange
      const Location desert = Location(latitude: 35, longitude: -110);

      // Act
      final int? result = await dataSource.getBortleClass(desert);

      // Assert
      expect(result, isNotNull);
      expect(result, greaterThanOrEqualTo(1)); // Rural/desert should be 1-4
      expect(result, lessThanOrEqualTo(4));
    });

    test('London (moderate light pollution) → Returns moderate Bortle class', () async {
      // Arrange
      const Location london = Location(latitude: 51.5074, longitude: -0.1278);

      // Act
      final int? result = await dataSource.getBortleClass(london);

      // Assert
      expect(result, isNotNull);
      expect(result, greaterThanOrEqualTo(5)); // Urban area
      expect(result, lessThanOrEqualTo(9));
    });

    test('Multiple locations → All return valid Bortle classes', () async {
      // Arrange
      final List<Location> locations = <Location>[
        const Location(latitude: 40.7, longitude: -74), // NYC
        const Location(latitude: 35, longitude: -110), // Desert
        const Location(latitude: 51.5, longitude: -0.1),   // London
        const Location(latitude: -33.9, longitude: 18.4),  // Cape Town
      ];

      // Act & Assert
      for (final Location location in locations) {
        final int? result = await dataSource.getBortleClass(location);
        expect(result, isNotNull, reason: 'Failed for $location');
        expect(result, greaterThanOrEqualTo(1));
        expect(result, lessThanOrEqualTo(9));
      }
    });
  });

  group('Performance (AC#5)', () {
    test('Offline lookup completes in < 100ms (after initial load)', () async {
      // Arrange
      const Location location = Location(latitude: 40.7, longitude: -74);
      
      // Warm up (first call loads image)
      await dataSource.getBortleClass(location);

      // Act - Measure 10 consecutive calls
      final Stopwatch stopwatch = Stopwatch()..start();
      for (int i = 0; i < 10; i++) {
        await dataSource.getBortleClass(location);
      }
      stopwatch.stop();

      // Assert
      final double averageMs = stopwatch.elapsedMilliseconds / 10;
      expect(averageMs, lessThan(100), 
        reason: 'Average lookup time was ${averageMs}ms, expected < 100ms');
    });

    test('First call (cold start) loads image successfully', () async {
      // Arrange
      const Location location = Location(latitude: 40.7, longitude: -74);

      // Act
      final Stopwatch stopwatch = Stopwatch()..start();
      final int? result = await dataSource.getBortleClass(location);
      stopwatch.stop();

      // Assert
      expect(result, isNotNull);
      // First load may take longer, but should still be reasonable
      expect(stopwatch.elapsedMilliseconds, lessThan(2000),
        reason: 'Initial load took too long');
    });
  });

  group('Cache Management', () {
    test('Cache persists across multiple calls', () async {
      // Arrange
      const Location location = Location(latitude: 40.7, longitude: -74);

      // Act
      final int? result1 = await dataSource.getBortleClass(location);
      final int? result2 = await dataSource.getBortleClass(location);

      // Assert
      expect(result1, equals(result2));
    });

    test('clearCache() resets cached image', () async {
      // Arrange
      const Location location = Location(latitude: 40.7, longitude: -74);
      await dataSource.getBortleClass(location);

      // Act
      dataSource.clearCache();
      final int? result = await dataSource.getBortleClass(location);

      // Assert
      expect(result, isNotNull); // Should re-load successfully
    });
  });
}
