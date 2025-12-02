import 'package:astr/features/astronomy/domain/entities/celestial_body.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_position.dart';
import 'package:astr/features/dashboard/domain/entities/highlight_item.dart';
import 'package:astr/features/dashboard/domain/logic/highlights_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HighlightsLogic', () {
    final now = DateTime.now();

    CelestialPosition createPos(CelestialBody body, double alt, double mag) {
      return CelestialPosition(
        body: body,
        time: now,
        altitude: alt,
        azimuth: 0,
        distance: 0,
        magnitude: mag,
      );
    }

    test('should filter objects below 10 degrees altitude', () {
      final positions = [
        createPos(CelestialBody.jupiter, 5.0, -2.0), // Too low
        createPos(CelestialBody.mars, 15.0, -1.0), // Visible
      ];

      final result = HighlightsLogic.selectTop3(positions: positions);

      expect(result.length, 1);
      expect(result.first.body, CelestialBody.mars);
    });

    test('should exclude the Sun', () {
      final positions = [
        createPos(CelestialBody.sun, 45.0, -26.0), // Sun is bright but should be excluded
        createPos(CelestialBody.venus, 20.0, -4.0),
      ];

      final result = HighlightsLogic.selectTop3(positions: positions);

      expect(result.length, 1);
      expect(result.first.body, CelestialBody.venus);
    });

    test('should sort by magnitude (lower is brighter)', () {
      final positions = [
        createPos(CelestialBody.mars, 30.0, 1.0), // Dimmer
        createPos(CelestialBody.venus, 30.0, -4.0), // Brightest
        createPos(CelestialBody.jupiter, 30.0, -2.0), // Bright
      ];

      final result = HighlightsLogic.selectTop3(positions: positions);

      expect(result.length, 3);
      expect(result[0].body, CelestialBody.venus);
      expect(result[1].body, CelestialBody.jupiter);
      expect(result[2].body, CelestialBody.mars);
    });

    test('should take only top 3', () {
      final positions = [
        createPos(CelestialBody.venus, 30.0, -4.0),
        createPos(CelestialBody.jupiter, 30.0, -2.0),
        createPos(CelestialBody.mars, 30.0, 0.0),
        createPos(CelestialBody.saturn, 30.0, 1.0), // 4th brightest
      ];

      final result = HighlightsLogic.selectTop3(positions: positions);

      expect(result.length, 3);
      expect(result.map((e) => e.body), containsAll([
        CelestialBody.venus,
        CelestialBody.jupiter,
        CelestialBody.mars,
      ]));
      expect(result.map((e) => e.body), isNot(contains(CelestialBody.saturn)));
    });
  });
}
