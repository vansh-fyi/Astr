// Checks AstrZoneScale against test/fixtures/astr_zone_scale.vectors.json, the same
// vectors that scripts/test_astr_zone.py runs against the Python reference.

import 'dart:convert';
import 'dart:io';

import 'package:astr/core/utils/astr_zone_scale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final Map<String, dynamic> vectors = jsonDecode(
    File('test/fixtures/astr_zone_scale.vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  List<Map<String, dynamic>> cases(Object? raw) =>
      (raw! as List<dynamic>).cast<Map<String, dynamic>>();

  double number(Object? v) => (v! as num).toDouble();

  group('AstrZoneScale', () {
    test('constants match the vectors', () {
      final Map<String, dynamic> c = vectors['constants'] as Map<String, dynamic>;
      expect(AstrZoneScale.naturalMicroCdPerM2, number(c['natural_ucd_per_m2']));
      expect(AstrZoneScale.referenceSqm, number(c['reference_sqm']));
      expect(AstrZoneScale.firstEdge, number(c['first_edge']));
      expect(AstrZoneScale.step, number(c['step']));
      expect(AstrZoneScale.zoneCount, c['zone_count']);
      expect(
        AstrZoneScale.edges,
        (vectors['edges']! as List<dynamic>).map(number).toList(),
      );
    });

    test('edges double', () {
      for (int i = 1; i < AstrZoneScale.edges.length; i++) {
        expect(AstrZoneScale.edges[i] / AstrZoneScale.edges[i - 1], 2);
      }
    });

    test('ratio to zone', () {
      for (final Map<String, dynamic> c in cases(vectors['ratio_to_zone'])) {
        expect(AstrZoneScale.zoneFromRatio(number(c['r'])), c['zone'], reason: '$c');
      }
    });

    test('infinity is the top zone and NaN is rejected', () {
      expect(AstrZoneScale.zoneFromRatio(double.infinity), 9);
      expect(() => AstrZoneScale.zoneFromRatio(double.nan), throwsArgumentError);
      expect(() => AstrZoneScale.sqmFromRatio(double.nan), throwsArgumentError);
    });

    test('ratio to sqm and back', () {
      final Map<String, dynamic> a = vectors['ratio_to_sqm'] as Map<String, dynamic>;
      for (final Map<String, dynamic> c in cases(a['cases'])) {
        expect(AstrZoneScale.sqmFromRatio(number(c['r'])), closeTo(number(c['sqm']), number(a['tolerance'])));
      }
      final Map<String, dynamic> b = vectors['sqm_to_ratio'] as Map<String, dynamic>;
      for (final Map<String, dynamic> c in cases(b['cases'])) {
        expect(AstrZoneScale.ratioFromSqm(number(c['sqm'])), closeTo(number(c['r']), number(b['tolerance'])));
      }
    });

    test('naked-eye limiting magnitude', () {
      final Map<String, dynamic> n = vectors['sqm_to_nelm'] as Map<String, dynamic>;
      for (final Map<String, dynamic> c in cases(n['cases'])) {
        expect(AstrZoneScale.nelmFromSqm(number(c['sqm'])), closeTo(number(c['nelm']), number(n['tolerance'])));
      }
    });

    test('artificial luminance', () {
      final Map<String, dynamic> u = vectors['artificial_ucd'] as Map<String, dynamic>;
      for (final Map<String, dynamic> c in cases(u['cases'])) {
        expect(
          AstrZoneScale.artificialMicroCdFromRatio(number(c['r'])),
          closeTo(number(c['ucd']), number(u['tolerance'])),
        );
      }
    });

    test('legacy chain', () {
      final Map<String, dynamic> l = vectors['legacy'] as Map<String, dynamic>;
      for (final Map<String, dynamic> c in cases(l['cases'])) {
        final double radiance = number(c['radiance']);
        expect(AstrZoneScale.legacyZoneFromRadiance(radiance), c['legacy_zone'], reason: '$c');
        final double r = AstrZoneScale.legacyRatioFromRadiance(radiance);
        expect(r, closeTo(number(c['ratio']), number(l['tolerance'])));
        expect(AstrZoneScale.zoneFromRatio(r), c['ladder_zone'], reason: '$c');
      }
    });

    test('legacy and ladder zones differ by at most one', () {
      for (double radiance = 0.2; radiance < 400; radiance *= 1.001) {
        final int legacy = AstrZoneScale.legacyZoneFromRadiance(radiance);
        final int ladder = AstrZoneScale.zoneFromRatio(AstrZoneScale.legacyRatioFromRadiance(radiance));
        expect((legacy - ladder).abs(), lessThanOrEqualTo(1), reason: '$radiance');
      }
    });
  });
}
