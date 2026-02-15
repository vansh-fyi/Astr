import 'package:astr/features/astronomy/domain/services/astronomy_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration tests for Story 2.1: Standardize Graph Timeframes
///
/// These tests verify that getNightWindow() correctly calculates
/// the sunset/sunrise window for graphs, meeting all acceptance criteria.
void main() {
  late AstronomyService astronomyService;

  setUpAll(() async {
    // Initialize Flutter bindings for platform channels
    TestWidgetsFlutterBinding.ensureInitialized();

    // Set up method channel mocks for path_provider
    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return '/tmp/test_docs';
      }
      return null;
    });

    astronomyService = AstronomyService();
    await astronomyService.init();
  });

  group('Story 2.1: Standardize Graph Timeframes', skip: 'Native dependency not available', () {
    // New York coordinates for testing
    const double testLat = 40.7128;
    const double testLong = -74.0060;

    test('AC #1: Returns timeframe from Sunset to Sunrise of next day', () async {
      // Arrange - Test with a specific date in summer (June 15, 2024)
      final DateTime testDate = DateTime(2024, 6, 15, 14); // 2 PM

      // Act
      final Map<String, DateTime> nightWindow = await astronomyService.getNightWindow(
        date: testDate,
        lat: testLat,
        long: testLong,
      );

      final DateTime start = nightWindow['start']!;
      final DateTime end = nightWindow['end']!;

      // Assert
      // 1. Start should be sunset on the selected date
      expect(start.year, equals(2024));
      expect(start.month, equals(6));
      expect(start.day, anyOf(equals(15), equals(16))); // Could be 15 or 16 depending on logic

      // 2. End should be sunrise the next day
      expect(end.isAfter(start), true, reason: 'Sunrise must be after sunset');

      // 3. Start time should be in the evening (sunset hours: 7-9 PM in summer)
      expect(start.hour, greaterThanOrEqualTo(19)); // After 7 PM
      expect(start.hour, lessThanOrEqualTo(21)); // Before 9 PM

      // 4. End time should be in the early morning (sunrise hours: 5-7 AM in summer)
      expect(end.hour, greaterThanOrEqualTo(4)); // After 4 AM
      expect(end.hour, lessThanOrEqualTo(7)); // Before 7 AM

      // 5. Duration should be a reasonable night length (8-12 hours)
      final Duration duration = end.difference(start);
      expect(duration.inHours, greaterThanOrEqualTo(8));
      expect(duration.inHours, lessThanOrEqualTo(12));

      print('✓ AC #1: Sunset at $start, Sunrise at $end (${duration.inHours}h ${duration.inMinutes % 60}m)');
    });

    test('AC #2: Context Continuity - Noon shows upcoming night', () async {
      // Arrange - Current time is noon (during the day)
      final DateTime noonTime = DateTime(2024, 6, 15, 12); // Noon

      // Act
      final Map<String, DateTime> nightWindow = await astronomyService.getNightWindow(
        date: noonTime,
        lat: testLat,
        long: testLong,
      );

      final DateTime start = nightWindow['start']!;
      final DateTime end = nightWindow['end']!;

      // Assert
      // When it's noon, should show the UPCOMING night
      // Start (sunset) should be today evening
      expect(start.isAfter(noonTime), true, reason: 'Sunset should be after noon');
      expect(start.day, equals(noonTime.day), reason: 'Sunset should be today');

      // End (sunrise) should be tomorrow morning
      expect(end.isAfter(start), true);
      expect(end.day, equals(noonTime.day + 1), reason: 'Sunrise should be tomorrow');

      print('✓ AC #2 (Noon): Shows upcoming night from $start to $end');
    });

    test('AC #2: Context Continuity - Early morning shows current night', () async {
      // Arrange - Current time is 3 AM (after midnight, before sunrise)
      final DateTime earlyMorning = DateTime(2024, 6, 16, 3); // 3 AM

      // Act
      final Map<String, DateTime> nightWindow = await astronomyService.getNightWindow(
        date: earlyMorning,
        lat: testLat,
        long: testLong,
      );

      final DateTime start = nightWindow['start']!;
      final DateTime end = nightWindow['end']!;

      // Assert
      // When it's 3 AM, should show the CURRENT night (started yesterday evening)
      // Start (sunset) should be yesterday
      expect(start.day, lessThan(earlyMorning.day), reason: 'Sunset should have been yesterday');

      // End (sunrise) should be today (later this morning)
      expect(end.day, equals(earlyMorning.day), reason: 'Sunrise should be today');
      expect(end.isAfter(earlyMorning), true, reason: 'Sunrise should be after 3 AM');

      print('✓ AC #2 (3 AM): Shows current night from $start to $end');
    });

    test('AC #2: Context Continuity - Evening shows current night', () async {
      // Arrange - Current time is 10 PM (after sunset)
      final DateTime eveningTime = DateTime(2024, 6, 15, 22); // 10 PM

      // Act
      final Map<String, DateTime> nightWindow = await astronomyService.getNightWindow(
        date: eveningTime,
        lat: testLat,
        long: testLong,
      );

      final DateTime start = nightWindow['start']!;
      final DateTime end = nightWindow['end']!;

      // Assert
      // When it's 10 PM, should show the CURRENT night
      // Start (sunset) should have already happened today
      expect(start.day, equals(eveningTime.day), reason: 'Sunset should be today');
      expect(start.isBefore(eveningTime), true, reason: 'Sunset should have already happened');

      // End (sunrise) should be tomorrow morning
      expect(end.day, equals(eveningTime.day + 1), reason: 'Sunrise should be tomorrow');
      expect(end.isAfter(eveningTime), true);

      print('✓ AC #2 (10 PM): Shows current night from $start to $end');
    });

    test('AC #3: Consistency - Different dates same location return valid windows', () async {
      // Test multiple dates to ensure consistency
      final List<DateTime> dates = <DateTime>[
        DateTime(2024, 1, 15), // Winter
        DateTime(2024, 3, 15), // Spring
        DateTime(2024, 6, 15), // Summer
        DateTime(2024, 9, 15), // Fall
      ];

      for (final DateTime date in dates) {
        final Map<String, DateTime> nightWindow = await astronomyService.getNightWindow(
          date: date,
          lat: testLat,
          long: testLong,
        );

        final DateTime start = nightWindow['start']!;
        final DateTime end = nightWindow['end']!;

        // Each window should be valid
        expect(start.isBefore(end), true,
            reason: 'Sunset must be before sunrise for ${date.month}/${date.day}');

        // Duration should be reasonable for any season (6-16 hours)
        final Duration duration = end.difference(start);
        expect(duration.inHours, greaterThanOrEqualTo(6),
            reason: 'Night too short for ${date.month}/${date.day}');
        expect(duration.inHours, lessThanOrEqualTo(16),
            reason: 'Night too long for ${date.month}/${date.day}');

        print('✓ AC #3: ${date.month}/${date.day} - ${duration.inHours}h ${duration.inMinutes % 60}m night');
      }
    });

    test('Performance: getNightWindow completes in <100ms', () async {
      // Arrange
      final DateTime testDate = DateTime(2024, 6, 15);

      // Act & Assert
      final Stopwatch stopwatch = Stopwatch()..start();
      await astronomyService.getNightWindow(
        date: testDate,
        lat: testLat,
        long: testLong,
      );
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'getNightWindow should complete in <100ms');

      print('✓ Performance: ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}
