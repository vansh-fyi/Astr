import 'package:flutter_test/flutter_test.dart';
import 'package:astr/features/data_layer/models/zone_data.dart';

void main() {
  group('ZoneData Tests', () {
    test('Initialization and fields', () {
      const zoneData = ZoneData(
        astrZone: 3,
        ratio: 1.0,
        sqm: 20.5,
      );

      expect(zoneData.astrZone, 3);
      expect(zoneData.ratio, 1.0);
      expect(zoneData.sqm, 20.5);
    });

    test('Equality and Hashcode', () {
      const zoneData1 = ZoneData(
        astrZone: 3,
        ratio: 1.0,
        sqm: 20.5,
      );

      const zoneData2 = ZoneData(
        astrZone: 3,
        ratio: 1.0,
        sqm: 20.5,
      );

      const zoneDataDifferent = ZoneData(
        astrZone: 4,
        ratio: 1.5,
        sqm: 19.5,
      );

      expect(zoneData1, equals(zoneData2));
      expect(zoneData1.hashCode, equals(zoneData2.hashCode));

      expect(zoneData1, isNot(equals(zoneDataDifferent)));
      expect(zoneData1.hashCode, isNot(equals(zoneDataDifferent.hashCode)));
    });

    test('copyWith', () {
      const zoneData = ZoneData(
        astrZone: 3,
        ratio: 1.0,
        sqm: 20.5,
      );

      final updated = zoneData.copyWith(astrZone: 5);

      expect(updated.astrZone, 5);
      expect(updated.ratio, 1.0);
      expect(updated.sqm, 20.5);
    });
  });
}
