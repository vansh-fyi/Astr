import 'package:astr/features/astronomy/domain/entities/celestial_body.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_position.dart';
import 'package:astr/features/dashboard/domain/entities/highlight_item.dart';
import 'package:astr/features/dashboard/domain/logic/highlights_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HighlightsLogic', () {
    final DateTime now = DateTime.now();

    CelestialPosition createPos(CelestialBody body, double alt, double mag) {
      return CelestialPosition(
        body: body,
        name: body.name,
        time: now,
        altitude: alt,
        azimuth: 0,
        distance: 0,
        magnitude: mag,
      );
    }

    test('should filter objects below 10 degrees altitude', () {
      final List<CelestialPosition> positions = <CelestialPosition>[
        createPos(CelestialBody.jupiter, 5, -2), // Too low
        createPos(CelestialBody.mars, 15, -1), // Visible
      ];

      final List<HighlightItem> result = HighlightsLogic.selectTop3(positions: positions);

      expect(result.length, 1);
      expect(result.first.body, CelestialBody.mars);
    });

    test('should exclude the Sun', () {
      final List<CelestialPosition> positions = <CelestialPosition>[
        createPos(CelestialBody.sun, -10, -26), // Sun below horizon (nighttime) but should still be excluded
        createPos(CelestialBody.venus, 20, -4),
      ];

      final List<HighlightItem> result = HighlightsLogic.selectTop3(positions: positions);

      expect(result.length, 1);
      expect(result.first.body, CelestialBody.venus);
    });

    test('should sort by magnitude (lower is brighter)', () {
      final List<CelestialPosition> positions = <CelestialPosition>[
        createPos(CelestialBody.mars, 30, 1), // Dimmer
        createPos(CelestialBody.venus, 30, -4), // Brightest
        createPos(CelestialBody.jupiter, 30, -2), // Bright
      ];

      final List<HighlightItem> result = HighlightsLogic.selectTop3(positions: positions);

      expect(result.length, 3);
      expect(result[0].body, CelestialBody.venus);
      expect(result[1].body, CelestialBody.jupiter);
      expect(result[2].body, CelestialBody.mars);
    });

    test('should take only top 3', () {
      final List<CelestialPosition> positions = <CelestialPosition>[
        createPos(CelestialBody.venus, 30, -4),
        createPos(CelestialBody.jupiter, 30, -2),
        createPos(CelestialBody.mars, 30, 0),
        createPos(CelestialBody.saturn, 30, 1), // 4th brightest
      ];

      final List<HighlightItem> result = HighlightsLogic.selectTop3(positions: positions);

      expect(result.length, 3);
      expect(result.map((HighlightItem e) => e.body), containsAll(<dynamic>[
        CelestialBody.venus,
        CelestialBody.jupiter,
        CelestialBody.mars,
      ]));
      expect(result.map((HighlightItem e) => e.body), isNot(contains(CelestialBody.saturn)));
    });
  });
}
